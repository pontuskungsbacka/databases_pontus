import bcrypt

def _to_bytes(value: str | bytes) -> bytes:
    return value.encode("utf-8") if isinstance(value, str) else value

def hash_password(password: str | bytes) -> str:
    """Return a bcrypt hash suitable for storing in Users.password_hash."""
    return bcrypt.hashpw(_to_bytes(password), bcrypt.gensalt()).decode("utf-8")

def verify_password(password: str | bytes, hashed: str | bytes) -> bool:
    """Return True when password matches a stored bcrypt hash."""
    return bcrypt.checkpw(_to_bytes(password), _to_bytes(hashed))