FROM python:3.13-slim # For AWS, use FROM --platform=linux/amd64 python:3.13-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN sed -i 's/\r$//' setup.sh && \
    chmod +x setup.sh

EXPOSE 8000

CMD ["./setup.sh"] # For AWS, run CMD ["/bin/bash", "./setup.sh"] 
