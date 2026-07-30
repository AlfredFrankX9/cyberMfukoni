import json
import logging
import random
from pathlib import Path
from google import genai
from google.genai import types
from app.core.config import settings

logger = logging.getLogger(__name__)

client = genai.Client(api_key=settings.GEMINI_API_KEY)

# Load fallback responses JSON (optional)
FALLBACKS: dict = {}
try:
    _fallback_path = Path(__file__).resolve().parents[2] / 'agent_fallbacks.json'
    if _fallback_path.exists():
        with _fallback_path.open('r', encoding='utf-8') as f:
            FALLBACKS = json.load(f)
            logger.info('Loaded agent fallbacks from %s', _fallback_path)
    else:
        logger.info('No agent_fallbacks.json found at %s', _fallback_path)
except Exception:
    logger.exception('Failed to load agent_fallbacks.json')

SYSTEM_PROMPT = """
You are an expert AI Cybersecurity Assistant called 'The Guardian' for the 'Cyber Mfukoni' platform.

Answer EVERY user message as helpfully and completely as you can, the way a top-tier assistant would.
You are not limited to cybersecurity topics — if a user asks something unrelated, still answer it well.
But cybersecurity is your specialty: whenever a question touches on it (directly or indirectly), go deeper —
educate, explain how the scam/threat works, point out concrete red flags, and recommend specific safe actions.

You have particular expertise in threats relevant to Kenya, e.g.:
- M-Pesa and mobile money scams (fake reversals, agent impersonation, SIM swaps)
- "Hi Mum" / family-impersonation social engineering
- Safaricom SIM-swap fraud
- KRA tax refund phishing
- Fake bank verification calls/SMS

Formatting guidelines:
- Keep answers structured and easy to scan: short paragraphs, bullet points, bold for key terms.
- Use emojis sparingly to flag warnings or key points (e.g. ⚠️, 🔒) — don't overdo it.
- If a user describes a suspicious message/call, walk through the specific red flags and what to do next
  (e.g. don't click, verify via the official app/number, report to Safaricom/KRA/your bank).
- If you genuinely don't have enough information to assess a situation, ask a clarifying question instead
  of guessing.
"""


def _build_contents(message: str, history: list[dict] | None = None) -> list[types.Content]:
    """
    Builds the multi-turn contents list for the Gemini call.

    `history` is a list of {"role": "user"|"agent", "content": str} pulled from the
    ChatMessage table, oldest first. Gemini expects roles "user" and "model", so
    "agent" is mapped to "model" here.
    """
    contents: list[types.Content] = []
    if history:
        for turn in history:
            role = "model" if turn.get("role") == "agent" else "user"
            text = (turn.get("content") or "").strip()
            if text:
                contents.append(types.Content(role=role, parts=[types.Part(text=text)]))
    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))
    return contents


def get_fallback_response(message: str) -> str:
    """Return a fallback response chosen from the loaded JSON, based on simple keyword matching."""
    if not FALLBACKS:
        return "I'm sorry — I can't reach my knowledge base right now. Please try again later."

    text = (message or "").lower().strip()
    # greetings
    if any(g in text for g in ['hi', 'hello', 'hey', 'welcome']):
        return random.choice(FALLBACKS.get('greetings', FALLBACKS.get('fallback_generic', [])))

    # map keywords to fallback categories
    mapping = {
        'phish': 'phishing',
        'scam': 'phishing',
        'password': 'passwords',
        'pass': 'passwords',
        '2fa': 'two_factor_auth',
        'two-factor': 'two_factor_auth',
        'malware': 'malware_and_virus',
        'virus': 'malware_and_virus',
        'ransom': 'ransomware',
        'sim': 'sim_swap',
        'm-pesa': 'sim_swap',
        'link': 'suspicious_link',
        'social': 'social_engineering',
        'identity': 'identity_theft',
        'wifi': 'public_wifi',
        'vpn': 'vpn',
        'backup': 'backup_and_recovery',
        'iot': 'iot_security',
        'children': 'children_online_safety',
        'email': 'email_security',
        'browser': 'browser_hijack_and_ads',
        'stolen': 'device_theft',
        'recovery': 'account_recovery',
        'oauth': 'oauth_and_third_party_apps',
        'leak': 'credentials_leak',
        'help': 'command_short_help',
    }

    for k, cat in mapping.items():
        if k in text:
            choices = FALLBACKS.get(cat) or FALLBACKS.get('fallback_generic')
            return random.choice(choices) if choices else FALLBACKS.get('fallback_generic', ['Sorry, something went wrong.'])[0]

    # default generic fallback
    generic = FALLBACKS.get('fallback_generic') or FALLBACKS.get('command_short_help') or []
    return random.choice(generic) if generic else 'Sorry, I could not help with that right now.'


async def generate_agent_response(message: str, history: list[dict] | None = None) -> str:
    """
    Generates a response from the Guardian agent for the given message, optionally
    grounded in prior conversation turns for continuity.
    """
    if not message or not message.strip():
        return "Please type a question or describe what you'd like help with."

    try:
        response = await client.aio.models.generate_content(
            model='gemini-1.5-flash',
            contents=_build_contents(message, history),
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT,
                temperature=0.6,
                max_output_tokens=1024,
            ),
        )

        text = (response.text or "").strip() if response else ""
        if not text:
            logger.warning("Gemini returned an empty response for message: %r", message)
            # fallback to local responses
            return get_fallback_response(message)

        return text

    except Exception:
        logger.exception("Failed to generate agent response from Gemini")
        return get_fallback_response(message)