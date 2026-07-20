FROM python:3.11-slim

WORKDIR /app

# Install dependencies from the backend folder
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all backend code into the container
COPY backend/ /app/

# Expose port (Railway automatically maps this)
EXPOSE 8000

# Start the server (JSON array format as recommended by Docker)
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
