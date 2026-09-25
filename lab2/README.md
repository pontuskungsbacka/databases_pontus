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

## Database justification for the assignment

### Purpose of the database

The database is designed for a bookstore with several stores. It separates the
book catalogue, authors, customers, orders, stock, sales transactions, users,
and store access. This makes it possible to manage the daily operations of a
bookstore while keeping historical sales and inventory information available
for reporting.

### Tables and their business purpose

The following tables are entities that are relevant to the bookstore:

- `Books`: stores each book title, ISBN, language, price, release date,
	category, publisher, and description.
- `Authors`: stores author information independently from books.
- `Publishers`: stores publisher information so the publisher is not repeated
	for every book row.
- `Categories`: stores reusable book categories.
- `Customers`: stores customer contact information and the customer creation
	date.
- `Stores`: stores the bookstore locations and their addresses.
- `Orders`: stores customer purchases and the store where an order was made.
- `ShipmentStatus`: stores the allowed shipment/order status values.
- `Shipments`: stores deliveries and transfers between stores or to customers.
- `InventoryBalance`: stores the current quantity of each book at each store.
- `InventoryTransactions`: stores the history of sales, deliveries, returns,
	adjustments, and book movements.
- `Returns`: stores returned orders and the employee who processed them.
- `Promotions`: stores campaigns and discount rules that can be used by the
	bookstore.
- `Roles`: stores application roles such as admin, manager, employee, and
	stockroom.
- `Users`: stores application login accounts and their roles.
- `Employees`: stores employee profiles connected to application users.

This gives more than the eight independent entities required for the higher
grade. The database is not only a catalogue; it also models sales, customers,
stores, inventory, logistics, and application administration.

### Junction tables and relationships

`AuthorsBooks` is a junction table between `Authors` and `Books`. It allows a
book to have several authors and an author to write several books. This is the
many-to-many relationship.

`OrderDetails`, `ShipmentItems`, and `ReturnItems` connect orders, shipments,
returns, and books. These tables are junction/detail tables and are not counted
as independent entities in the eight-entity requirement.

`UserStoreAccess` connects users to stores. It is used by the Python
application to ensure that an employee can only see sales for the store to
which the employee is assigned.

### Normalization and integrity

The design separates facts that belong to different subjects. For example,
publisher data is stored in `Publishers`, category data in `Categories`, and
author data in `Authors` instead of being repeated in every `Books` row. This
reduces update anomalies and supports 3NF-oriented design.

Every main table has a primary key. Foreign keys connect related records and
prevent references to records that do not exist. Examples include:

- `Books.categoryID` -> `Categories.categoryID`
- `Books.publisherID` -> `Publishers.publisherID`
- `Orders.customer_id` -> `Customers.customer_id`
- `Orders.store_id` -> `Stores.store_id`
- `InventoryBalance.ISBN` -> `Books.ISBN`
- `InventoryBalance.store_id` -> `Stores.store_id`
- `AuthorsBooks` -> both `Authors` and `Books`

Check constraints also prevent invalid values such as non-numeric ISBN values,
negative inventory, and non-positive order quantities. Datatypes are selected
according to the data: `DECIMAL(10,2)` for prices, `DATE` for release dates,
`DATETIME2` for timestamps, `INT` for identifiers and quantities, and text
types for names and descriptions.

### Views and their usefulness

#### `TitlesPerAuthor`

`TitlesPerAuthor` combines `Authors`, `AuthorsBooks`, `Books`, and
`InventoryBalance`. It shows each author, age, number of book titles, and the
inventory value connected to that author's books.

A bookstore can use this view to answer questions such as:

- Which authors have the largest catalogue?
- How much stock value is connected to an author's books?
- Which authors' books should be included in a campaign or review?

This is the required view for the assignment. The application uses the English
name `TitlesPerAuthor` because the database objects are written in English.

#### `MostSoldBooks`

`MostSoldBooks` combines `Books`, `Authors`, `Categories`, and
`InventoryTransactions`. It calculates sold copies and revenue per title.

Managers can use it to identify popular titles, plan reorders, compare
categories, and decide which books should receive more shelf space or
promotion.

#### `InventoryByStore`

`InventoryByStore` combines `Stores`, `InventoryBalance`, and `Books`. It shows
the number of available titles, total copies, and inventory value per store.

This helps managers and stockroom staff compare stores, find stores with low
stock, and understand how much capital is tied up in inventory. It is also the
basis for the application's company-wide and store-specific inventory view.

#### `DailySalesStatistics`

`DailySalesStatistics` combines `InventoryTransactions` and `Books` and groups
sales by date. It shows the number of sold copies and the sales value for each
day.

Employees can see sales for their assigned store, while managers and stockroom
users can select a specific store or view the total for all stores. The view is
useful for daily follow-up, comparing sales periods, and identifying unusual
sales patterns.

### `MoveBook` stored procedure

`MoveBook` is used when a manager or stockroom employee transfers books between
stores. It validates the source store, destination store, ISBN, quantity, user,
and available stock before making any changes.

The procedure writes an outgoing and an incoming inventory transaction in one
SQL transaction. The inventory trigger then updates `InventoryBalance`. If a
validation fails, the transaction is rolled back and an explanatory error is
returned. This prevents stock from disappearing or becoming negative during a
store transfer.

### Test data and Python functionality

The SQL script contains "realistic" test data for stores, books, authors,
publishers, categories, customers, orders, shipments, inventory, returns, and
sales. The May 2026 sales data makes the reporting views demonstrable and
contains a deliberate sold-out book for testing stock status.

The Python application demonstrates the database through Rich menus. It
supports login, role-based menus, customer management, book search, stock
lookups, inventory summaries, sales reports, date and store drill-down, and
book transfers. Employees are limited to the stores assigned in
`UserStoreAccess`, while managers and stockroom users can inspect all stores.
