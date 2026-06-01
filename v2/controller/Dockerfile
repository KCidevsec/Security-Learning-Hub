# Controller image. BUILD CONTEXT MUST BE v2/ (it bakes in platform/ + exercises/ so the
# controller can render the same templates the manual scripts use).
#   docker build -f controller/Dockerfile -t slh/controller:dev .
FROM python:3.12-slim

WORKDIR /app

COPY controller/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Controller code.
COPY controller/app /app/app

# Templates the controller renders at runtime (same sources as deploy/slice-up.sh).
COPY platform /app/platform
COPY exercises /app/exercises

ENV SLH_BASE_DIR=/app \
    SLH_PLATFORM_DIR=/app/platform \
    SLH_EXERCISES_DIR=/app/exercises

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--ws", "websockets"]
