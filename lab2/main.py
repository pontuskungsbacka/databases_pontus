import os
import subprocess
import time
from rich import print
from rich.text import Text
from rich.panel import Panel
from rich.console import Console

console = Console()

def __init__(self):
    self.username = None
    self.password = None

def exit():
    console.print(Panel("Thank you for using Code Block Books Mananger!", style="bold blue"))
    time.sleep(1.0)
    console.clear()

"""========================LOGIN PAGE========================
    Here is the login page function where user input their
    username and password.
    THIS PART IS UNDER CONSTRUCTION, NOT FUNCTIONAL YET. IT IS JUST A PLACEHOLDER.
=========================================================="""
def login():
    console.clear()
    console.print(Panel("Please log in to your account", title="Login", subtitle="Code Block Books Manager", style="green"))
    username = console.input("Username: ")
    password = console.input("Password: ", password=True)
    # Here you would normally check the credentials against a database
    if username == "admin" and password == "password":
        console.print(Panel("Login successful!", style="bold green"))
        return True
    else:
        console.print(Panel("Invalid credentials. Please try again.", style="bold red"))
        return False

about_text = Text.from_markup("""[bold]Code Block Books Manager[/bold] is a simple inventory management application designed to help you create, view, and manage your book collection with ease. \nCode Block Books Manager allows you to organize your books, track their details, and maintain an up-to-date inventory of your collection.\nYou could manage your sales, customers and stores as well.\n\nThis project is a course project for the course "Databases" at IT-Högskolan in Gothenburg, Sweden.\nThe application is built using Python and SQLAlchemy for database management in MS SQL Server, and Rich for a visually appealing command-line interface.\nDesign by [bold]Pontus Johansson[/bold].
                        """)
def about():
    console.clear()
    console.print(Panel(about_text, title="About", subtitle="Code Block Books Manager", style="green",  expand=True, border_style="green"))
    console.print(Panel("Please select an option from the menu below:", title="Menu", style="bold yellow"))
    menu_entry = console.input("0: Back\n1: Exit Application\nEnter your choice: ")

    if menu_entry == "0":
        start()
    elif menu_entry == "1":
        exit()
def admin_login():
    username = console.input("Username: ")
    password = console.input("Password: ", password=True)
    # Here you would normally check the credentials against a database
    if username == "admin" and password == "password":
        console.print(Panel("Login successful!", style="bold green"))
        admin()
    else:
        console.print(Panel("Invalid credentials. Please try again.", style="bold red"))
        start()
def admin():
    console.clear()
    console.print(Panel("Admin Panel", title="Admin", subtitle="Code Block Books Manager", style="green"))
    # Add admin functionality here

    menu_entry = console.input("0: Login\n1: Back\n2: Exit Application\nEnter your choice: ")

    if menu_entry == "0":
        admin_login()
    elif menu_entry == "1":
        start()
    elif menu_entry == "2":
        exit()

def start():
    console.clear()
    console.print(Panel("Welcome to Code Block Books Manager! This is a simple inventory management application. Create, view, and manage your book collection with ease.", title="Home", subtitle="Code Block Books Manager", style="green"))
    console.print(Panel("Please select an option from the menu below:", title="Menu", style="bold yellow"))
    menu_entry = console.input("0: Login\n1: About\n2: Admin\n3: Exit Application\nEnter your choice: ")

    if menu_entry == "0":
        login()
    elif menu_entry == "1":
        about()
    elif menu_entry == "2":
        admin()
    elif menu_entry == "3":
        exit()

if __name__ == "__main__":
    start()