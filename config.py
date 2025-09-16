import os


from pathlib import Path

def read_secret_env(name: str, default: str | None = None) -> str | None:
    """
    Önce NAME_FILE env var'ına bakar; varsa dosyayı okuyup döner.
    Yoksa doğrudan NAME env var'ını döner.
    """
    file_var = os.getenv(f"{name}_FILE")
    if file_var and Path(file_var).exists():
        try:
            return Path(file_var).read_text().strip()
        except Exception:
            pass
    return os.getenv(name, default)

class Config:
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASS = os.getenv("DB_PASS", "postgres")
    DB_HOST = os.getenv("DB_HOST", "postgres-db")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "postgres")

    SQLALCHEMY_DATABASE_URI = (
        f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

        # Tek kullanıcı için sabit değerler
    APP_USER = os.getenv("APP_USER", "admin")
    APP_PASS = read_secret_env("APP_PASS", "changeme")




    # JWT Secret: JWT_SECRET veya JWT_SECRET_FILE'dan
    JWT_SECRET_KEY = read_secret_env("JWT_SECRET", None)
    # Secret yoksa fail et (prod için iyi pratik)
    if not JWT_SECRET_KEY:
        raise RuntimeError("JWT_SECRET / JWT_SECRET_FILE set edilmemiş! Lütfen bir secret sağlayın.")

