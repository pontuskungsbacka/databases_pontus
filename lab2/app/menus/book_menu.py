from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from sqlalchemy.exc import SQLAlchemyError

from app.books import get_book_stock, get_top_sold_books, search_books
from app.cli.theme import ThemeClasses
from app.inventory import list_stores, move_book
from app.menus.customer_menu import customer_menu
from app.reports import (
    get_daily_sales,
    get_inventory_by_store,
    get_sales_by_date,
    get_user_store_ids,
)


console = Console()


def _pause(message="Press Enter to go back..."):
    console.input(message)


def _book_table(books):
    table = Table(title="Books", header_style=ThemeClasses.TextStyles.HEADER)
    table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
    table.add_column("ISBN")
    table.add_column("Title")
    table.add_column("Author")
    table.add_column("Release year")
    for index, book in enumerate(books, start=1):
        table.add_row(
            str(index),
            book["ISBN"].strip(),
            book["title"],
            book["authors"] or "Unknown",
            str(book["releasedate"].year),
        )
    return table


def _show_book_details(book):
    console.clear()
    console.print(
        Panel(
            f"[bold]Title:[/bold] {book['title']}\n"
            f"[bold]ISBN:[/bold] {book['ISBN'].strip()}\n"
            f"[bold]Author:[/bold] {book['authors'] or 'Unknown'}\n"
            f"[bold]Release date:[/bold] {book['releasedate']}\n"
            f"[bold]Price:[/bold] {book['price']}",
            title="Book details",
            border_style=ThemeClasses.Colors.BORDER_DEFAULT,
        )
    )
    stock_table = Table(title="Stock by store", header_style=ThemeClasses.TextStyles.HEADER)
    stock_table.add_column("Store")
    stock_table.add_column("Quantity", justify="right")
    try:
        stock = get_book_stock(book["ISBN"])
        for row in stock:
            quantity = row["quantity"]
            stock_table.add_row(
                row["store_name"],
                str(quantity) if quantity > 0 else "Out of stock",
            )
        console.print(Panel(stock_table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))
    except SQLAlchemyError as error:
        console.print(Panel(f"Could not read stock: {error}", style="bold red"))
    _pause()


def _search_books():
    search = console.input("Search by title, author, or release year (blank shows all): ").strip()
    try:
        books = search_books(search)
    except SQLAlchemyError as error:
        console.print(Panel(f"Could not search books: {error}", style="bold red"))
        _pause()
        return

    if not books:
        console.print(Panel("No books matched the search.", style="bold yellow"))
        _pause()
        return

    while True:
        console.clear()
        console.print(Panel(_book_table(books), border_style=ThemeClasses.Colors.BORDER_DEFAULT))
        choice = console.input("Select a book, or 0 to go back: ").strip()
        if choice == "0":
            return
        try:
            book_index = int(choice) - 1
            if not 0 <= book_index < len(books):
                raise IndexError
            _show_book_details(books[book_index])
        except (ValueError, IndexError):
            console.print(Panel("Invalid book choice.", style="bold red"))


def _show_top_sold():
    console.clear()
    try:
        books = get_top_sold_books()
        table = Table(title="Top 10 most sold books", header_style=ThemeClasses.TextStyles.HEADER)
        table.add_column("Rank", style=ThemeClasses.Colors.PRIMARY, width=8)
        table.add_column("Title")
        table.add_column("Author")
        table.add_column("Sold", justify="right")
        table.add_column("Revenue", justify="right")
        for index, book in enumerate(books, start=1):
            table.add_row(
                str(index),
                book["Title"],
                book["Author"],
                str(book["total_sold_books"]),
                f"{book['total_revenue']:.2f}",
            )
        console.print(Panel(table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))
    except SQLAlchemyError as error:
        console.print(Panel(f"Could not read sales statistics: {error}", style="bold red"))
    _pause()


