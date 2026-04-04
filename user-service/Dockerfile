# ── Stage 1: Builder ──────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Final image ───────────────────────

FROM python:3.11-slim AS final

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -u 10001 app-user

WORKDIR /app

COPY --from=builder /install /usr/local

COPY . .

RUN chown -R app-user:app-user /app

USER app-user

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]