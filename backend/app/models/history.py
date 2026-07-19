from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from app.db.session import Base

class ScamAnalysis(Base):
    __tablename__ = "scam_analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_content = Column(Text, nullable=False)
    scam_probability = Column(Integer, nullable=False)
    risk_rating = Column(String(50), nullable=False)
    red_flags = Column(Text) # JSON string of list of flags
    explanation = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String(50), nullable=False) # 'user' or 'agent'
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
