import os
import time
import httpx
from typing import List, Dict
from datetime import datetime, timedelta, timezone
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from sqlalchemy import func
from google import genai
from app.db.session import SessionLocal
from app.models.intel import IntelArticle
from app.core.config import settings

# Fixed UTC hour the daily refresh runs at. Using a cron trigger (instead of
# an interval trigger) anchors the job to a real wall-clock time each day,
# so "daily" actually means once per calendar day rather than "N hours after
# whenever the process happened to start".
DAILY_REFRESH_HOUR_UTC = 6

client = genai.Client(api_key=settings.GEMINI_API_KEY, http_options={'timeout': 10000})

def classify_severity(title: str, summary: str) -> str:
    """Use Gemini to assign CRITICAL, HIGH, MEDIUM, or LOW severity based on the article."""
    try:
        prompt = f"""
        Analyze this cybersecurity news article:
        Title: {title}
        Summary: {summary}
        
        Assign a severity level: CRITICAL, HIGH, MEDIUM, or LOW.
        - CRITICAL: Active massive breach, zero-day exploited in wild, widespread M-Pesa fraud.
        - HIGH: New phishing campaign, ransomware attack, major vulnerability discovered.
        - MEDIUM: Data leak warning, malware discovery, general cyber crime arrest.
        - LOW: General cybersecurity tip, policy change, industry news.
        
        Return exactly ONE word (CRITICAL, HIGH, MEDIUM, or LOW).
        """
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=prompt
        )
        level = response.text.strip().upper()
        if level in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
            return level
        return "MEDIUM"
    except Exception as e:
        print(f"Gemini classification failed: {e}")
        return "MEDIUM"

