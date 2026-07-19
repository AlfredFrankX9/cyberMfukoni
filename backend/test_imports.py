print("Testing imports...")
from app.core.config import settings
from app.db.session import SessionLocal, Base, engine
from app.models.user import User
from app.models.game import QuizAttempt
from app.models.history import ScamAnalysis, ChatMessage
from app.services.intel_service import get_intel_feed
from app.services.mulika_service import analyze_message_content
from app.services.agent_service import generate_agent_response
from app.api.endpoints import router
print("All imports successful! Syntax and dependency resolution verified.")
