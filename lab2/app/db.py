import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.engine import URL

from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.status import Status

console = Console()

"""Setting up the database connection and session management.
   Making a more secure way to handle database credentials using environment variables.
   To use this code, create a .env file in the same directory as this script with the following content:
   - DB_SERVER=your_server_name
   - DB_NAME=your_database_name
   - DB_USERNAME=your_username
   - DB_PASSWORD=your_password
   - DB_DRIVER=ODBC Driver 17 for SQL Server  #This depends on the ODBC driver you have installed, adjust if necessary.
   The connection string is constructed using the provided parameters and the ODBC Driver for SQL Server."""

load_dotenv(Path(__file__).with_name(".env"))

DB_SERVER = os.getenv("DB_SERVER")
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_DRIVER = os.getenv("DB_DRIVER")

odbc_str = f"DRIVER={{{DB_DRIVER}}};SERVER={DB_SERVER};DATABASE={DB_NAME};UID={DB_USERNAME};PWD={DB_PASSWORD};Encrypt=yes;TrustServerCertificate=yes;"

connection_url = URL.create("mssql+pyodbc", query={"odbc_connect": odbc_str})

engine = create_engine(connection_url, 
                        fast_executemany=True, 
                        future=True)

# Test connection with loading animation
try:
    with Status("[bold yellow]Connecting to database...[/bold yellow]", spinner="dots", spinner_style="yellow") as status:
        with engine.connect() as conn:
            pass  # Connection successful

    # SUCCESS MESSAGE
    success_text = Text()
    success_text.append("✅ Connection successful!\n\n", style="bold green")
    success_text.append("Transferring control to application:\n", style="bold yellow")
    success_text.append(" → ", style="bold yellow")
    success_text.append("Code Block Books Manager", style="bold green")

    console.print(
        Panel(
            success_text,
            title="DATABASE CONNECTION",
            border_style="green",
            expand=False
        )
    )

except Exception as e:
    # ERROR MESSAGE
    error_text = Text()
    error_text.append("❌ The application could not start due to a configuration error.\n\n", style="bold red")

    error_text.append("Possible causes:\n", style="bold yellow")
    error_text.append(" • Make sure the database is created or restored from backup.\n")
    error_text.append(" • Verify that the .env file contains correct values for:\n")
    error_text.append("     DB_SERVER, DB_NAME, DB_USERNAME, DB_PASSWORD, DB_DRIVER\n")
    error_text.append(" • Ensure that the .env file is located in the project root (Lab2/) or in /app/\n")
    error_text.append(" • Check that ODBC Driver 17/18 for SQL Server is installed.\n\n")

    error_text.append("Technical information (for troubleshooting):\n", style="bold yellow")
    error_text.append(f" {type(e).__name__}: {e}\n", style="red")

    console.print(
        Panel(
            error_text,
            title="DATABASE ERROR",
            border_style="red",
            expand=False
        )
    )
    raise SystemExit(1)


SessionLocal = sessionmaker(bind=engine, 
                            autoflush=False, 
                            autocommit=False,
                            future=True)

Base = declarative_base()

def get_db():
    """Provides a database session for use in the application."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
