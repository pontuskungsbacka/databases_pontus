from app.menus.base_menu import show_role_menu


def customer_menu(user):
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table
    from sqlalchemy.exc import SQLAlchemyError

    from app.cli.theme import ThemeClasses
    from app.customers import anonymize_customer, list_customers, update_customer

    console = Console()

    def _pause():
        console.input("Press Enter to go back...")

    def _show_customer(customer):
        table = Table(show_header=False, box=None)
        table.add_column("Field", style=ThemeClasses.Colors.PRIMARY, width=16)
        table.add_column("Value")
        table.add_row("Customer ID", str(customer["customer_id"]))
        table.add_row("First name", customer["first_name"])
        table.add_row("Last name", customer["last_name"])
        table.add_row("Email", customer["email"] or "-")
        table.add_row("Phone", customer["phone"] or "-")
        table.add_row("Address", customer["address"] or "-")
        console.print(Panel(table, title="Selected customer", border_style=ThemeClasses.Colors.BORDER_DEFAULT))

    def _edit_customer(customer):
        console.clear()
        _show_customer(customer)
        console.print("Leave a field blank to keep its current value.")

        values = {
            "first_name": console.input(f"First name [{customer['first_name']}]: ").strip() or customer["first_name"],
            "last_name": console.input(f"Last name [{customer['last_name']}]: ").strip() or customer["last_name"],
            "email": console.input(f"Email [{customer['email'] or '-'}]: ").strip() or customer["email"] or "",
            "phone": console.input(f"Phone [{customer['phone'] or '-'}]: ").strip() or customer["phone"] or "",
            "address": console.input(f"Address [{customer['address'] or '-'}]: ").strip() or customer["address"] or "",
        }

        try:
            update_customer(customer["customer_id"], values)
            customer.update(values)
            console.print(Panel("Customer details updated successfully.", style="bold green"))
        except (SQLAlchemyError, ValueError) as error:
            console.print(Panel(f"Could not update customer: {error}", style="bold red"))
        _pause()

    def _anonymize_customer(customer):
        confirmation = console.input(
            f"Type ANONYMIZE to remove personal data for "
            f"{customer['first_name']} {customer['last_name']}: "
        ).strip()
        if confirmation != "ANONYMIZE":
            console.print(Panel("Customer details were not changed.", style="bold yellow"))
            _pause()
            return False

        try:
            anonymize_customer(customer["customer_id"])
            console.print(
                Panel(
                    "Personal data anonymized. Customer ID and history were preserved.",
                    style="bold green",
                )
            )
            _pause()
            return True
        except (SQLAlchemyError, ValueError) as error:
            console.print(Panel(f"Could not anonymize customer: {error}", style="bold red"))
            _pause()
            return False

    def _manage_customer(customer):
        while True:
            console.clear()
            _show_customer(customer)
            menu = Table(show_header=False, box=None)
            menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
            menu.add_column("Function", style=ThemeClasses.Colors.TEXT_MUTED)
            menu.add_row("1", "Edit customer details")
            menu.add_row("2", "Anonymize customer data")
            menu.add_row("0", "Back to customer list")
            console.print(Panel(menu, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

            choice = console.input("Select an option: ").strip()
            if choice == "1":
                _edit_customer(customer)
            elif choice == "2":
                if _anonymize_customer(customer):
                    return
            elif choice == "0":
                return
            else:
                console.print(Panel("Invalid choice.", style="bold red"))

    def _customer_table(customers):
        table = Table(title="Customers", header_style=ThemeClasses.TextStyles.HEADER)
        table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        table.add_column("Customer ID")
        table.add_column("Name")
        table.add_column("Email")
        table.add_column("Phone")
        table.add_column("Address")
        for index, customer in enumerate(customers, start=1):
            table.add_row(
                str(index),
                str(customer["customer_id"]),
                f"{customer['first_name']} {customer['last_name']}",
                customer["email"] or "-",
                customer["phone"] or "-",
                customer["address"] or "-",
            )
        return table

    if user.get("role", "").lower() not in {"manager", "employee"}:
        console.print(Panel("You do not have permission to manage customers.", style="bold red"))
        _pause()
        return

    search = ""
    while True:
        console.clear()
        try:
            customers = list_customers(search)
            console.print(
                Panel(
                    f"[bold]User:[/bold] {user['username']}\n"
                    f"[bold]Role:[/bold] {user['role'].title()}",
                    title="Customer management",
                    border_style=ThemeClasses.Colors.BORDER_DEFAULT,
                )
            )
            if customers:
                console.print(Panel(_customer_table(customers), border_style=ThemeClasses.Colors.BORDER_DEFAULT))
            else:
                console.print(Panel("No customers matched the search.", style="bold yellow"))
        except SQLAlchemyError as error:
            console.print(Panel(f"Could not read customers: {error}", style="bold red"))
            _pause()
            return

        menu = Table(show_header=False, box=None)
        menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
        menu.add_column("Function", style=ThemeClasses.Colors.TEXT_MUTED)
        menu.add_row("S", "Search by customer_id or email")
        menu.add_row("0", "Back")
        console.print(Panel(menu, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

        choice = console.input("Select a customer, S to search, or 0: ").strip()
        if choice == "0":
            return
        if choice.lower() == "s":
            search = console.input("Search by customer_id or email (blank shows all): ").strip()
            continue
        try:
            customer_index = int(choice) - 1
            if not 0 <= customer_index < len(customers):
                raise IndexError
            _manage_customer(customers[customer_index])
        except (ValueError, IndexError):
            console.print(Panel("Invalid customer choice.", style="bold red"))