def fetch_and_cache_intel():
    print("[Intel] Starting background job to fetch cybersecurity news...")
    
    # Touch the lock file to prevent rapid restarts from re-triggering the fetch
    try:
        open(".last_intel_fetch", "w").close()
    except Exception:
        pass
    
    gnews_api_key = settings.GNEWS_API_KEY
    if not gnews_api_key:
        print("[Intel] GNEWS_API_KEY not set. Skipping fetch.")
        return

    TARGET_COUNT = 20
    # How far back an article is allowed to be and still count as "today's
    # news". GNews' sortby=publishedAt only orders results by date, it does
    # NOT restrict the search window — so a low-coverage keyword can still
    # return week-old articles as its "most recent" match. We constrain the
    # query itself with `from`, and filter again after fetching as a
    # safety net (e.g. malformed dates, API not honoring `from`).
    MAX_ARTICLE_AGE_DAYS = 1
    cutoff = datetime.now(timezone.utc) - timedelta(days=MAX_ARTICLE_AGE_DAYS)
    from_param = cutoff.strftime("%Y-%m-%dT%H:%M:%SZ")

    # Primary keywords: cybersecurity + IT security
    cyber_keywords = [
        'cybersecurity',
        'data breach',
        'ransomware',
        'hacking',
        'phishing',
        'malware',
    ]
    # Fallback: broader IT and technology news
    tech_keywords = [
        'artificial intelligence',
        'cloud computing',
        'software vulnerability',
        'tech industry',
        'cryptocurrency',
        'privacy data',
        'IT security',
        'technology news',
    ]

    articles_data = []
    seen_urls = set()

    def fetch_keyword(kw, use_country=False):
        """Fetch articles for a single keyword and return deduplicated results."""
        try:
            print(f"[Intel] Fetching articles for: {kw}")
            params = {
                "q": kw,
                "lang": "en",
                "max": 10,
                "apikey": gnews_api_key,
                "sortby": "publishedAt",
                "from": from_param,
            }
            # Only add country filter when explicitly requested
            if use_country:
                params["country"] = "ke"

            resp = httpx.get("https://gnews.io/api/v4/search", params=params, timeout=15.0)
            
            if resp.status_code == 200:
                data = resp.json()
                fetched = data.get("articles", [])
                print(f"[Intel] Got {len(fetched)} articles for '{kw}'")
                new_articles = []
                for a in fetched:
                    if a["url"] in seen_urls:
                        continue
                    # Safety net: drop anything older than the cutoff even
                    # if GNews returned it despite the `from` filter.
                    try:
                        pub = datetime.strptime(a.get("publishedAt", ""), "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
                        if pub < cutoff:
                            continue
                    except ValueError:
                        # No parseable date — skip rather than risk showing stale news
                        continue
                    seen_urls.add(a["url"])
                    new_articles.append(a)
                return new_articles
            else:
                print(f"[Intel] GNews API error {resp.status_code} for '{kw}': {resp.text}")
        except Exception as e:
            print(f"[Intel] Failed to fetch '{kw}': {e}")

        return []
    
    # Fetch cybersecurity articles first (priority) - no country filter, keywords provide geo relevance
    for kw in cyber_keywords:
        articles_data.extend(fetch_keyword(kw))
        if len(articles_data) >= TARGET_COUNT:
            break

    # If we still don't have enough, fill with general tech/cyber news
    if len(articles_data) < TARGET_COUNT:
        print(f"[Intel] Only {len(articles_data)} cyber articles found, fetching broader news as fallback...")
        for kw in tech_keywords:
            articles_data.extend(fetch_keyword(kw))
            if len(articles_data) >= TARGET_COUNT:
                break

    # Cap at TARGET_COUNT
    articles_data = articles_data[:TARGET_COUNT]

    if not articles_data:
        print("[Intel] No articles found at all.")
        return

    print(f"[Intel] Total unique articles to process: {len(articles_data)}")

    db: Session = SessionLocal()
    try:
        # Fetch existing articles before deleting
        old_articles = db.query(IntelArticle).order_by(IntelArticle.published_at.desc()).all()
        
        # Calculate how many we need
        needed = TARGET_COUNT - len(articles_data)
        
        if needed > 0 and old_articles:
            print(f"[Intel] Short by {needed} articles. Retaining some from previous fetch.")
            new_urls = {a.get("url") for a in articles_data}
            retained = 0
            for old_a in old_articles:
                if old_a.source_url not in new_urls:
                    # Construct dictionary resembling fetched API data
                    articles_data.append({
                        "title": old_a.title,
                        "description": old_a.summary,
                        "image": old_a.image_url,
                        "url": old_a.source_url,
                        "source": {"name": old_a.source_name},
                        "publishedAt": old_a.published_at.strftime("%Y-%m-%dT%H:%M:%SZ") if old_a.published_at else "",
                        # We will re-classify or just skip classification, but let's re-use the item processing below.
                        "_retained_severity": old_a.severity # We can inject this flag to avoid re-classifying
                    })
                    retained += 1
                    if retained >= needed:
                        break

        # Clear old articles to keep feed fresh every cycle
        old_count = len(old_articles)
        if old_count > 0:
            db.query(IntelArticle).delete()
            db.commit()
            print(f"[Intel] Cleared {old_count} old articles from DB.")

        added_count = 0
        for item in articles_data:
            if "_retained_severity" in item:
                severity = item["_retained_severity"]
            else:
                severity = classify_severity(item["title"], item.get("description", ""))
            
            # Parse datetime
            pub_date = item.get("publishedAt", "")
            try:
                published_at = datetime.strptime(pub_date, "%Y-%m-%dT%H:%M:%SZ")
            except:
                published_at = datetime.now(timezone.utc)
                
            new_article = IntelArticle(
                title=item.get("title", ""),
                summary=item.get("description", ""),
                image_url=item.get("image", ""),
                source_url=item.get("url", ""),
                source_name=item.get("source", {}).get("name", "Unknown Source"),
                severity=severity,
                published_at=published_at
            )
            db.add(new_article)
            added_count += 1
                
        db.commit()
        print(f"[Intel] Saved {added_count} fresh articles to database.")
    except Exception as e:
        db.rollback()
        print(f"[Intel] Database error: {e}")
    finally:
        db.close()

# Scheduler singleton
scheduler = BackgroundScheduler()

def _already_fetched_today() -> bool:
    """Check whether we've already cached a fetch for today (UTC) or recently attempted."""
    import os
    lock_file = ".last_intel_fetch"
    try:
        # Prevent uvicorn reload death-spiral by checking if we attempted a fetch in the last 6 hours
        if os.path.exists(lock_file):
            mtime = os.path.getmtime(lock_file)
            if time.time() - mtime < 6 * 3600:
                return True
    except Exception:
        pass

    db: Session = SessionLocal()
    try:
        latest = db.query(func.max(IntelArticle.fetched_at)).scalar()
        if latest is None:
            return False
        if latest.tzinfo is None:
            latest = latest.replace(tzinfo=timezone.utc)
        return latest.astimezone(timezone.utc).date() == datetime.now(timezone.utc).date()
    except Exception as e:
        print(f"[Intel] Failed to check last fetch date: {e}")
        return False
    finally:
        db.close()

def start_scheduler():
    if not scheduler.running:
        # Cron trigger fires at a fixed UTC time every calendar day, so the
        # "trending" feed reliably rolls over once per day instead of
        # drifting or silently going stale across restarts/deploys.
        scheduler.add_job(
            fetch_and_cache_intel,
            CronTrigger(hour=DAILY_REFRESH_HOUR_UTC, minute=0),
            id='intel_fetch_job',
            replace_existing=True,
            misfire_grace_time=3600,
        )
        scheduler.start()
        print(f"[Intel] APScheduler started (runs daily at {DAILY_REFRESH_HOUR_UTC:02d}:00 UTC).")

        # An interval/cron trigger alone won't run at process startup, so a
        # fresh deploy (or a restart that missed the scheduled hour) can sit
        # on stale/empty data for up to 24h. Do an immediate catch-up fetch
        # if today's data isn't cached yet.
        if not _already_fetched_today():
            print("[Intel] No data cached for today yet — running catch-up fetch now.")
            fetch_and_cache_intel()