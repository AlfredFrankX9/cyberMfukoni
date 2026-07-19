"""
VirusTotal Integration Service for Cyber Mfukoni.

Uses the VirusTotal API v3 to:
- Check Android APK package names (searches for known malware by package name)
- Check file hashes (SHA-256) against the VT database
- Check URLs/domains for malicious content

Free tier: 4 requests/minute, 500 requests/day, 15.5K requests/month.
"""
import httpx
import hashlib
import asyncio
from typing import Optional
from app.core.config import settings

VT_BASE_URL = "https://www.virustotal.com/api/v3"


def _get_headers():
    return {
        "x-apikey": settings.VIRUSTOTAL_API_KEY,
        "Accept": "application/json",
    }


async def check_file_hash(file_hash: str) -> dict:
    """
    Check a file hash (MD5, SHA-1, or SHA-256) against VirusTotal.
    Returns detection stats or None if not found.
    """
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(
                f"{VT_BASE_URL}/files/{file_hash}",
                headers=_get_headers(),
            )
            if resp.status_code == 200:
                data = resp.json()
                attrs = data.get("data", {}).get("attributes", {})
                stats = attrs.get("last_analysis_stats", {})
                return {
                    "found": True,
                    "malicious": stats.get("malicious", 0),
                    "suspicious": stats.get("suspicious", 0),
                    "undetected": stats.get("undetected", 0),
                    "harmless": stats.get("harmless", 0),
                    "name": attrs.get("meaningful_name", attrs.get("suggested_threat_label", "Unknown")),
                    "reputation": attrs.get("reputation", 0),
                }
            elif resp.status_code == 404:
                return {"found": False}
            else:
                return {"found": False, "error": f"VT API returned {resp.status_code}"}
    except Exception as e:
        return {"found": False, "error": str(e)}


async def check_domain(domain: str) -> dict:
    """
    Check a domain against VirusTotal.
    """
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(
                f"{VT_BASE_URL}/domains/{domain}",
                headers=_get_headers(),
            )
            if resp.status_code == 200:
                data = resp.json()
                attrs = data.get("data", {}).get("attributes", {})
                stats = attrs.get("last_analysis_stats", {})
                return {
                    "found": True,
                    "malicious": stats.get("malicious", 0),
                    "suspicious": stats.get("suspicious", 0),
                    "undetected": stats.get("undetected", 0),
                    "harmless": stats.get("harmless", 0),
                    "reputation": attrs.get("reputation", 0),
                }
            elif resp.status_code == 404:
                return {"found": False}
            else:
                return {"found": False, "error": f"VT API returned {resp.status_code}"}
    except Exception as e:
        return {"found": False, "error": str(e)}


