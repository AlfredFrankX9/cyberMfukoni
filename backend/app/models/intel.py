from sqlalchemy import Column, Integer, String, Text, DateTime
from app.db.session import Base
from datetime import datetime, timezone

class IntelArticle(Base):
    __tablename__ = "intel_articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    summary = Column(Text)
    image_url = Column(String, nullable=True)
    source_url = Column(String)
    source_name = Column(String)
    severity = Column(String)
    published_at = Column(DateTime)
    fetched_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))