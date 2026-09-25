from sqlalchemy import text

from app.db import SessionLocal
from app.security.passwords import verify_password


def authenticate_user(username: str, password: str):
	with SessionLocal() as db:
		result = db.execute(
			text(
				"""
				SELECT u.user_id, u.username, u.password_hash, r.role_name
				FROM Users AS u
				INNER JOIN Roles AS r ON r.role_id = u.role_id
				WHERE u.username = :username
				"""
			),
			{"username": username},
		).mappings().first()

	if result is None or not verify_password(password, result["password_hash"]):
		return None

	return {
		"user_id": result["user_id"],
		"username": result["username"],
		"role": result["role_name"],
	}
