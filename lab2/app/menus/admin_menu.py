from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from sqlalchemy.exc import SQLAlchemyError

from app.admin import (
	list_managed_roles,
	list_all_users,
	update_user_password,
	update_user_role,
)
from app.cli.theme import ThemeClasses


console = Console()


def _pause(message="Press Enter to go back..."):
	console.input(message)


def _show_not_implemented():
	console.clear()
	console.print(
		Panel(
			"Editing user details has not been implemented yet.",
			title="User details",
			border_style=ThemeClasses.Colors.BORDER_DEFAULT,
		)
	)
	_pause()


def _change_password(selected_user):
	console.clear()
	console.print(Panel(f"Change password for {selected_user['username']}"))
	new_password = console.input("New password: ", password=True)
	confirmation = console.input("Confirm password: ", password=True)

	if not new_password:
		console.print(Panel("Password cannot be empty.", style="bold red"))
	elif new_password != confirmation:
		console.print(Panel("Passwords do not match.", style="bold red"))
	else:
		try:
			update_user_password(selected_user["user_id"], new_password)
			console.print(Panel("Password changed successfully.", style="bold green"))
		except (SQLAlchemyError, ValueError) as error:
			console.print(Panel(f"Could not change password: {error}", style="bold red"))
	_pause()


def _change_role(selected_user):
	roles = list_managed_roles()
	if not roles:
		console.print(Panel("No selectable roles are available.", style="bold red"))
		_pause()
		return

	console.clear()
	console.print(Panel(f"Change role for {selected_user['username']}"))
	role_table = Table(show_header=True, header_style=ThemeClasses.TextStyles.HEADER)
	role_table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
	role_table.add_column("Role")
	for index, role in enumerate(roles, start=1):
		role_table.add_row(str(index), role["role_name"].title())
	console.print(role_table)

	choice = console.input("Choose a new role, or 0 to go back: ").strip()
	if choice == "0":
		return
	try:
		role_index = int(choice) - 1
		if not 0 <= role_index < len(roles):
			raise IndexError
		selected_role = roles[role_index]
		update_user_role(selected_user["user_id"], selected_role["role_id"])
		selected_user["role"] = selected_role["role_name"]
		console.print(Panel("Role changed successfully.", style="bold green"))
	except (ValueError, IndexError, SQLAlchemyError) as error:
		console.print(Panel(f"Invalid choice or update failed: {error}", style="bold red"))
	_pause()


def _manage_user(selected_user):
	if selected_user["role"].lower() == "admin":
		console.clear()
		console.print(
			Panel(
				"The admin account is visible but cannot be changed here.",
				title="Read-only user",
				border_style=ThemeClasses.Colors.BORDER_DEFAULT,
			)
		)
		_pause()
		return

	while True:
		console.clear()
		console.print(
			Panel(
				f"[bold]Username:[/bold] {selected_user['username']}\n"
				f"[bold]Role:[/bold] {selected_user['role'].title()}",
				title="Manage user",
				border_style=ThemeClasses.Colors.BORDER_DEFAULT,
			)
		)
		menu = Table(show_header=False, box=None)
		menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
		menu.add_column("Function", style=ThemeClasses.Colors.TEXT_MUTED)
		menu.add_row("1", "Change password")
		menu.add_row("2", "Change role")
		menu.add_row("3", "Edit user details")
		menu.add_row("0", "Back")
		console.print(Panel(menu, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

		choice = console.input("Select an option: ").strip()
		if choice == "1":
			_change_password(selected_user)
		elif choice == "2":
			_change_role(selected_user)
		elif choice == "3":
			_show_not_implemented()
		elif choice == "0":
			return
		else:
			console.print(Panel("Invalid choice.", style="bold red"))


def _users_menu():
	while True:
		console.clear()
		users = list_all_users()
		user_table = Table(title="Users", header_style=ThemeClasses.TextStyles.HEADER)
		user_table.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
		user_table.add_column("Username")
		user_table.add_column("Role")
		user_table.add_column("Name")
		user_table.add_column("Email")
		for index, managed_user in enumerate(users, start=1):
			name = " ".join(
				part for part in (managed_user["first_name"], managed_user["last_name"]) if part
			) or "-"
			user_table.add_row(
				str(index),
				managed_user["username"],
				managed_user["role"].title(),
				name,
				managed_user["email"] or "-",
			)
		console.print(Panel(user_table, border_style=ThemeClasses.Colors.BORDER_DEFAULT))
		choice = console.input("Select a user, or 0 to go back: ").strip()
		if choice == "0":
			return
		try:
			user_index = int(choice) - 1
			if not 0 <= user_index < len(users):
				raise IndexError
			_manage_user(users[user_index])
		except (ValueError, IndexError):
			console.print(Panel("Invalid user choice.", style="bold red"))


def _show_admin_section(title: str, description: str):
	console.clear()
	console.print(
		Panel(
			description,
			title=f"Admin / {title}",
			border_style=ThemeClasses.Colors.BORDER_DEFAULT,
		)
	)
	console.input("Press Enter to return to the admin menu...")


def admin_menu(user):
	while True:
		console.clear()
		console.print(
			Panel(
				f"[bold]User:[/bold] {user['username']}\n"
				f"[bold]Role:[/bold] {user['role'].title()}",
				title="Code Block Books Manager",
				border_style=ThemeClasses.Colors.BORDER_DEFAULT,
			)
		)

		menu = Table(title="Admin Menu", show_header=False, box=None)
		menu.add_column("Choice", style=ThemeClasses.Colors.PRIMARY, width=8)
		menu.add_column("Function", style=ThemeClasses.Colors.TEXT_MUTED)
		menu.add_row("1", "Users: view and manage users")
		menu.add_row("2", "Stores: view and manage stores")
		menu.add_row("3", "System settings")
		menu.add_row("0", "Log out and return to the home screen")
		menu.add_row("9", "Exit application")
		console.print(Panel(menu, border_style=ThemeClasses.Colors.BORDER_DEFAULT))

		choice = console.input("Select an option: ").strip()
		if choice == "1":
			_users_menu()
		elif choice == "2":
			_show_admin_section("Stores", "Store management and store access will be added here.")
		elif choice == "3":
			_show_admin_section("System settings", "System settings and database status will be added here.")
		elif choice == "0":
			return
		elif choice == "9":
			raise SystemExit
		else:
			console.print(Panel("Invalid choice.", style="bold red"))
