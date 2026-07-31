import json
import httpx
from google import genai
from app.core.config import settings
from fastapi import HTTPException
import base64
from google.genai import types
client = genai.Client(api_key=settings.GEMINI_API_KEY, http_options={'timeout': 20000})

async def fetch_url_content(url: str) -> str:
    try:
        async with httpx.AsyncClient(timeout=10.0) as httpx_client:
            resp = await httpx_client.get(url)
            return resp.text[:5000] # Truncate to avoid massive prompts
    except Exception as e:
        return f"[Failed to fetch URL content: {e}]"

async def analyze_message_content(message: str, input_type: str = "text", image_base64: str | None = None) -> dict:
    try:
        context_addition = ""
        if input_type.lower() == "url" and message.startswith("http"):
            content = await fetch_url_content(message)
            context_addition = f"\n\nHere is a snippet of the website content fetched from the URL:\n{content}\n"

        type_desc = {
            "sms": "an SMS message",
            "email": "an Email",
            "url": "a Website URL",
            "qr code": "content decoded from a QR Code",
            "image": "text extracted from an Image",
            "document": "text extracted from a Document"
        }.get(input_type.lower(), "a message")

        prompt = f"""
        You are an expert mobile security and anti-phishing AI engine named 'Mulika' operating in Kenya.
        Analyze the following {type_desc} for indicators of scams, fraud, phishing, or social engineering:
        
        "{message}"
        {context_addition}
        Evaluate it carefully and return a JSON object containing:
        1. "scam_probability": an integer between 0 and 100 representing the likelihood that this is a scam.
        2. "risk_rating": one of: "Safe", "Low Risk", "Suspicious", "High Risk", "Scam Likely".
        3. "red_flags": a list of strings describing specific indicators of fraud (e.g. "Urgent call to action", "Suspicious URL", "Impersonation of M-Pesa", etc.). If none, return an empty list.
        4. "confidence": an integer between 0 and 100 indicating your confidence in this assessment.
        5. "community_reports": a string indicating whether similar scams are trending or reported (e.g., "Reported 15 times this week" or "No similar reports found").
        6. "explanation": a detailed explanation (3-4 sentences) analyzing why the message is safe or a scam, citing the flags and advising on safe behavior.
        
        Return ONLY a raw JSON object. Do not wrap in markdown code blocks like ```json.
        """
        contents = [prompt]
        if image_base64:
            # We assume a jpeg for simplicity, though Gemini handles various formats via the mime_type.
            image_bytes = base64.b64decode(image_base64)
            contents.append(
                types.Part.from_bytes(
                    data=image_bytes,
                    mime_type="image/jpeg"
                )
            )

        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=contents
        )
        raw_text = response.text.strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:]
        if raw_text.endswith("```"):
            raw_text = raw_text[:-3]
        return json.loads(raw_text.strip())
    except Exception as e:
        print(f"Gemini analysis in Mulika failed: {e}")
        # Parse the error string if possible to give a cleaner message
        error_msg = str(e)
        if "503" in error_msg:
            detail = "The AI service is currently experiencing high demand. Please try again in a few moments."
        elif "quota" in error_msg.lower():
            detail = "The AI service quota has been exceeded. Please try again later."
        else:
            detail = "Analysis failed due to technical difficulties with the AI service."
            
        raise HTTPException(status_code=503, detail=detail)
