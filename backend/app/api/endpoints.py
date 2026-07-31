from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import List
import json
import httpx
from app.core.config import settings

from app.services.game_service import generate_daily_quiz
from app.services.mulika_service import analyze_message_content
from app.services.agent_service import generate_agent_response

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.history import ScamAnalysis, ChatMessage

router = APIRouter()

# How many prior messages (user + agent combined) to feed back to the model as context.
AGENT_HISTORY_LIMIT = 12

class MessageAnalyze(BaseModel):
    message: str
    type: str = "text"
    image_base64: str | None = None

class ChatInput(BaseModel):
    message: str = Field(..., min_length=1)

@router.get("/chonjo/daily-quiz")
async def get_daily_quiz(level: int = 1):
    """
    Returns 20 randomized questions for the daily Chonjo game.
    """
    questions = await generate_daily_quiz(level)
    return {"status": "success", "data": questions}

@router.post("/chonjo/submit-score")
async def submit_score(score: int, level: int = 1, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Submit the score for a specific level.
    Only the ADDITIONAL XP (score minus previous best for that level)
    is added to the user's cumulative total_score.
    """
    from app.models.chonjo_score import ChonjoLevelScore
    from datetime import datetime, timezone

    # Find existing best score for this user+level
    entry = db.query(ChonjoLevelScore).filter(
        ChonjoLevelScore.user_id == current_user.id,
        ChonjoLevelScore.level == level,
    ).first()

    if entry:
        old_max = entry.max_score
        if score > old_max:
            delta = score - old_max
            entry.max_score = score
            current_user.total_score += delta
        # else: no new XP, they didn't beat their old score
    else:
        entry = ChonjoLevelScore(
            user_id=current_user.id,
            level=level,
            max_score=score,
        )
        db.add(entry)
        current_user.total_score += score

    # If this is level 10 and no cert yet, mark certificate earned
    if level == 10 and entry.cert_earned_at is None:
        entry.cert_earned_at = datetime.now(timezone.utc)

    if score > 0:
        current_user.streak += 1
    else:
        current_user.streak = 0

    db.commit()
    db.refresh(current_user)

    return {"status": "success", "message": "Score updated successfully", "score": current_user.total_score, "streak": current_user.streak}


@router.get("/chonjo/progress")
async def get_chonjo_progress(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Returns the user's total XP, per-level best scores, and certificate status.
    """
    from app.models.chonjo_score import ChonjoLevelScore

    level_entries = db.query(ChonjoLevelScore).filter(
        ChonjoLevelScore.user_id == current_user.id,
    ).all()

    level_scores = {}
    cert_earned_at = None
    for e in level_entries:
        level_scores[str(e.level)] = e.max_score
        if e.level == 10 and e.cert_earned_at is not None:
            cert_earned_at = e.cert_earned_at.strftime("%B %d, %Y")

    return {
        "status": "success",
        "data": {
            "total_xp": current_user.total_score,
            "username": current_user.username,
            "email": current_user.email,
            "level_scores": level_scores,
            "cert_earned_at": cert_earned_at,
        },
    }

@router.get("/intel/feed")
async def get_intel(category: str = "All", db: Session = Depends(get_db)):
    """
    Retrieve real-time filtered tech/cybersecurity alert news from cached DB.
    """
    from app.models.intel import IntelArticle
    articles_query = db.query(IntelArticle).order_by(IntelArticle.published_at.desc()).limit(30)
    
    articles = articles_query.all()
    
    formatted_articles = []
    for a in articles:
        formatted_articles.append({
            "id": a.id,
            "title": a.title,
            "source": a.source_name,
            "category": "News",
            "threat_level": a.severity,
            "summary": a.summary,
            "time_ago": a.published_at.strftime("%Y-%m-%d") if a.published_at else "Recent",
            "url": a.source_url,
            "image_url": a.image_url or ""
        })
        
    return {"status": "success", "data": formatted_articles}

@router.post("/mulika/analyze")
async def analyze_message(payload: MessageAnalyze, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Analyze suspicious text/link and persist report to database history.
    """
    result = await analyze_message_content(payload.message, payload.type, payload.image_base64)
    
    # Save to DB
    db_analysis = ScamAnalysis(
        user_id=current_user.id,
        message_content=payload.message,
        scam_probability=result.get("scam_probability", 0),
        risk_rating=result.get("risk_rating", "Suspicious"),
        red_flags=json.dumps(result.get("red_flags", [])),
        explanation=result.get("explanation", "")
    )
    db.add(db_analysis)
    db.commit()
    db.refresh(db_analysis)
    
    return {"status": "success", "data": result}

@router.post("/agent/chat")
async def chat_with_agent(payload: ChatInput, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Get interactive AI cybersecurity guidance from the agent, using the user's recent
    chat history for conversational context, and persist the new exchange.
    """
    # Pull the most recent turns (oldest first) so the agent has memory of the conversation
    recent_messages = (
        db.query(ChatMessage)
        .filter(ChatMessage.user_id == current_user.id)
        .order_by(ChatMessage.id.desc())
        .limit(AGENT_HISTORY_LIMIT)
        .all()
    )
    history = [{"role": m.role, "content": m.content} for m in reversed(recent_messages)]

    response_text = await generate_agent_response(payload.message, history)
    
    # Save user message
    user_msg = ChatMessage(
        user_id=current_user.id,
        role="user",
        content=payload.message
    )
    db.add(user_msg)
    
    # Save agent message
    agent_msg = ChatMessage(
        user_id=current_user.id,
        role="agent",
        content=response_text
    )
    db.add(agent_msg)
    
    db.commit()
    
    return {"status": "success", "data": {"response": response_text}}

class ReportNumberInput(BaseModel):
    phone_number: str
    scam_category: str
    details: str | None = None

@router.post("/active-defense/report")
async def report_number(payload: ReportNumberInput, db: Session = Depends(get_db)):
    """
    Report a fraudulent number to the global database.
    """
    from app.models.active_defense import ReportedNumber
    
    # Check if number already exists
    existing = db.query(ReportedNumber).filter(ReportedNumber.phone_number == payload.phone_number).first()
    
    if existing:
        existing.report_count += 1
        # optionally update category if it's the same or keep track, but for now just increment
        db.commit()
        return {"status": "success", "message": "Number report count incremented"}
    else:
        new_report = ReportedNumber(
            phone_number=payload.phone_number,
            scam_category=payload.scam_category,
            details=payload.details
        )
        db.add(new_report)
        db.commit()
        return {"status": "success", "message": "Number reported successfully"}

@router.get("/active-defense/check/{phone_number}")
async def check_number(phone_number: str, db: Session = Depends(get_db)):
    """
    Check if a number has been reported.
    """
    from app.models.active_defense import ReportedNumber
    
    reported = db.query(ReportedNumber).filter(ReportedNumber.phone_number == phone_number).first()
    
    if reported:
        return {
            "status": "success",
            "data": {
                "is_safe": False,
                "scam_category": reported.scam_category,
                "report_count": reported.report_count,
                "last_reported": reported.last_reported_at.strftime("%Y-%m-%d %H:%M:%S") if reported.last_reported_at else None
            }
        }
    else:
        return {
            "status": "success",
            "data": {
                "is_safe": True
            }
        }

# ─── VirusTotal Device Scan ──────────────────────────────────────────────────

class ScanAppsInput(BaseModel):
    package_names: List[str] = Field(..., min_length=1)

class ScanFilesInput(BaseModel):
    file_hashes: List[dict] = Field(..., min_length=1)

class ScanDomainInput(BaseModel):
    domain: str

@router.post("/mulika/scan-apps")
async def scan_apps(payload: ScanAppsInput):
    """
    Scan a list of Android app package names against VirusTotal.
    """
    from app.services.virustotal_service import scan_package_names
    from app.core.config import settings
    
    if not settings.VIRUSTOTAL_API_KEY or settings.VIRUSTOTAL_API_KEY == "YOUR_VIRUSTOTAL_API_KEY_HERE":
        raise HTTPException(
            status_code=503,
            detail="VirusTotal API key not configured. Please set VIRUSTOTAL_API_KEY in .env"
        )
    
    result = await scan_package_names(payload.package_names)
    return {"status": "success", "data": result}


@router.post("/mulika/scan-files")
async def scan_files(payload: ScanFilesInput):
    """
    Scan a list of file hashes (SHA-256) against VirusTotal.
    """
    from app.services.virustotal_service import scan_file_hashes
    from app.core.config import settings
    
    if not settings.VIRUSTOTAL_API_KEY or settings.VIRUSTOTAL_API_KEY == "YOUR_VIRUSTOTAL_API_KEY_HERE":
        raise HTTPException(
            status_code=503,
            detail="VirusTotal API key not configured. Please set VIRUSTOTAL_API_KEY in .env"
        )
    
    result = await scan_file_hashes(payload.file_hashes)
    return {"status": "success", "data": result}


@router.post("/mulika/scan-domain")
async def scan_domain(payload: ScanDomainInput):
    """
    Check a domain against VirusTotal.
    """
    from app.services.virustotal_service import check_domain
    from app.core.config import settings
    
    if not settings.VIRUSTOTAL_API_KEY or settings.VIRUSTOTAL_API_KEY == "YOUR_VIRUSTOTAL_API_KEY_HERE":
        raise HTTPException(
            status_code=503,
            detail="VirusTotal API key not configured. Please set VIRUSTOTAL_API_KEY in .env"
        )
    
    result = await check_domain(payload.domain)
    return {"status": "success", "data": result}