FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .

RUN pip uninstall -y flask_sqlalchemy && \
    pip install --no-cache-dir Flask-SQLAlchemy==3.1.1

COPY . .

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