def _show_inventory_overview():
    console.clear()
    try:
        stores = get_inventory_by_store()
        if not stores:
            console.print(Panel("No stores were found.", style="bold yellow"))
            _pause()
            return

        store_table = Table(title="Inventory scope", header_style=ThemeClasses.TextStyles.HEADER)
        store_table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        store_table.add_column("Store")
        for index, store in enumerate(stores, start=1):
            store_table.add_row(str(index), store["store_name"])
        store_table.add_row("A", "All stores")
        console.print(Panel(store_table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

        choice = console.input("Choose a store or A for all stores: ").strip().lower()
        if choice == "a":
            selected = stores
            title = "Company-wide inventory"
        else:
            store_index = int(choice) - 1
            if not 0 <= store_index < len(stores):
                raise IndexError
            selected = [stores[store_index]]
            title = f"Inventory: {selected[0]['store_name']}"

        summary = Table(title=title, header_style=ThemeClasses.TextStyles.HEADER)
        summary.add_column("Scope")
        summary.add_column("Book titles", justify="right")
        summary.add_column("Total copies", justify="right")
        summary.add_column("Inventory value", justify="right")
        book_titles = sum(store["book_titles"] for store in selected)
        total_copies = sum(store["total_copies"] for store in selected)
        inventory_value = sum(store["inventory_value"] for store in selected)
        scope = "All stores" if choice == "a" else selected[0]["store_name"]
        summary.add_row(scope, str(book_titles), str(total_copies), f"{inventory_value:.2f}")
        console.print(Panel(summary, border_style=ThemeClasses.Colors.BORDER_DEFAULT))
    except (ValueError, IndexError):
        console.print(Panel("Invalid store choice.", style="bold red"))
    except SQLAlchemyError as error:
        console.print(Panel(f"Could not read inventory summary: {error}", style="bold red"))
    _pause()


def _choose_sales_scope(user):
    role = (user.get("role") or "").lower()
    if role == "employee":
        store_ids = get_user_store_ids(user["user_id"])
        if not store_ids:
            raise ValueError("Your account is not assigned to a store.")
        return store_ids

    stores = list_stores()
    if not stores:
        raise ValueError("No stores were found.")

    scope_table = Table(title="Sales scope", header_style=ThemeClasses.TextStyles.HEADER)
    scope_table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
    scope_table.add_column("Store")
    scope_table.add_row("A", "All stores")
    for index, store in enumerate(stores, start=1):
        scope_table.add_row(str(index), store["store_name"])
    console.print(Panel(scope_table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

    choice = console.input("Choose a store or A for all stores: ").strip().lower()
    if choice == "a":
        return None
    store_index = int(choice) - 1
    if not 0 <= store_index < len(stores):
        raise IndexError
    return [stores[store_index]["store_id"]]


def _show_daily_sales(user):
    console.clear()
    try:
        store_ids = _choose_sales_scope(user)
        sales = get_daily_sales(store_ids)
        if not sales:
            console.print(Panel("No sales were found for this scope.", style="bold yellow"))
            _pause()
            return
        table = Table(title="Daily sales statistics", header_style=ThemeClasses.TextStyles.HEADER)
        table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        table.add_column("Sales date")
        table.add_column("Sold copies", justify="right")
        table.add_column("Sales value", justify="right")
        for index, day in enumerate(sales, start=1):
            table.add_row(
                str(index),
                str(day["sales_date"]),
                str(day["sold_copies"]),
                f"{day['sales_value']:.2f}",
            )
        console.print(Panel(table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

        choice = console.input("Select a sales date, or 0 to go back: ").strip()
        if choice == "0":
            return

        day_index = int(choice) - 1
        if not 0 <= day_index < len(sales):
            raise IndexError
        selected_date = str(sales[day_index]["sales_date"])
        details = get_sales_by_date(selected_date, store_ids)
        detail_table = Table(
            title=f"Books sold on {selected_date}",
            header_style=ThemeClasses.TextStyles.HEADER,
        )
        detail_table.add_column("Store")
        detail_table.add_column("ISBN")
        detail_table.add_column("Title")
        detail_table.add_column("Author")
        detail_table.add_column("Sold copies", justify="right")
        detail_table.add_column("Sales value", justify="right")
        for book in details:
            detail_table.add_row(
                book["store_name"],
                book["ISBN"].strip(),
                book["title"],
                book["authors"],
                str(book["sold_copies"]),
                f"{book['sales_value']:.2f}",
            )
        console.clear()
        console.print(Panel(detail_table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))
    except SQLAlchemyError as error:
        console.print(Panel(f"Could not read sales statistics: {error}", style="bold red"))
    except (ValueError, IndexError) as error:
        console.print(Panel(f"Invalid sales scope or date choice: {error}", style="bold red"))
    _pause()


def _move_book(user):
    console.clear()
    console.print(Panel("Move book between stores", border_style=ThemeClasses.Colors.BORDER_DEFAULT))
    isbn = console.input("ISBN: ").strip()
    try:
        stores = list_stores()
        if len(stores) < 2:
            console.print(Panel("At least two stores are required.", style="bold red"))
            _pause()
            return

        store_table = Table(title="Stores", header_style=ThemeClasses.TextStyles.HEADER)
        store_table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        store_table.add_column("Store")
        for index, store in enumerate(stores, start=1):
            store_table.add_row(str(index), store["store_name"])
        console.print(store_table)

        from_choice = int(console.input("Source store: ").strip()) - 1
        to_choice = int(console.input("Destination store: ").strip()) - 1
        quantity = int(console.input("Quantity: ").strip())
        if not 0 <= from_choice < len(stores) or not 0 <= to_choice < len(stores):
            raise IndexError

        move_book(
            isbn=isbn,
            from_store_id=stores[from_choice]["store_id"],
            to_store_id=stores[to_choice]["store_id"],
            quantity=quantity,
            created_by_user_id=user["user_id"],
        )
        console.print(Panel("Book moved successfully.", style="bold green"))
    except (ValueError, IndexError):
        console.print(Panel("Store choices and quantity must be valid numbers.", style="bold red"))
    except SQLAlchemyError as error:
        console.print(Panel(f"Book could not be moved: {error}", style="bold red"))
    _pause()


def book_menu(user):
    role = (user.get("role") or "").lower()
    can_move = role in {"manager", "stockroom"}
    can_view_stats = role == "manager"
    can_manage_customers = role in {"manager", "employee"}

    while True:
        console.clear()
        menu = Table(title="Bookstore operations", show_header=False, box=None)
        menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        menu.add_column("Function", style=ThemeClasses.Colors.TEXT_MUTED)
        menu.add_row("1", "Search books and view stock")
        if can_view_stats:
            menu.add_row("2", "Most sold books")
        if can_move:
            menu.add_row("3", "Move book between stores")
        if can_manage_customers:
            menu.add_row("4", "Manage customers")
        if role in {"manager", "stockroom"}:
            menu.add_row("5", "Inventory overview")
        menu.add_row("6", "Daily sales statistics")
        menu.add_row("0", "Log out")
        console.print(Panel(menu, title=f"{role.title()} menu", border_style=ThemeClasses.Colors.BORDER_DEFAULT))

        choice = console.input("Select an option: ").strip()
        if choice == "1":
            _search_books()
        elif choice == "2" and can_view_stats:
            _show_top_sold()
        elif choice == "3" and can_move:
            _move_book(user)
        elif choice == "4" and can_manage_customers:
            customer_menu(user)
        elif choice == "5" and role in {"manager", "stockroom"}:
            _show_inventory_overview()
        elif choice == "6":
            _show_daily_sales(user)
        elif choice == "0":
            return
        else:
            console.print(Panel("Invalid option.", style="bold red"))
