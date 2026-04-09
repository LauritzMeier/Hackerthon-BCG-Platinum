FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/src \
    PORT=8080

COPY requirements.txt ./
COPY agent/requirements.txt ./agent-requirements.txt
RUN pip install --no-cache-dir -r requirements.txt -r agent-requirements.txt

COPY src ./src
COPY agent ./agent
COPY scripts ./scripts
COPY sql ./sql
COPY data/raw ./data/raw

EXPOSE 8080

CMD ["sh", "-c", "uvicorn agent.server:app --host 0.0.0.0 --port ${PORT:-8080}"]
