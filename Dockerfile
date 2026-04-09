FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src \
    PORT=8080

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY src ./src
COPY scripts ./scripts
COPY sql ./sql
COPY data/raw ./data/raw

RUN python scripts/build_warehouse.py

EXPOSE 8080

CMD ["sh", "-c", "uvicorn longevity_mvp.api:app --host 0.0.0.0 --port ${PORT:-8080}"]
