from dotenv import load_dotenv
load_dotenv()

from app.core.config import settings
from sqlalchemy import create_engine, text
from app.db.base import Base

print(f"Connecting to: {settings.SQLALCHEMY_DATABASE_URI.split('@')[1]}")

engine = create_engine(settings.SQLALCHEMY_DATABASE_URI)
conn = engine.connect()

result = conn.execute(text("SELECT version()"))
print(f"PostgreSQL connected!")
print(f"Version: {result.fetchone()[0]}")

# Create all tables
Base.metadata.create_all(bind=engine)

# List tables
result = conn.execute(text("SELECT tablename FROM pg_tables WHERE schemaname='public'"))
tables = result.fetchall()
print(f"\nTables created ({len(tables)}):")
for row in tables:
    print(f"  - {row[0]}")

conn.close()
print("\nDatabase is ready!")
