from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.session import Base


class ChonjoLevelScore(Base):
    """Tracks the maximum score a user has achieved on each Chonjo level."""
    __tablename__ = "chonjo_level_scores"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    level = Column(Integer, nullable=False)
    max_score = Column(Integer, default=0)  # best score on this level (out of 100)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Certificate tracking — only set when user completes level 10
    cert_earned_at = Column(DateTime(timezone=True), nullable=True)
