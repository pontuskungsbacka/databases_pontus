from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from app.cli.theme import ThemeClasses


console = Console()


def show_role_menu(user, role_name: str, options: str):
    console.clear()
    console.print(
        Panel(
            f"[bold]User:[/bold] {user['username']}\n"
            f"[bold]Role:[/bold] {role_name.title()}",
            title="Code Block Books Manager",
            border_style=ThemeClasses.Colors.BORDER_DEFAULT,
        )
    )

    menu = Table(title=f"{role_name.title()} Menu", show_header=False, box=None)
    menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
    menu.add_column("Access", style=ThemeClasses.Colors.TEXT_MUTED)
    menu.add_row("1", options)
    menu.add_row("0", "Log out")
    console.print(Panel(menu, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

    return console.input("Select an option: ").strip() == "0"