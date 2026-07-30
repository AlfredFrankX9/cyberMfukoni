from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router as api_router
from app.api.auth import router as auth_router
from app.db.session import engine, Base
from app.models.user import User
from app.models.game import QuizAttempt
from app.models.history import ScamAnalysis, ChatMessage
from app.models.intel import IntelArticle
from app.models.active_defense import ReportedNumber
app = FastAPI(
    title="Cyber Mfukoni 2.0 API",
    description="AI-Powered Cybersecurity Platform",
    version="2.0.0",
)

# Configure CORS for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins, adjust for production
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables on startup
@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    print("[OK] Database tables created/verified.")
    
    from app.services.intel_service import start_scheduler, fetch_and_cache_intel
    start_scheduler()
    
    # Optionally trigger an initial fetch in background if empty (safe to just let the scheduler handle it, but we want immediate data)
    from app.db.session import SessionLocal
    from app.models.intel import IntelArticle
    db = SessionLocal()
    if db.query(IntelArticle).count() == 0:
        import threading
        threading.Thread(target=fetch_and_cache_intel, daemon=True).start()
    db.close()

app.include_router(auth_router, prefix="/api/auth", tags=["auth"])
app.include_router(api_router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "Welcome to Cyber Mfukoni 2.0 API"}

if __name__ == "__main__":
    import os
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
