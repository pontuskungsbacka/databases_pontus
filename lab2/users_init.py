"""Create and update application users in CodeBlockBooks SQL Server."""

from sqlalchemy import text

from app.db import engine
from app.security.passwords import hash_password


ROLES = ("admin", "manager", "employee", "stockroom", "logistics", "supplier")

USERS = (
    ("0000", "Admin123!", "admin", "System", "Administrator", "admin@codeblockbooks.se", 1),
    ("0001", "Man0F¤RC6B!", "manager", "Store", "Manager", "manager@codeblockbooks.se", 1),
    ("2000", "Stock123!", "stockroom", "Stockroom", "User", "stockroom@codeblockbooks.se", 6),
    ("3000", "Logi123!", "logistics", "Logistics", "User", "logistics@codeblockbooks.se", 6),
    ("4000", "Supplier123!", "supplier", "Supplier", "User", "supplier@codeblockbooks.se", 6),
    ("1000", "Emp1F¤RC6B!", "employee", "Erik", "Svensson", "emp_central_1@codeblockbooks.se", 1),
    ("1001", "Emp2F¤RC6B!", "employee", "Maja", "Lind", "emp_central_2@codeblockbooks.se", 1),
    ("1002", "Emp3F¤RC6B!", "employee", "Linnea", "Berg", "emp_north_1@codeblockbooks.se", 2),
    ("1003", "Emp4F¤RC6B!", "employee", "Viktor", "Holm", "emp_north_2@codeblockbooks.se", 2),
    ("1004", "Emp5F¤RC6B!", "employee", "Nora", "Ek", "emp_malmo_1@codeblockbooks.se", 3),
    ("1005", "Emp6F¤RC6B!", "employee", "Hugo", "Dahl", "emp_malmo_2@codeblockbooks.se", 3),
    ("1006", "Emp7F¤RC6B!", "employee", "Alva", "Nyberg", "emp_stockholm_1@codeblockbooks.se", 4),
    ("1007", "Emp8F¤RC6B!", "employee", "Oscar", "Wik", "emp_stockholm_2@codeblockbooks.se", 4),
)


def seed_roles(connection):
    for role_name in ROLES:
        connection.execute(
            text(
                """
                IF NOT EXISTS (SELECT 1 FROM Roles WHERE role_name = :role_name)
                    INSERT INTO Roles (role_name) VALUES (:role_name)
                """
            ),
            {"role_name": role_name},
        )


def get_role_id(connection, role_name: str) -> int:
    return connection.execute(
        text("SELECT role_id FROM Roles WHERE role_name = :role_name"),
        {"role_name": role_name},
    ).scalar_one()


def seed_user(connection, user_data):
    username, password, role_name, first_name, last_name, email, store_id = user_data
    role_id = get_role_id(connection, role_name)
    password_hash = hash_password(password)
    user_id = connection.execute(
        text("SELECT user_id FROM Users WHERE username = :username"),
        {"username": username},
    ).scalar_one_or_none()

    if user_id is None:
        user_id = connection.execute(
            text(
                """
                INSERT INTO Users (username, password_hash, role_id)
                OUTPUT INSERTED.user_id
                VALUES (:username, :password_hash, :role_id)
                """
            ),
            {"username": username, "password_hash": password_hash, "role_id": role_id},
        ).scalar_one()
    else:
        connection.execute(
            text(
                """
                UPDATE Users
                SET password_hash = :password_hash, role_id = :role_id
                WHERE user_id = :user_id
                """
            ),
            {"password_hash": password_hash, "role_id": role_id, "user_id": user_id},
        )

    connection.execute(
        text(
            """
            IF EXISTS (SELECT 1 FROM Employees WHERE user_id = :user_id)
                UPDATE Employees
                SET role_id = :role_id, first_name = :first_name,
                    last_name = :last_name, email = :email
                WHERE user_id = :user_id
            ELSE
                INSERT INTO Employees (user_id, role_id, first_name, last_name, email)
                VALUES (:user_id, :role_id, :first_name, :last_name, :email)
            """
        ),
        {
            "user_id": user_id,
            "role_id": role_id,
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
        },
    )

    connection.execute(
        text(
            """
            IF NOT EXISTS (
                SELECT 1 FROM UserStoreAccess
                WHERE user_id = :user_id AND store_id = :store_id
            )
                INSERT INTO UserStoreAccess (user_id, store_id)
                VALUES (:user_id, :store_id)
            """
        ),
        {"user_id": user_id, "store_id": store_id},
    )


def initialize_users():
    with engine.begin() as connection:
        seed_roles(connection)
        for user_data in USERS:
            seed_user(connection, user_data)

    print(f"User initialization complete: {len(USERS)} users are ready.")


if __name__ == "__main__":
    initialize_users()