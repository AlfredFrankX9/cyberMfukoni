from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.db.session import Base

class ReportedNumber(Base):
    __tablename__ = "reported_numbers"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, index=True, nullable=False)
    scam_category = Column(String, nullable=False)
    details = Column(String, nullable=True)
    report_count = Column(Integer, default=1)
    last_reported_at = Column(DateTime, default=datetime.utcnow)
