import random
import json
from google import genai
from pydantic import BaseModel
from typing import List
from duckduckgo_search import DDGS
from app.core.config import settings
client = genai.Client(api_key=settings.GEMINI_API_KEY, http_options={'timeout': 20000})
class QuizItem(BaseModel):
    id: int
    sender: str
    message: str
    is_scam: bool
    explanation: str
    type: str # "SMS" or "EMAIL"

def fetch_trending_scams() -> str:
    """Fetches real-time internet context about current scams."""
    # Deprecated: Static fallback is used to ensure stability
    return "No real-time internet context available."

async def generate_daily_quiz(level: int = 1) -> List[dict]:
    """
    Loads 10 static scam scenarios for the specified level from chonjo_questions_bank.json.
    """
    import os
    from pathlib import Path
    try:
        base_dir = Path(__file__).parent.parent.parent
        file_path = base_dir / 'chonjo_questions_bank.json'
        
        with open(file_path, 'r', encoding='utf-8') as f:
            all_questions = json.load(f)
            
        # Filter by level
        level_questions = [q for q in all_questions if q.get('level') == level]
        
        # If no questions found for this level, just return a default fallback
        if not level_questions:
             return [
                 {"id": 100, "type": "SMS", "sender": "MPESA", "message": "Dear customer, your account will be suspended. Click here to verify: http://mpesa-verify.com", "is_scam": True, "explanation": "Safaricom never sends links via SMS to verify accounts."}
             ]
             
        random.shuffle(level_questions)
        return level_questions
    except Exception as e:
        print(f"Failed to load static quiz content: {e}")
        raise ValueError("Failed to load quiz content.")
