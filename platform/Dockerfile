FROM python:3.12-slim
WORKDIR /app
COPY platform/api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY platform/api /app/api
COPY platform/frontend /app/frontend
EXPOSE 8000
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
