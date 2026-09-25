from sqlalchemy import text

from app.db import SessionLocal
from app.security.passwords import hash_password


_ALL_USERS_SQL = text(
    """
    SELECT u.user_id, u.username, r.role_name AS role,
           e.first_name, e.last_name, e.email
    FROM Users AS u
    INNER JOIN Roles AS r ON r.role_id = u.role_id
    LEFT JOIN Employees AS e ON e.user_id = u.user_id
    ORDER BY u.username
    """
)

_ROLES_SQL = text(
    """
    SELECT role_id, role_name
    FROM Roles
    WHERE LOWER(role_name) <> 'admin'
    ORDER BY role_name
    """
)


def list_all_users() -> list[dict]:
    with SessionLocal() as db:
        return [dict(row) for row in db.execute(_ALL_USERS_SQL).mappings().all()]


def list_managed_roles() -> list[dict]:
    with SessionLocal() as db:
        return [dict(row) for row in db.execute(_ROLES_SQL).mappings().all()]


def update_user_password(user_id: int, new_password: str) -> None:
    with SessionLocal.begin() as db:
        result = db.execute(
            text(
                """
                UPDATE Users
                SET password_hash = :password_hash
                WHERE user_id = :user_id
                  AND role_id IN (
                      SELECT role_id FROM Roles
                      WHERE LOWER(role_name) <> 'admin'
                  )
                """
            ),
            {"password_hash": hash_password(new_password), "user_id": user_id},
        )
        if result.rowcount != 1:
            raise ValueError("User does not exist or is an admin.")


def update_user_role(user_id: int, role_id: int) -> None:
    with SessionLocal.begin() as db:
        role_exists = db.execute(
            text(
                """
                SELECT 1
                FROM Roles
                WHERE role_id = :role_id
                  AND LOWER(role_name) <> 'admin'
                """
            ),
            {"role_id": role_id},
        ).scalar_one_or_none()
        if role_exists is None:
            raise ValueError("Selected role does not exist or is admin.")

        target_exists = db.execute(
            text(
                """
                SELECT 1
                FROM Users AS u
                INNER JOIN Roles AS current_role ON current_role.role_id = u.role_id
                WHERE u.user_id = :user_id
                  AND LOWER(current_role.role_name) <> 'admin'
                """
            ),
            {"user_id": user_id},
        ).scalar_one_or_none()
        if target_exists is None:
            raise ValueError("User does not exist or is an admin.")

        db.execute(
            text("UPDATE Users SET role_id = :role_id WHERE user_id = :user_id"),
            {"role_id": role_id, "user_id": user_id},
        )
        db.execute(
            text("UPDATE Employees SET role_id = :role_id WHERE user_id = :user_id"),
            {"role_id": role_id, "user_id": user_id},
        )