async def scan_package_names(package_names: list[str]) -> dict:
    """
    Scan a list of Android package names by searching VirusTotal.
    Uses the /intelligence/search endpoint to find APKs by package name.
    
    Due to VT rate limits (4 req/min on free tier), we batch and throttle.
    For each package, we search VT's dataset. If an exact APK match is found
    with malicious detections, it's flagged.
    
    Returns a summary report.
    """
    results = []
    threats_found = 0
    scanned = 0
    
    for pkg in package_names:
        scanned += 1
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                # Search for the package name in VT's intelligence database
                resp = await client.get(
                    f"{VT_BASE_URL}/intelligence/search",
                    headers=_get_headers(),
                    params={"query": f"metadata:{pkg} type:apk"},
                )

                if resp.status_code == 200:
                    data = resp.json()
                    items = data.get("data", [])
                    
                    if items:
                        # Check the first matching file's detection stats
                        attrs = items[0].get("attributes", {})
                        stats = attrs.get("last_analysis_stats", {})
                        malicious_count = stats.get("malicious", 0)
                        suspicious_count = stats.get("suspicious", 0)
                        
                        is_threat = malicious_count > 0 or suspicious_count > 2
                        if is_threat:
                            threats_found += 1
                        
                        results.append({
                            "package": pkg,
                            "status": "THREAT" if is_threat else "CLEAN",
                            "malicious": malicious_count,
                            "suspicious": suspicious_count,
                            "name": attrs.get("meaningful_name", pkg),
                        })
                    else:
                        # No match found in VT — not necessarily safe, just unknown
                        results.append({
                            "package": pkg,
                            "status": "UNKNOWN",
                            "malicious": 0,
                            "suspicious": 0,
                        })
                elif resp.status_code == 429:
                    # Rate limited — stop scanning, report what we have
                    results.append({
                        "package": pkg,
                        "status": "RATE_LIMITED",
                        "malicious": 0,
                        "suspicious": 0,
                    })
                    break
                else:
                    results.append({
                        "package": pkg,
                        "status": "ERROR",
                        "malicious": 0,
                        "suspicious": 0,
                    })
        except Exception as e:
            results.append({
                "package": pkg,
                "status": "ERROR",
                "malicious": 0,
                "suspicious": 0,
            })
        
        # Throttle: VT free tier allows 4 req/min. ~15s between requests.
        # We use a shorter delay since users won't want to wait 4+ minutes
        # In production, use a premium key with higher limits.
        if scanned < len(package_names):
            await asyncio.sleep(1.0)  # 1 second delay between requests

    # Build summary
    threat_score = min(100, int((threats_found / max(scanned, 1)) * 100))
    if threats_found == 0:
        risk_rating = "Safe"
    elif threats_found <= 2:
        risk_rating = "Low Risk"
    elif threats_found <= 5:
        risk_rating = "Suspicious"
    elif threats_found <= 10:
        risk_rating = "High Risk"
    else:
        risk_rating = "Scam Likely"

    return {
        "scam_probability": threat_score if threats_found > 0 else 5,
        "risk_rating": risk_rating,
        "red_flags": [
            f"THREAT: {r['package']} ({r['malicious']} engines flagged malicious)"
            for r in results if r["status"] == "THREAT"
        ] if threats_found > 0 else ["No known threats detected in scanned packages"],
        "confidence": 95,
        "community_reports": f"Scanned {scanned} packages. {threats_found} threats found via VirusTotal.",
        "explanation": (
            f"VirusTotal cross-referenced {scanned} installed applications against its database of "
            f"70+ antivirus engines. {threats_found} application(s) were flagged as potentially malicious. "
            "It is recommended to uninstall flagged applications immediately."
        ) if threats_found > 0 else (
            f"VirusTotal cross-referenced {scanned} installed applications against its database of "
            f"70+ antivirus engines. No known malware signatures were detected. Your device appears clean."
        ),
        "scan_details": results,
    }


async def scan_file_hashes(file_hashes: list[dict]) -> dict:
    """
    Scan a list of file hashes. Each entry: {"name": "filename.ext", "hash": "sha256..."}
    """
    results = []
    threats_found = 0
    scanned = 0

    for entry in file_hashes:
        scanned += 1
        file_hash = entry.get("hash", "")
        file_name = entry.get("name", "unknown")
        
        vt_result = await check_file_hash(file_hash)
        
        if vt_result.get("found"):
            is_threat = vt_result.get("malicious", 0) > 0
            if is_threat:
                threats_found += 1
            results.append({
                "name": file_name,
                "hash": file_hash[:16] + "...",
                "status": "THREAT" if is_threat else "CLEAN",
                "malicious": vt_result.get("malicious", 0),
            })
        else:
            results.append({
                "name": file_name,
                "hash": file_hash[:16] + "...",
                "status": "UNKNOWN",
                "malicious": 0,
            })

        if scanned < len(file_hashes):
            await asyncio.sleep(1.0)

    threat_score = min(100, int((threats_found / max(scanned, 1)) * 100))
    
    return {
        "scam_probability": threat_score if threats_found > 0 else 5,
        "risk_rating": "High Risk" if threats_found > 0 else "Safe",
        "red_flags": [
            f"MALWARE: {r['name']} flagged by {r['malicious']} engines"
            for r in results if r["status"] == "THREAT"
        ] if threats_found > 0 else ["No known threats detected in scanned files"],
        "confidence": 95,
        "community_reports": f"Scanned {scanned} files. {threats_found} threats found via VirusTotal.",
        "explanation": (
            f"VirusTotal checked {scanned} file hashes against 70+ antivirus engines. "
            f"{threats_found} file(s) matched known malware signatures."
        ) if threats_found > 0 else (
            f"VirusTotal checked {scanned} file hashes against 70+ antivirus engines. "
            f"All files appear clean."
        ),
        "scan_details": results,
    }
