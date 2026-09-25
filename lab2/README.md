Welcome to Code Block Books
===========================

This application is part of a school assignment in the Database course in the
AI and Machine Learning Developer program at ITHS Gothenburg.

The application was created by Pontus Johansson.

## Requirements

Install the following before starting:

- Python 3.13 or later
- uv
- SQL Server
- SQL Server Management Studio (SSMS), or an equivalent SQL client
- ODBC Driver 17 or 18 for SQL Server

## Setup

### 1. Download the repository

Clone or download this repository and open a terminal in the repository root.

### 2. Create the database

Open `lab2/PontusJohansson.sql` in SQL Server Management Studio and execute the
complete file from the beginning.

The script creates the `CodeBlockBooks` database, its tables, relationships,
views, test data, sales data, and the `MoveBook` procedure.

The script also contains the application permissions section. If you use the
database login named `admin`, make sure that this login exists in SQL Server.
The script creates the database user for that login when the login is available.

Do not execute only a selected part of the SQL file. Run the complete file so
that all tables and dependencies are created in the correct order.

### 3. Configure the database connection

Copy `lab2/.env_example.txt` to `lab2/app/.env` and replace the values with
your own SQL Server connection details.

The `.env` file must be placed in the `lab2/app` folder because the application
loads it from there. Never commit the real `.env` file to GitHub.

Example:

```env
DB_USERNAME=admin
DB_PASSWORD=your_database_password
DB_SERVER=localhost
DB_NAME=CodeBlockBooks
DB_DRIVER=ODBC Driver 18 for SQL Server
```

Use the SQL Server login credentials for `DB_USERNAME` and `DB_PASSWORD`.
These are database connection credentials, not the application login.

### 4. Create the Python environment and install dependencies

From the repository root, run:

```powershell
uv venv .venv
.venv\Scripts\activate
uv sync
```

### 5. Create and update application users

Run:

```powershell
uv run --directory lab2 python users_init.py
```

This creates or updates the application users, roles, employee profiles, and
store access.

### 6. Start the application

Run:

```powershell
uv run --directory lab2 python main.py
```

Use the demo usernames and passwords listed in `lab2/users_init.py` to log in.
For example, the admin account is defined there with username `0000` and the
password shown in the `USERS` collection.

## Main functionality

Depending on the role, the application supports:

- User management for administrators
- Customer management and GDPR-oriented anonymization
- Book search by title, author, or release year
- Stock levels by store
- Inventory summaries and inventory values
- Daily sales statistics and sales details by date and store
- Moving books between stores for managers and stockroom users

## Important files

- `PontusJohansson.sql`: creates and seeds the database
- `users_init.py`: creates application users and store access
- `app/.env`: local database connection settings, never commit this file
- `app/`: Python application source code
- `pyproject.toml`: Python dependencies and project configuration
