FROM python:3.12-alpine
RUN adduser -D app && mkdir /data
WORKDIR /app
COPY backend/app.py .
USER app
EXPOSE 5000
HEALTHCHECK CMD wget -q -O /dev/null http://127.0.0.1:5000/health || exit 1
CMD ["python", "app.py"]
