from rich.console import Console
from rich.panel import Panel

from app.auth import authenticate_user
from app.cli.router import route_user


console = Console()


def login():
	console.clear()
	console.print(
		Panel(
			"Sign in to open the menu for your account.",
			title="Login",
			subtitle="Code Block Books Manager",
			style="green",
		)
	)

	username = console.input("Username: ").strip()
	password = console.input("Password: ", password=True)
	user = authenticate_user(username, password)

	if user is None:
		console.print(Panel("Invalid username or password.", style="bold red"))
		console.input("Press Enter to go back...")
		return False

	console.print(Panel(f"Signed in as {user['username']} ({user['role']}).", style="bold green"))
	route_user(user)
	return True
