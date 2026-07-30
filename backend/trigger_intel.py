import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.services.intel_service import fetch_and_cache_intel

fetch_and_cache_intel()
