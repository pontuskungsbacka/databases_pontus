from sqlalchemy import text

from app.db import SessionLocal


_STORES_SQL = text(
    """
    SELECT store_id, store_name
    FROM Stores
    ORDER BY store_name
    """
)

_MOVE_BOOK_SQL = text(
    """
    EXEC dbo.MoveBook
        @ISBN = :isbn,
        @FromStoreId = :from_store_id,
        @ToStoreId = :to_store_id,
        @Quantity = :quantity,
        @CreatedByUserId = :created_by_user_id
    """
)


def list_stores() -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(_STORES_SQL).mappings().all()
        return [dict(row) for row in rows]


def move_book(
    isbn: str,
    from_store_id: int,
    to_store_id: int,
    quantity: int,
    created_by_user_id: int,
) -> None:
    with SessionLocal.begin() as db:
        db.execute(
            _MOVE_BOOK_SQL,
            {
                "isbn": isbn,
                "from_store_id": from_store_id,
                "to_store_id": to_store_id,
                "quantity": quantity,
                "created_by_user_id": created_by_user_id,
            },
        )
