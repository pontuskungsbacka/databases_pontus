from sqlalchemy import text

from app.db import SessionLocal


_INVENTORY_BY_STORE_SQL = text(
    """
    SELECT s.store_id, s.store_name,
           COUNT(DISTINCT CASE WHEN COALESCE(ib.Quantity, 0) > 0 THEN ib.ISBN END) AS book_titles,
           COALESCE(SUM(COALESCE(ib.Quantity, 0)), 0) AS total_copies,
           COALESCE(SUM(COALESCE(ib.Quantity, 0) * COALESCE(b.price, 0)), 0) AS inventory_value
    FROM Stores AS s
    LEFT JOIN InventoryBalance AS ib ON ib.store_id = s.store_id
    LEFT JOIN Books AS b ON b.ISBN = ib.ISBN
    GROUP BY s.store_id, s.store_name
    ORDER BY s.store_name
    """
)

_DAILY_SALES_SQL = text(
    """
    SELECT CAST(t.created_at AS DATE) AS sales_date,
           SUM(ABS(t.quantity_change)) AS sold_copies,
           SUM(ABS(t.quantity_change) * b.price) AS sales_value
    FROM InventoryTransactions AS t
    INNER JOIN Books AS b ON b.ISBN = t.ISBN
    WHERE t.reason = 'sale'
    GROUP BY CAST(t.created_at AS DATE)
    ORDER BY sales_date DESC
    """
)

_SALES_BY_DATE_SQL = text(
    """
        SELECT s.store_name,
            b.ISBN,
           b.title,
           COALESCE(
               (
                   SELECT STRING_AGG(a2.FirstName + ' ' + a2.LastName, ', ')
                   FROM AuthorsBooks AS ab2
                   INNER JOIN Authors AS a2 ON a2.author_id = ab2.author_id
                   WHERE ab2.ISBN = b.ISBN
               ),
               'Unknown'
           ) AS authors,
           SUM(ABS(t.quantity_change)) AS sold_copies,
           SUM(ABS(t.quantity_change) * b.price) AS sales_value
    FROM InventoryTransactions AS t
    INNER JOIN Books AS b ON b.ISBN = t.ISBN
        INNER JOIN Stores AS s ON s.store_id = t.store_id
    WHERE t.reason = 'sale'
      AND CAST(t.created_at AS DATE) = :sales_date
        GROUP BY s.store_name, b.ISBN, b.title
        ORDER BY s.store_name, sold_copies DESC, b.title
    """
)


def get_inventory_by_store() -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(_INVENTORY_BY_STORE_SQL).mappings().all()
        return [dict(row) for row in rows]


def _store_filter(store_ids: list[int] | None) -> tuple[str, dict]:
    if not store_ids:
        return "", {}
    placeholders = ", ".join(f":store_id_{index}" for index in range(len(store_ids)))
    return f" AND t.store_id IN ({placeholders})", {
        f"store_id_{index}": store_id for index, store_id in enumerate(store_ids)
    }


def get_user_store_ids(user_id: int) -> list[int]:
    with SessionLocal() as db:
        rows = db.execute(
            text("SELECT store_id FROM UserStoreAccess WHERE user_id = :user_id"),
            {"user_id": user_id},
        ).scalars().all()
        return list(rows)


def get_daily_sales(store_ids: list[int] | None = None) -> list[dict]:
    store_clause, parameters = _store_filter(store_ids)
    with SessionLocal() as db:
        query = _DAILY_SALES_SQL.text.replace("GROUP BY", f"{store_clause}\n    GROUP BY")
        rows = db.execute(text(query), parameters).mappings().all()
        return [dict(row) for row in rows]


def get_sales_by_date(sales_date: str, store_ids: list[int] | None = None) -> list[dict]:
    store_clause, parameters = _store_filter(store_ids)
    parameters["sales_date"] = sales_date
    with SessionLocal() as db:
        rows = db.execute(
            text(_SALES_BY_DATE_SQL.text.replace("AND CAST", f"{store_clause}\n      AND CAST")),
            parameters,
        ).mappings().all()
        return [dict(row) for row in rows]
