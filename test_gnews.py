import sys; sys.path.append('backend'); from app.core.config import settings; from app.services.intel_service import fetch_and_cache_intel; fetch_and_cache_intel()
