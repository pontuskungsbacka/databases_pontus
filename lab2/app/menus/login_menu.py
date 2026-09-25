
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
