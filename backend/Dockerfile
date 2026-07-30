FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Expose port (Railway sets PORT env var)
EXPOSE 8000

# Start the server
CMD ["python", "main.py"]
