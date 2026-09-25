from sqlalchemy import text

from app.db import SessionLocal


_BOOK_SEARCH_SQL = text(
    """
    SELECT b.ISBN, b.title, b.releasedate, b.price,
           STRING_AGG(a.FirstName + ' ' + a.LastName, ', ') AS authors
    FROM Books AS b
    LEFT JOIN AuthorsBooks AS ab ON ab.ISBN = b.ISBN
    LEFT JOIN Authors AS a ON a.author_id = ab.author_id
    WHERE (:search = ''
           OR b.title LIKE :like_search
           OR a.FirstName + ' ' + a.LastName LIKE :like_search
           OR a.FirstName LIKE :like_search
           OR a.LastName LIKE :like_search
           OR CONVERT(VARCHAR(4), YEAR(b.releasedate)) = :search)
    GROUP BY b.ISBN, b.title, b.releasedate, b.price
    ORDER BY b.title
    """
)

_BOOK_STOCK_SQL = text(
    """
    SELECT s.store_id, s.store_name, COALESCE(ib.Quantity, 0) AS quantity
    FROM Stores AS s
    LEFT JOIN InventoryBalance AS ib
      ON ib.store_id = s.store_id AND ib.ISBN = :isbn
    ORDER BY s.store_name
    """
)

_MOST_SOLD_SQL = text(
    """
    SELECT TOP 10 ISBN, Title, Author, Category,
           [Total sold Books] AS total_sold_books,
           [Total Revenue] AS total_revenue
    FROM MostSoldBooks
    ORDER BY [Total sold Books] DESC, Title
    """
)


def search_books(search: str = "") -> list[dict]:
    search = search.strip()
    with SessionLocal() as db:
        rows = db.execute(
            _BOOK_SEARCH_SQL,
            {"search": search, "like_search": f"%{search}%"},
        ).mappings().all()
        return [dict(row) for row in rows]


def get_book_stock(isbn: str) -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(_BOOK_STOCK_SQL, {"isbn": isbn}).mappings().all()
        return [dict(row) for row in rows]


def get_top_sold_books() -> list[dict]:
    with SessionLocal() as db:
        rows = db.execute(_MOST_SOLD_SQL).mappings().all()
        return [dict(row) for row in rows]
