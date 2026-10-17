# ---- Build Stage ----
FROM python:3.12-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Runtime Stage ----
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

COPY --from=builder /install /usr/local
COPY . .

EXPOSE 8003

CMD ["gunicorn", "--bind", "0.0.0.0:8003", "--workers", "2", "app:app"]
