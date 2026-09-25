from sqlalchemy import text
from app.db import SessionLocal


_CUSTOMER_COLUMNS = """
    customer_id, first_name, last_name, email, phone, [adress] AS address,
    created_at
"""


def list_customers(search: str = "") -> list[dict]:
    search = search.strip()
    parameters = {}
    where_clause = ""
    if search:
        where_clause = "WHERE CAST(customer_id AS VARCHAR(20)) = :customer_id OR email LIKE :email"
        parameters = {
            "customer_id": search,
            "email": f"%{search}%",
        }

    with SessionLocal() as db:
        result = db.execute(
            text(
                f"""
                SELECT {_CUSTOMER_COLUMNS}
                FROM Customers
                {where_clause}
                ORDER BY last_name, first_name, customer_id
                """
            ),
            parameters,
        )
        return [dict(row) for row in result.mappings().all()]


def update_customer(customer_id: int, values: dict[str, str]) -> None:
    with SessionLocal.begin() as db:
        result = db.execute(
            text(
                """
                UPDATE Customers
                SET first_name = :first_name,
                    last_name = :last_name,
                    email = :email,
                    phone = :phone,
                    [adress] = :address
                WHERE customer_id = :customer_id
                """
            ),
            {**values, "customer_id": customer_id},
        )
        if result.rowcount != 1:
            raise ValueError("Customer could not be found.")


def anonymize_customer(customer_id: int) -> None:
    """Remove personal data while preserving order and shipment references."""
    with SessionLocal.begin() as db:
        result = db.execute(
            text(
                """
                UPDATE Customers
                SET first_name = :first_name,
                    last_name = :last_name,
                    email = NULL,
                    phone = NULL,
                    [adress] = NULL
                WHERE customer_id = :customer_id
                """
            ),
            {
                "first_name": "Borttagen",
                "last_name": "Kund",
                "customer_id": customer_id,
            },
        )
        if result.rowcount != 1:
            raise ValueError("Customer could not be found.")
