/* Intial SQL query for Code Block Books
	Creating tables and inserting data for Code Block Books
	Course: Databas
	Created by: Pontus Johansson
	AIM25G */
USE master;
GO

IF DB_ID(N'CodeBlockBooks') IS NOT NULL
BEGIN
    ALTER DATABASE CodeBlockBooks SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CodeBlockBooks;
END;
GO

CREATE DATABASE CodeBlockBooks;
GO

USE CodeBlockBooks;
GO
-- CREATING ADMIN USER
/* IF admin login does not exist, create it and also create
	admin USER to the database and for the LOGIN admin*/
-- CREATE LOGIN admin WITH PASSWORD = 'Adm@Passwor123!'; --THIS IS AN EXAMPLE PASSWORD, CHANGE IT TO A STRONGER ONE IN PRODUCTION ENVIRONMENTS
-- CREATE USER admin FOR LOGIN admin;

/* Creating Table for roles, this will be used to assign different permissions to users based on their roles in the system.
    Creating a Users table to store user information, including username, password, and role. This will allow us to manage user access and permissions effectively.
    Creating a Employees table to store employee information, including name, position, and contact details. This will help in managing employee data and their roles within the organization.
	*/
CREATE TABLE Roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    CONSTRAINT FK_Users_Roles FOREIGN KEY (role_id)
        REFERENCES Roles(role_id)
);

CREATE TABLE Employees (
    [user_id] INT PRIMARY KEY,
    role_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,

    CONSTRAINT FK_Employees_Users FOREIGN KEY ([user_id])
        REFERENCES Users([user_id]),

    CONSTRAINT FK_Employees_Roles FOREIGN KEY (role_id)
        REFERENCES Roles(role_id)
);

CREATE TABLE Stores (
    store_id INT IDENTITY(1,1) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE UserStoreAccess (
    [user_id] INT NOT NULL,
    store_id INT NOT NULL,

    CONSTRAINT PK_UserStoreAccess PRIMARY KEY ([user_id], store_id),

    CONSTRAINT FK_UserStoreAccess_Users FOREIGN KEY ([user_id])
        REFERENCES Users([user_id]),

    CONSTRAINT FK_UserStoreAccess_Stores FOREIGN KEY (store_id)
        REFERENCES Stores(store_id)
);

/* Creating a Publishers table to store information about book publishers, including their name and contact details. This will help in managing publisher data and their relationships with books.
    Creating a Categories table to store different book categories, allowing for better organization and filtering of books based on their genre or type.
    Creating a Books table to store detailed information about each book, including its ISBN, title, category, price, publisher, and release date. This will be the central table for managing book data and its relationships with authors, publishers, and inventory.
    Creating an Authors table to store information about book authors, including their name and birthday. This will help in managing author data and their relationships with books.
    Creating an AuthorsBooks table to manage the many-to-many relationship between authors and books, allowing for accurate representation of which authors have written which books.
    Cr
    */


CREATE TABLE Publishers (
    publisherID INT IDENTITY(1,1) PRIMARY KEY,
    PublisherName VARCHAR(200) NOT NULL
);

CREATE TABLE Categories (
    categoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);

CREATE TABLE Books (
    ISBN CHAR(13) NOT NULL,
    title NVARCHAR(200) NOT NULL,
    language CHAR(2) NOT NULL, -- EN or SV
    categoryID INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    publisherID INT NOT NULL,
    releasedate DATE NOT NULL,
    description NVARCHAR(MAX) NOT NULL,

    CONSTRAINT PK_Books PRIMARY KEY (ISBN),

    CONSTRAINT FK_Books_Categories FOREIGN KEY (categoryID)
        REFERENCES Categories(categoryID),

    CONSTRAINT FK_Books_Publishers FOREIGN KEY (publisherID)
        REFERENCES Publishers(publisherID),

    CONSTRAINT CK_Books_ISBN_Length CHECK (LEN(ISBN) = 13),
    CONSTRAINT CK_Books_ISBN_Numeric CHECK (ISBN NOT LIKE '%[^0-9]%')
);

CREATE TABLE Authors (
    author_id INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName  VARCHAR(50) NOT NULL,
    birthdate  DATE NOT NULL
);

CREATE TABLE AuthorsBooks (
    author_id INT NOT NULL,
    ISBN CHAR(13) NOT NULL,

    CONSTRAINT PK_AuthorsBooks PRIMARY KEY (author_id, ISBN),

    CONSTRAINT FK_AuthorsBooks_Authors FOREIGN KEY (author_id)
        REFERENCES Authors(author_id),

    CONSTRAINT FK_AuthorsBooks_Books FOREIGN KEY (ISBN)
        REFERENCES Books(ISBN)
);

CREATE TABLE Customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(50),
    adress VARCHAR(200),
    created_at DATETIME2 NOT NULL DEFAULT GETDATE()
);


CREATE TABLE ShipmentStatus (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    StatusName VARCHAR(50) NOT NULL
);

CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    store_id INT NOT NULL,
    order_date DATE NOT NULL,
    status_id INT NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (status_id) REFERENCES ShipmentStatus(status_id)
);

CREATE TABLE OrderDetails (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    ISBN CHAR(13) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (ISBN) REFERENCES Books(ISBN)
);

CREATE TABLE Shipments (
    shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    from_store_id INT NULL REFERENCES Stores(store_id),
    to_store_id INT NULL REFERENCES Stores(store_id),
    to_customer_id INT NULL REFERENCES Customers(customer_id),
    direction_type VARCHAR(50) NOT NULL,   -- 'store_to_store', 'store_to_customer', 'customer_return'
    status_id INT NOT NULL REFERENCES ShipmentStatus(status_id),
    created_by_user_id INT NOT NULL REFERENCES Users(user_id),
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    received_at DATETIME2 NULL,
    notes NVARCHAR(400) NULL
);

CREATE TABLE ShipmentItems (
    shipment_item_id INT IDENTITY(1,1) PRIMARY KEY,
    shipment_id INT NOT NULL REFERENCES Shipments(shipment_id),
    ISBN CHAR(13) NOT NULL REFERENCES Books(ISBN),
    quantity INT NOT NULL
);

CREATE TABLE InventoryBalance (
    store_id INT NOT NULL,
    ISBN CHAR(13) NOT NULL,
    Quantity INT NOT NULL,

    CONSTRAINT PK_InventoryBalance PRIMARY KEY (store_id, ISBN),

    CONSTRAINT FK_InventoryBalance_Stores FOREIGN KEY (store_id)
        REFERENCES Stores(store_id),

    CONSTRAINT FK_InventoryBalance_Books FOREIGN KEY (ISBN)
        REFERENCES Books(ISBN)
);

CREATE TABLE InventoryTransactions (
  transaction_id INT IDENTITY(1,1) PRIMARY KEY,
  store_id INT NOT NULL REFERENCES Stores(store_id),
  ISBN CHAR(13) NOT NULL REFERENCES Books(ISBN),
  quantity_change INT NOT NULL, 
  reason VARCHAR(50) NOT NULL,             -- 'shipment_out', 'shipment_in', 'sale', 'return', 'adjustment'
  order_id INT NULL REFERENCES Orders(order_id),
  shipment_id INT NULL REFERENCES Shipments(shipment_id),
  created_by_user_id INT NOT NULL REFERENCES Users(user_id),
  created_at DATETIME2 NOT NULL DEFAULT GETDATE()
);
-- ALTER InventoryBalance so we can't have negative quantity
ALTER TABLE InventoryBalance
WITH CHECK
ADD CONSTRAINT CK_InventoryBalance_Quantity_NonNegative
CHECK (Quantity >= 0);

-- AlTER OrderDetails so we can't have negative or zero quantity
ALTER TABLE OrderDetails
WITH CHECK
ADD CONSTRAINT CK_OrderDetails_Quantity_Positive
CHECK (Quantity > 0);


CREATE TABLE [Returns] (
    return_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES Orders(order_id),
    store_id INT NOT NULL FOREIGN KEY REFERENCES Stores(store_id),
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    processed_by_user_id INT NOT NULL FOREIGN KEY REFERENCES Users(user_id),
    return_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    reason VARCHAR(255),
    status VARCHAR(50) NOT NULL
);

CREATE TABLE ReturnItems (
    return_item_id INT IDENTITY(1,1) PRIMARY KEY,
    return_id INT NOT NULL REFERENCES Returns(return_id),
    order_detail_id INT NOT NULL REFERENCES OrderDetails(order_detail_id),
    ISBN CHAR(13) NOT NULL REFERENCES Books(ISBN),
    quantity INT NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Promotions (
    promotion_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    discount_type VARCHAR(20) NOT NULL, -- percent or fixed
    discount_value DECIMAL(10,2) NOT NULL,
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2 NOT NULL,
    active BIT NOT NULL DEFAULT 1
);

INSERT INTO ShipmentStatus (StatusName) VALUES ('Created');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Picked');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Packed');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Shipped');
INSERT INTO ShipmentStatus (StatusName) VALUES ('InTransit');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Received');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Delivered');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Cancelled');
INSERT INTO ShipmentStatus (StatusName) VALUES ('Returned');

INSERT INTO Roles (role_name)
VALUES
    ('admin'),
    ('manager'),
    ('employee'),
    ('stockroom'),
    ('logistics'),
    ('supplier');

/* Internal seed users satisfy the audit foreign keys in the demo transactions. */
INSERT INTO Users (username, password_hash, role_id)
SELECT seed.username, seed.password_hash, r.role_id
FROM (VALUES
    ('seed_admin', '$2b$12$TyqB08t7Nr7DlX/Fkr5bzOfTMlqCc1EA88X6q2vYIumeDhKET20Ca', 'admin'),
    ('seed_manager', '$2b$12$TyqB08t7Nr7DlX/Fkr5bzOfTMlqCc1EA88X6q2vYIumeDhKET20Ca', 'manager'),
    ('seed_employee', '$2b$12$TyqB08t7Nr7DlX/Fkr5bzOfTMlqCc1EA88X6q2vYIumeDhKET20Ca', 'employee'),
    ('seed_stockroom', '$2b$12$TyqB08t7Nr7DlX/Fkr5bzOfTMlqCc1EA88X6q2vYIumeDhKET20Ca', 'stockroom'),
    ('seed_logistics', '$2b$12$TyqB08t7Nr7DlX/Fkr5bzOfTMlqCc1EA88X6q2vYIumeDhKET20Ca', 'logistics')
) AS seed(username, password_hash, role_name)
INNER JOIN Roles AS r ON LOWER(r.role_name) = LOWER(seed.role_name);
GO

INSERT INTO Customers (first_name, last_name, email, phone, adress)
VALUES
    ('Emma', 'Larsson', 'emma.larsson@example.se', '070-1234567', 'Storgatan 12, Kungsbacka'),
    ('Johan', 'Berg', 'johan.berg@example.se', '070-9876543', 'Hantverksgatan 8, Kungsbacka'),
    ('Sara', 'Lindholm', 'sara.lindholm@example.se', '073-5566778', 'Kungsgatan 5, Kungsbacka'),
    ('Marcus', 'Sjoberg', 'marcus.sjoberg@example.se', '076-1122334', 'Borgmastaregatan 22, Kungsbacka'),
    ('Elin', 'Wester', 'elin.wester@example.se', '070-9988776', 'Norra Torggatan 3, Kungsbacka'),
    ('Oskar', 'Nystrom', 'oskar.nystrom@example.se', '072-3344556', 'Hedevagen 14, Kungsbacka'),
    ('Frida', 'Ekstrom', 'frida.ekstrom@example.se', '070-4455667', 'Sodra Vagen 19, Kungsbacka'),
    ('Henrik', 'Karlsson', 'henrik.karlsson@example.se', '073-7788991', 'Vallgatan 2, Kungsbacka'),
    ('Nina', 'Holm', 'nina.holm@example.se', '076-2233445', 'Stationsgatan 7, Kungsbacka'),
    ('Patrik', 'Dahl', 'patrik.dahl@example.se', '070-6677889', 'Gamla Vagen 11, Kungsbacka'),
    ('Karin', 'Sundberg', 'karin.sundberg@example.se', '073-8899001', 'Lilla Torggatan 4, Kungsbacka'),
    ('Daniel', 'Akesson', 'daniel.akesson@example.se', '070-5566778', 'Ostra Hamngatan 9, Kungsbacka'),
    ('Maja', 'Nilsson', 'maja.nilsson@example.se', '070-1000001', 'Parkgatan 1, Kungsbacka'),
    ('Noah', 'Olsson', 'noah.olsson@example.se', '070-1000002', 'Parkgatan 2, Kungsbacka'),
    ('Alice', 'Lund', 'alice.lund@example.se', '070-1000003', 'Parkgatan 3, Kungsbacka'),
    ('Liam', 'Bergman', 'liam.bergman@example.se', '070-1000004', 'Parkgatan 4, Kungsbacka'),
    ('Elsa', 'Holmberg', 'elsa.holmberg@example.se', '070-1000005', 'Parkgatan 5, Kungsbacka'),
    ('Hugo', 'Sand', 'hugo.sand@example.se', '070-1000006', 'Parkgatan 6, Kungsbacka'),
    ('Alva', 'Lind', 'alva.lind@example.se', '070-1000007', 'Parkgatan 7, Kungsbacka'),
    ('Leo', 'Dahlberg', 'leo.dahlberg@example.se', '070-1000008', 'Parkgatan 8, Kungsbacka');
GO

-- Orders
CREATE INDEX IX_Orders_CustomerId ON Orders(customer_id);
CREATE INDEX IX_Orders_StoreId ON Orders(store_id);
CREATE INDEX IX_Orders_StatusId ON Orders(status_id);
CREATE INDEX IX_Orders_OrderDate ON Orders(order_date);

-- OrderDetails
CREATE INDEX IX_OrderDetails_OrderId ON OrderDetails(order_id);
CREATE INDEX IX_OrderDetails_ISBN ON OrderDetails(ISBN);

-- InventoryTransactions
CREATE INDEX IX_InventoryTransactions_StoreISBN_Date
    ON InventoryTransactions(store_id, ISBN, created_at);
CREATE INDEX IX_InventoryTransactions_ISBN_Date
    ON InventoryTransactions(ISBN, created_at);

-- InventoryBalance (PK finns redan, men ett covering index för queries per ISBN kan hjälpa)
CREATE INDEX IX_InventoryBalance_ISBN ON InventoryBalance(ISBN);

-- Shipments and ShipmentItems
CREATE INDEX IX_Shipments_StatusId_CreatedAt ON Shipments(status_id, created_at);
CREATE INDEX IX_Shipments_FromStoreId ON Shipments(from_store_id);
CREATE INDEX IX_Shipments_ToStoreId ON Shipments(to_store_id);
CREATE INDEX IX_Shipments_ToCustomerId ON Shipments(to_customer_id);

CREATE INDEX IX_ShipmentItems_ShipmentId ON ShipmentItems(shipment_id);
CREATE INDEX IX_ShipmentItems_ISBN ON ShipmentItems(ISBN);

-- Returns and ReturnItems
CREATE INDEX IX_Returns_OrderId ON [Returns](order_id);
CREATE INDEX IX_Returns_StoreId ON [Returns](store_id);
CREATE INDEX IX_ReturnItems_ReturnId ON ReturnItems(return_id);
CREATE INDEX IX_ReturnItems_OrderDetailId ON ReturnItems(order_detail_id);
CREATE INDEX IX_ReturnItems_ISBN ON ReturnItems(ISBN);

-- Customers
CREATE INDEX IX_Customers_Email ON Customers(email);

-- Stores
SET IDENTITY_INSERT Stores ON;
INSERT INTO Stores (store_id, store_name, address, city) VALUES
(1, 'Code Block Books Central Store', 'Storgatan 1', 'Gothenburg'),
(2, 'Code Block Books North', 'Norra Vägen 12', 'Kungsbacka'),
(3, 'Code Block Books Malmö', 'Södra Förstadsgatan 18', 'Malmö'),
(4, 'Code Block Books Stockholm', 'Sveavägen 12', 'Stockholm'),
(5, 'Code Block Books Lund', 'Universitetsplatsen 2', 'Lund'),
(6, 'Code Block Books Online', 'Logistics Park 3', 'Mölndal'),
(7, 'Code Block Books Outlet - Hede Kungsbacka', 'Hedevägen 2', 'Kungsbacka');
SET IDENTITY_INSERT Stores OFF;

SET IDENTITY_INSERT Orders ON;
INSERT INTO Orders (order_id, customer_id, store_id, order_date, status_id)
VALUES
(1, 1, 1, '2026-01-12', 7),
(2, 2, 4, '2026-01-15', 7),
(3, 3, 6, '2026-01-18', 7),
(4, 4, 2, '2026-01-20', 7),
(5, 5, 3, '2026-01-22', 7),
(6, 6, 5, '2026-01-25', 7),
(7, 7, 1, '2026-01-27', 7),
(8, 8, 4, '2026-01-29', 7),
(9, 9, 6, '2026-02-01', 7),
(10, 10, 3, '2026-02-03', 7),
(11, 11, 2, '2026-02-05', 7),
(12, 12, 5, '2026-02-07', 7),
(13, 13, 1, '2026-02-10', 7),
(14, 14, 4, '2026-02-12', 7),
(15, 15, 6, '2026-02-14', 7),
(16, 16, 3, '2026-02-16', 7),
(17, 17, 2, '2026-02-18', 7),
(18, 18, 5, '2026-02-20', 7),
(19, 19, 1, '2026-02-22', 7),
(20, 20, 4, '2026-02-25', 7);
SET IDENTITY_INSERT Orders OFF;

;WITH Numbers AS (
    SELECT TOP (60)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO Shipments
    (from_store_id, to_store_id, direction_type, status_id, created_by_user_id, created_at)
SELECT
    ((n - 1) % 7) + 1,
    (n % 7) + 1,
    'store_to_store',
    1,
    ((n - 1) % 5) + 1,
    DATEADD(DAY, n - 1, CAST('2026-01-01' AS DATETIME2))
FROM Numbers;
GO

SET IDENTITY_INSERT Authors ON;

INSERT INTO Authors (author_id, firstname, lastname, birthdate) VALUES
(1, 'Emma', 'Lindström', '1981-04-12'),
(2, 'Jonas', 'Berg', '1975-09-03'),
(3, 'Sofia', 'Nyberg', '1988-11-22'),
(4, 'Lars', 'Holm', '1972-02-17'),
(5, 'Mikael', 'Sundqvist', '1980-07-29'),
(6, 'Anna', 'Ekström', '1990-03-14'),
(7, 'Daniel', 'Forsberg', '1984-12-01'),
(8, 'Karin', 'Åkesson', '1979-05-09'),
(9, 'Oskar', 'Lindahl', '1986-08-25'),
(10, 'Maria', 'Hansson', '1983-01-30'),
(11, 'James', 'Carter', '1977-06-18'),
(12, 'Alicia', 'Reyes', '1989-10-11'),
(13, 'Michael', 'Thompson', '1974-03-02'),
(14, 'Sarah', 'Mitchell', '1985-09-27'),
(15, 'David', 'Kim', '1982-12-19'),
(16, 'Emily', 'Chen', '1991-07-05'),
(17, 'Robert', 'Hughes', '1978-04-23'),
(18, 'Linda', 'Cooper', '1987-02-14'),
(19, 'Thomas', 'Wright', '1976-11-08'),
(20, 'Julia', 'Fischer', '1984-05-21'),
(21, 'Markus', 'Weber', '1979-09-12'),
(22, 'Hannah', 'Schmidt', '1990-01-17'),
(23, 'Peter', 'Keller', '1981-03-29'),
(24, 'Nina', 'Vogel', '1986-10-04'),
(25, 'Alex', 'Novak', '1983-06-15'),
(26, 'Elena', 'Kuznetsova', '1988-08-19'),
(27, 'Ivan', 'Petrov', '1975-12-09'),
(28, 'Svetlana', 'Morozova', '1982-04-01'),
(29, 'Hiroshi', 'Tanaka', '1977-07-22'),
(30, 'Yuki', 'Sato', '1992-03-11'),
(31, 'Chen', 'Wei', '1980-09-30'),
(32, 'Li', 'Mei', '1989-05-06'),
(33, 'Carlos', 'Ramirez', '1983-02-28'),
(34, 'Isabella', 'Torres', '1991-11-13'),
(35, 'Mateo', 'Silva', '1984-08-02'),
(36, 'Camila', 'Fernandez', '1987-12-25'),
(37, 'John', 'O’Connor', '1976-10-19'),
(38, 'Aoife', 'Murphy', '1985-04-07'),
(39, 'Patrick', 'Doyle', '1979-01-28'),
(40, 'Emma', 'Walsh', '1990-06-09'),
(41, 'Noah', 'Anderson', '1986-03-03'),
(42, 'Grace', 'Bennett', '1988-09-14'),
(43, 'Oliver', 'Harris', '1981-12-20'),
(44, 'Chloe', 'Morgan', '1992-07-01'),
(45, 'Ethan', 'Scott', '1983-05-18'),
(46, 'Ava', 'Rogers', '1989-10-29'),
(47, 'Lucas', 'Perry', '1984-11-05'),
(48, 'Mia', 'Brooks', '1991-02-16'),
(49, 'Henry', 'Bell', '1978-08-27'),
(50, 'Lily', 'Ward', '1986-04-30'),
(51, 'Victor', 'Johansson', '1982-09-09'),
(52, 'Elin', 'Karlsson', '1990-12-12'),
(53, 'Henrik', 'Persson', '1977-03-08'),
(54, 'Sara', 'Björk', '1985-07-19'),
(55, 'Tobias', 'Månsson', '1983-11-01'),
(56, 'Ida', 'Sjöberg', '1992-01-26'),
(57, 'Anders', 'Lund', '1979-06-14'),
(58, 'Frida', 'Hellström', '1988-09-23'),
(59, 'Patrik', 'Ström', '1981-02-05'),
(60, 'Helena', 'Vikström', '1987-10-30');

SET IDENTITY_INSERT Authors OFF;



SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (categoryID, categoryName) VALUES
(1, 'programming'),
(2, 'analytics'),
(3, 'databases'),
(4, 'artificial intelligence'),
(5, 'project management'),
(6, 'machine learning'),
(7, 'cybersecurity'),
(8, 'governance');

SET IDENTITY_INSERT Categories OFF;
SET IDENTITY_INSERT Publishers ON;

INSERT INTO Publishers (publisherID, publisherName) VALUES
(1, 'CodeHouse'),
(2, 'DevPress'),
(3, 'NetBooks'),
(4, 'SystemsPub'),
(5, 'TypeWorks'),
(6, 'WebForge'),
(7, 'MobileBooks'),
(8, 'JVMPress'),
(9, 'CloudPub'),
(10, 'DataWorks'),
(11, 'InsightPress'),
(12, 'StatHouse'),
(13, 'VizMedia'),
(14, 'ScaleBooks'),
(15, 'MarketPub'),
(16, 'ExperimentPress'),
(17, 'CausalBooks'),
(18, 'DBPress'),
(19, 'QueryWorks'),
(20, 'SchemaFree'),
(21, 'EnterpriseDB'),
(22, 'ModelPress'),
(23, 'GraphHouse'),
(24, 'OpsBooks'),
(25, 'AIPress'),
(26, 'EthicPub'),
(27, 'DeepHouse'),
(28, 'NeuroPress'),
(29, 'BizTech'),
(30, 'ExplainPub'),
(31, 'EdgeWorks'),
(32, 'ProdPress'),
(33, 'GenMedia'),
(34, 'PMPress'),
(35, 'RiskBooks'),
(36, 'PeoplePub'),
(37, 'FinancePress'),
(38, 'DeliveryPub'),
(39, 'LeadHouse'),
(40, 'ToolWorks'),
(41, 'EngBooks'),
(42, 'FeaturePub'),
(43, 'DeployHouse'),
(44, 'RLPress'),
(45, 'AutoPub'),
(46, 'ProbPress'),
(47, 'SecureCode'),
(48, 'RedTeamPress'),
(49, 'DefendHouse'),
(50, 'AuthPress'),
(51, 'ThreatWorks'),
(52, 'CryptoPub'),
(53, 'BluePress'),
(54, 'GovPress'),
(55, 'PolicyHouse'),
(56, 'RegPress'),
(57, 'BoardBooks'),
(58, 'PrivacyPub'),
(59, 'ResiliencePress'),
(60, 'AIGov'),
(61, 'IncidentPub');

SET IDENTITY_INSERT Publishers OFF;

INSERT INTO Books (ISBN, title, language, categoryID, price, publisherID, releasedate, description)
VALUES
('9789143127741', 'Practical Python Patterns', 'EN', 1, 499.00, 1, '2021-05-10', 'Design patterns and idioms for practical Python development.'),
('9789143127742', 'Modern JavaScript Design', 'EN', 1, 549.00, 2, '2022-03-22', 'Modern architecture and patterns for large JavaScript applications.'),
('9789143127743', 'Go in Production', 'EN', 1, 590.00, 3, '2023-07-01', 'Deploying and operating Go services at scale.'),
('9789143127744', 'Rust Systems Programming', 'EN', 1, 620.00, 4, '2024-02-14', 'Systems programming with Rust: safety and performance.'),
('9789143127745', 'Effective TypeScript', 'EN', 1, 450.00, 5, '2020-09-30', 'Best practices for TypeScript in production codebases.'),
('9789143127746', 'Full Stack with Django', 'EN', 1, 480.00, 6, '2021-11-05', 'Building full stack web apps using Django and modern frontends.'),
('9789143127747', 'Kotlin for Android', 'EN', 1, 425.00, 7, '2022-06-18', 'Practical Kotlin patterns for Android development.'),
('9789143127748', 'Functional Scala', 'EN', 1, 550.00, 8, '2023-04-12', 'Functional programming techniques in Scala for robust systems.'),
('9789143127749', 'Cloud Native Patterns', 'EN', 1, 580.00, 9, '2024-08-20', 'Patterns for building cloud native applications and microservices.'),

('9789143127750', 'Dataanalys med Python', 'SV', 2, 490.00, 10, '2020-02-25', 'End-to-end analytics workflows using Python tools.'),
('9789143127751', 'Tillämpad analys', 'SV', 2, 520.00, 11, '2021-10-10', 'Case studies and applied techniques for business analytics.'),
('9789143127752', 'Tidsserieanalys', 'SV', 2, 475.00, 12, '2022-05-03', 'Methods and models for time series forecasting and analysis.'),
('9789143127753', 'Visualiseringsmetodik', 'SV', 2, 399.00, 13, '2023-09-01', 'Design principles for clear and effective data visualizations.'),
('9789143127754', 'Analys i stor skala', 'SV', 2, 600.00, 14, '2024-01-15', 'Scaling analytics pipelines for large datasets.'),
('9789143127755', 'Kundanalys', 'SV', 2, 440.00, 15, '2025-03-12', 'Techniques for customer segmentation and lifetime value modeling.'),
('9789143127756', 'Handbok i A/B-testning', 'SV', 2, 360.00, 16, '2021-07-07', 'Practical guide to designing and analyzing experiments.'),
('9789143127757', 'Kausal inferens i praktiken', 'SV', 2, 570.00, 17, '2026-04-20', 'Applied causal methods for real-world decision making.'),

('9789143127758', 'Designing Reliable Databases', 'EN', 3, 650.00, 18, '2020-06-30', 'Principles for designing resilient and maintainable databases.'),
('9789143127759', 'SQL Performance Tuning', 'EN', 3, 595.00, 19, '2021-11-20', 'Advanced techniques for optimizing SQL queries and indexes.'),
('9789143127760', 'NoSQL Patterns', 'EN', 3, 500.00, 20, '2022-08-05', 'Design patterns for NoSQL data models and use cases.'),
('9789143127761', 'Distributed Transactions', 'EN', 3, 680.00, 21, '2023-03-18', 'Managing transactions in distributed systems.'),
('9789143127762', 'Cloud Databases', 'EN', 3, 610.00, 9, '2024-10-02', 'Design and operation of cloud-native database services.'),
('9789143127763', 'Data Modeling Mastery', 'EN', 3, 460.00, 22, '2025-05-27', 'Practical data modeling techniques for OLTP and OLAP.'),
('9789143127764', 'Graph Databases in Practice', 'EN', 3, 540.00, 23, '2026-02-11', 'Using graph databases for relationship-rich data.'),
('9789143127765', 'Backup and Recovery Strategies', 'EN', 3, 400.00, 24, '2020-12-01', 'Operational strategies for backup, restore and disaster recovery.'),

('9789143127766', 'Foundations of Artificial Intelligence', 'EN', 4, 720.00, 25, '2020-04-14', 'Core concepts and foundations of AI systems.'),
('9789143127767', 'AI Ethics and Governance', 'EN', 4, 480.00, 26, '2021-09-09', 'Ethical frameworks and governance for AI deployment.'),
('9789143127768', 'Applied Deep Learning', 'EN', 4, 660.00, 27, '2022-11-02', 'Practical deep learning techniques for production models.'),
('9789143127769', 'Neural Network Engineering', 'EN', 4, 700.00, 28, '2023-06-21', 'Engineering reliable neural network systems.'),
('9789143127770', 'AI för företagsledare', 'SV', 4, 540.00, 29, '2024-05-05', 'How business leaders can adopt and govern AI.'),
('9789143127771', 'Explainable AI', 'EN', 4, 580.00, 30, '2025-08-16', 'Techniques for making AI decisions interpretable.'),
('9789143127772', 'Edge AI Systems', 'EN', 4, 630.00, 31, '2026-03-03', 'Deploying AI models on edge devices.'),
('9789143127773', 'Produktledning för AI', 'SV', 4, 465.00, 32, '2021-02-28', 'Managing AI product lifecycles and teams.'),
('9789143127774', 'Generative Models Practical Guide', 'EN', 4, 690.00, 33, '2024-09-12', 'Practical guide to generative models and applications.'),

('9789143127775', 'Agil projektledning', 'SV', 5, 390.00, 34, '2020-01-20', 'Agile practices for modern project teams.'),
('9789143127776', 'Riskhantering i projekt', 'SV', 5, 440.00, 35, '2021-06-11', 'Identifying and mitigating project risks.'),
('9789143127777', 'Intressenthantering', 'SV', 5, 365.00, 36, '2022-10-07', 'Techniques for effective stakeholder communication.'),
('9789143127778', 'Skalade agila ramverk', 'SV', 5, 520.00, 14, '2023-12-05', 'Applying scaled agile in large organizations.'),
('9789143127779', 'Projektfinansiering', 'SV', 5, 485.00, 37, '2024-07-19', 'Financial planning and control for projects.'),
('9789143127780', 'Hybrid projektleverans', 'SV', 5, 410.00, 38, '2025-11-03', 'Combining predictive and adaptive delivery models.'),
('9789143127781', 'Ledarskap i projekt', 'SV', 5, 450.00, 39, '2026-01-08', 'Leadership skills for project managers.'),
('9789143127782', 'Projektverktyg och automatisering', 'SV', 5, 380.00, 40, '2021-04-18', 'Automation and tooling for project workflows.'),

('9789143127783', 'Machine Learning Foundations', 'EN', 6, 640.00, 41, '2020-08-09', 'Mathematical foundations of machine learning.'),
('9789143127784', 'Practical ML Engineering', 'EN', 6, 590.00, 42, '2021-12-14', 'Engineering practices for ML systems in production.'),
('9789143127785', 'Feature Engineering Handbook', 'EN', 6, 420.00, 43, '2022-02-02', 'Techniques for building strong features for models.'),
('9789143127786', 'Model Deployment Patterns', 'EN', 6, 550.00, 44, '2023-05-25', 'Patterns for deploying and monitoring ML models.'),
('9789143127787', 'Reinforcement Learning Practical', 'EN', 6, 680.00, 45, '2024-11-30', 'Applied reinforcement learning for real problems.'),
('9789143127788', 'AutoML in Practice', 'EN', 6, 500.00, 46, '2025-09-06', 'Using AutoML tools to accelerate model building.'),
('9789143127789', 'Probabilistic Models', 'EN', 6, 600.00, 47, '2026-06-17', 'Probabilistic modeling and Bayesian methods.'),
('9789143127790', 'MLOps Cookbook', 'EN', 6, 460.00, 24, '2022-03-29', 'Recipes for MLOps workflows and automation.'),

('9789143127791', 'Practical Cybersecurity for Developers', 'EN', 7, 525.00, 47, '2021-06-15', 'Security practices developers must apply to build safer applications.'),
('9789143127792', 'Cloud Security Patterns', 'EN', 7, 610.00, 9, '2022-09-01', 'Patterns and anti-patterns for securing cloud deployments.'),
('9789143127793', 'Applied Offensive Security', 'EN', 7, 680.00, 48, '2023-04-20', 'Hands-on offensive techniques for penetration testing and red teaming.'),
('9789143127794', 'Defensive Architecture', 'EN', 7, 595.00, 49, '2024-02-10', 'Designing layered defenses and incident response strategies.'),
('9789143127795', 'Secure DevOps', 'EN', 7, 475.00, 24, '2020-11-11', 'Integrating security into CI/CD and DevOps workflows.'),
('9789143127796', 'Identity and Access Management', 'EN', 7, 520.00, 50, '2021-08-05', 'IAM models, protocols, and practical implementations.'),
('9789143127797', 'Threat Modeling in Practice', 'EN', 7, 460.00, 51, '2022-03-30', 'Practical threat modeling techniques for teams.'),
('9789143127798', 'IoT Security Essentials', 'EN', 7, 540.00, 31, '2023-10-12', 'Securing IoT devices and edge deployments.'),
('9789143127799', 'Cryptography for Engineers', 'EN', 7, 650.00, 52, '2024-07-07', 'Applied cryptography for system designers and engineers.'),
('9789143127800', 'Blue Team Operations', 'EN', 7, 585.00, 53, '2025-05-19', 'Operational playbooks for detection and response.'),

('9789143127801', 'Styrning, risk och regelefterlevnad', 'SV', 8, 499.00, 54, '2020-03-02', 'Foundations of GRC for technology organizations.'),
('9789143127802', 'Datastyrning i praktiken', 'SV', 8, 540.00, 10, '2021-10-21', 'Implementing data governance programs and policies.'),
('9789143127803', 'Utformning av IT-policy', 'SV', 8, 420.00, 55, '2022-06-14', 'How to craft effective IT policies and standards.'),
('9789143127804', 'Regelefterlevnad för teknik', 'SV', 8, 610.00, 56, '2023-01-30', 'Navigating GDPR, ePrivacy, and sector regulations.'),
('9789143127805', 'Säkerhetsstyrning för styrelser', 'SV', 8, 575.00, 57, '2024-09-09', 'Advising boards on cyber risk and governance responsibilities.'),
('9789143127806', 'Integritetsdesign', 'SV', 8, 530.00, 58, '2025-02-17', 'Engineering systems with privacy by design principles.'),
('9789143127807', 'Operativ resiliens', 'SV', 8, 600.00, 59, '2026-04-01', 'Building resilient operations and continuity plans.'),
('9789143127808', 'Styrning av AI-system', 'SV', 8, 645.00, 60, '2024-11-11', 'Policies and oversight for responsible AI deployment.'),
('9789143127809', 'Kvantifiering av cyberrisker', 'SV', 8, 560.00, 35, '2022-12-05', 'Quantitative approaches to measure cyber risk.'),
('9789143127810', 'Styrning av incidenthantering', 'SV', 8, 510.00, 61, '2023-08-22', 'Governance structures for incident response and post-mortems.');

INSERT INTO AuthorsBooks(author_id, ISBN) VALUES
(1, '9789143127741'),
(11, '9789143127742'),
(12, '9789143127742'),
(13, '9789143127743'),
(14, '9789143127744'),
(15, '9789143127745'),
(16, '9789143127746'),
(17, '9789143127747'),
(18, '9789143127748'),
(19, '9789143127749'),

(2, '9789143127750'),
(3, '9789143127751'),
(4, '9789143127752'),
(5, '9789143127753'),
(6, '9789143127754'),
(7, '9789143127755'),
(8, '9789143127756'),
(9, '9789143127757'),

(20, '9789143127758'),
(21, '9789143127759'),
(22, '9789143127760'),
(23, '9789143127761'),
(24, '9789143127762'),
(25, '9789143127763'),
(26, '9789143127764'),
(27, '9789143127765'),

(28, '9789143127766'),
(29, '9789143127767'),
(30, '9789143127768'),
(31, '9789143127769'),
(32, '9789143127770'),
(33, '9789143127771'),
(34, '9789143127772'),
(35, '9789143127773'),
(36, '9789143127774'),

(37, '9789143127775'),
(38, '9789143127776'),
(39, '9789143127777'),
(40, '9789143127778'),
(41, '9789143127779'),
(42, '9789143127780'),
(43, '9789143127781'),
(44, '9789143127782'),

(45, '9789143127783'),
(46, '9789143127784'),
(47, '9789143127785'),
(48, '9789143127786'),
(49, '9789143127787'),
(50, '9789143127788'),
(51, '9789143127789'),
(52, '9789143127790'),

(53, '9789143127791'),
(54, '9789143127792'),
(55, '9789143127793'),
(56, '9789143127794'),
(57, '9789143127795'),
(58, '9789143127796'),
(59, '9789143127797'),
(60, '9789143127798'),
(11, '9789143127799'),
(12, '9789143127800'),

(1, '9789143127801'),
(2, '9789143127802'),
(3, '9789143127803'),
(4, '9789143127804'),
(5, '9789143127805'),
(6, '9789143127806'),
(7, '9789143127807'),
(8, '9789143127808'),
(9, '9789143127809'),
(10, '9789143127810');

/* INVERTORY SEPERATED FOR EACH STORE AND BOOK */

--Central Store Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(1,'9789143127741',18),(1,'9789143127742',16),(1,'9789143127743',20),(1,'9789143127744',14),
(1,'9789143127745',22),(1,'9789143127746',19),(1,'9789143127747',17),(1,'9789143127748',21),
(1,'9789143127749',15),

(1,'9789143127750',20),(1,'9789143127751',18),(1,'9789143127752',17),(1,'9789143127753',16),
(1,'9789143127754',22),(1,'9789143127755',19),(1,'9789143127756',14),(1,'9789143127757',18),

(1,'9789143127758',21),(1,'9789143127759',20),(1,'9789143127760',18),(1,'9789143127761',17),
(1,'9789143127762',23),(1,'9789143127763',19),(1,'9789143127764',16),(1,'9789143127765',15),

(1,'9789143127766',22),(1,'9789143127767',18),(1,'9789143127768',20),(1,'9789143127769',17),
(1,'9789143127770',19),(1,'9789143127771',21),(1,'9789143127772',16),(1,'9789143127773',18),
(1,'9789143127774',17),

(1,'9789143127775',20),(1,'9789143127776',18),(1,'9789143127777',17),(1,'9789143127778',16),
(1,'9789143127779',22),(1,'9789143127780',19),(1,'9789143127781',15),(1,'9789143127782',17),

(1,'9789143127783',21),(1,'9789143127784',20),(1,'9789143127785',18),(1,'9789143127786',17),
(1,'9789143127787',23),(1,'9789143127788',19),(1,'9789143127789',16),(1,'9789143127790',15),

(1,'9789143127791',22),(1,'9789143127792',20),(1,'9789143127793',18),(1,'9789143127794',17),
(1,'9789143127795',21),(1,'9789143127796',19),(1,'9789143127797',16),(1,'9789143127798',15),
(1,'9789143127799',23),(1,'9789143127800',18),

(1,'9789143127801',20),(1,'9789143127802',18),(1,'9789143127803',17),(1,'9789143127804',16),
(1,'9789143127805',22),(1,'9789143127806',19),(1,'9789143127807',15),(1,'9789143127808',17),
(1,'9789143127809',16),(1,'9789143127810',18);

--Store 2 Kungsbacka Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(2,'9789143127741',12),(2,'9789143127742',10),(2,'9789143127743',9),(2,'9789143127744',11),
(2,'9789143127745',14),(2,'9789143127746',13),(2,'9789143127747',8),(2,'9789143127748',12),
(2,'9789143127749',9),

(2,'9789143127750',14),(2,'9789143127751',12),(2,'9789143127752',11),(2,'9789143127753',10),
(2,'9789143127754',15),(2,'9789143127755',13),(2,'9789143127756',8),(2,'9789143127757',11),

(2,'9789143127758',14),(2,'9789143127759',12),(2,'9789143127760',11),(2,'9789143127761',10),
(2,'9789143127762',15),(2,'9789143127763',13),(2,'9789143127764',9),(2,'9789143127765',8),

(2,'9789143127766',14),(2,'9789143127767',12),(2,'9789143127768',11),(2,'9789143127769',10),
(2,'9789143127770',13),(2,'9789143127771',14),(2,'9789143127772',9),(2,'9789143127773',11),
(2,'9789143127774',10),

(2,'9789143127775',13),(2,'9789143127776',12),(2,'9789143127777',11),(2,'9789143127778',10),
(2,'9789143127779',14),(2,'9789143127780',13),(2,'9789143127781',8),(2,'9789143127782',10),

(2,'9789143127783',14),(2,'9789143127784',12),(2,'9789143127785',11),(2,'9789143127786',10),
(2,'9789143127787',15),(2,'9789143127788',13),(2,'9789143127789',9),(2,'9789143127790',8),

(2,'9789143127791',14),(2,'9789143127792',12),(2,'9789143127793',11),(2,'9789143127794',10),
(2,'9789143127795',13),(2,'9789143127796',12),(2,'9789143127797',9),(2,'9789143127798',8),
(2,'9789143127799',15),(2,'9789143127800',12),

(2,'9789143127801',13),(2,'9789143127802',12),(2,'9789143127803',11),(2,'9789143127804',10),
(2,'9789143127805',14),(2,'9789143127806',13),(2,'9789143127807',8),(2,'9789143127808',10),
(2,'9789143127809',9),(2,'9789143127810',12);


--Store 3 Malmö Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(3,'9789143127741',14),(3,'9789143127742',12),(3,'9789143127743',10),(3,'9789143127744',13),
(3,'9789143127745',17),(3,'9789143127746',15),(3,'9789143127747',11),(3,'9789143127748',16),
(3,'9789143127749',12),

(3,'9789143127750',17),(3,'9789143127751',15),(3,'9789143127752',13),(3,'9789143127753',12),
(3,'9789143127754',18),(3,'9789143127755',16),(3,'9789143127756',10),(3,'9789143127757',14),

(3,'9789143127758',17),(3,'9789143127759',15),(3,'9789143127760',13),(3,'9789143127761',12),
(3,'9789143127762',18),(3,'9789143127763',16),(3,'9789143127764',11),(3,'9789143127765',10),

(3,'9789143127766',17),(3,'9789143127767',15),(3,'9789143127768',13),(3,'9789143127769',12),
(3,'9789143127770',16),(3,'9789143127771',17),(3,'9789143127772',11),(3,'9789143127773',14),
(3,'9789143127774',12),

(3,'9789143127775',16),(3,'9789143127776',15),(3,'9789143127777',13),(3,'9789143127778',12),
(3,'9789143127779',17),(3,'9789143127780',15),(3,'9789143127781',10),(3,'9789143127782',12),

(3,'9789143127783',17),(3,'9789143127784',15),(3,'9789143127785',13),(3,'9789143127786',12),
(3,'9789143127787',18),(3,'9789143127788',16),(3,'9789143127789',11),(3,'9789143127790',10),

(3,'9789143127791',17),(3,'9789143127792',15),(3,'9789143127793',13),(3,'9789143127794',12),
(3,'9789143127795',16),(3,'9789143127796',15),(3,'9789143127797',11),(3,'9789143127798',10),
(3,'9789143127799',18),(3,'9789143127800',15),

(3,'9789143127801',16),(3,'9789143127802',15),(3,'9789143127803',13),(3,'9789143127804',12),
(3,'9789143127805',17),(3,'9789143127806',15),(3,'9789143127807',10),(3,'9789143127808',12),
(3,'9789143127809',11),(3,'9789143127810',15);

--Store 4 Stockholm Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(4,'9789143127741',24),(4,'9789143127742',22),(4,'9789143127743',20),(4,'9789143127744',23),
(4,'9789143127745',28),(4,'9789143127746',26),(4,'9789143127747',19),(4,'9789143127748',27),
(4,'9789143127749',21),

(4,'9789143127750',27),(4,'9789143127751',25),(4,'9789143127752',23),(4,'9789143127753',22),
(4,'9789143127754',29),(4,'9789143127755',26),(4,'9789143127756',18),(4,'9789143127757',24),

(4,'9789143127758',28),(4,'9789143127759',26),(4,'9789143127760',23),(4,'9789143127761',22),
(4,'9789143127762',30),(4,'9789143127763',27),(4,'9789143127764',20),(4,'9789143127765',19),

(4,'9789143127766',28),(4,'9789143127767',25),(4,'9789143127768',23),(4,'9789143127769',22),
(4,'9789143127770',26),(4,'9789143127771',28),(4,'9789143127772',20),(4,'9789143127773',24),
(4,'9789143127774',22),

(4,'9789143127775',26),(4,'9789143127776',25),(4,'9789143127777',23),(4,'9789143127778',22),
(4,'9789143127779',28),(4,'9789143127780',26),(4,'9789143127781',18),(4,'9789143127782',22),

(4,'9789143127783',28),(4,'9789143127784',26),(4,'9789143127785',23),(4,'9789143127786',22),
(4,'9789143127787',30),(4,'9789143127788',27),(4,'9789143127789',20),(4,'9789143127790',19),

(4,'9789143127791',28),(4,'9789143127792',26),(4,'9789143127793',23),(4,'9789143127794',22),
(4,'9789143127795',27),(4,'9789143127796',25),(4,'9789143127797',20),(4,'9789143127798',19),
(4,'9789143127799',30),(4,'9789143127800',26),

(4,'9789143127801',26),(4,'9789143127802',25),(4,'9789143127803',23),(4,'9789143127804',22),
(4,'9789143127805',28),(4,'9789143127806',26),(4,'9789143127807',18),(4,'9789143127808',22),
(4,'9789143127809',20),(4,'9789143127810',25);

--Store 5 Lund Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(5,'9789143127741',14),(5,'9789143127742',13),(5,'9789143127743',12),(5,'9789143127744',15),
(5,'9789143127745',18),(5,'9789143127746',17),(5,'9789143127747',11),(5,'9789143127748',16),
(5,'9789143127749',12),

(5,'9789143127750',19),(5,'9789143127751',17),(5,'9789143127752',15),(5,'9789143127753',14),
(5,'9789143127754',20),(5,'9789143127755',18),(5,'9789143127756',11),(5,'9789143127757',15),

(5,'9789143127758',18),(5,'9789143127759',17),(5,'9789143127760',15),(5,'9789143127761',14),
(5,'9789143127762',20),(5,'9789143127763',18),(5,'9789143127764',12),(5,'9789143127765',11),

(5,'9789143127766',18),(5,'9789143127767',17),(5,'9789143127768',15),(5,'9789143127769',14),
(5,'9789143127770',17),(5,'9789143127771',18),(5,'9789143127772',12),(5,'9789143127773',15),
(5,'9789143127774',14),

(5,'9789143127775',17),(5,'9789143127776',17),(5,'9789143127777',15),(5,'9789143127778',14),
(5,'9789143127779',18),(5,'9789143127780',17),(5,'9789143127781',11),(5,'9789143127782',14),

(5,'9789143127783',18),(5,'9789143127784',17),(5,'9789143127785',15),(5,'9789143127786',14),
(5,'9789143127787',20),(5,'9789143127788',18),(5,'9789143127789',12),(5,'9789143127790',11),

(5,'9789143127791',18),(5,'9789143127792',17),(5,'9789143127793',15),(5,'9789143127794',14),
(5,'9789143127795',17),(5,'9789143127796',17),(5,'9789143127797',12),(5,'9789143127798',11),
(5,'9789143127799',20),(5,'9789143127800',17),

(5,'9789143127801',17),(5,'9789143127802',17),(5,'9789143127803',15),(5,'9789143127804',14),
(5,'9789143127805',18),(5,'9789143127806',17),(5,'9789143127807',11),(5,'9789143127808',14),
(5,'9789143127809',12),(5,'9789143127810',17);

--Store 6 Online Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(6,'9789143127741',38),(6,'9789143127742',35),(6,'9789143127743',32),(6,'9789143127744',36),
(6,'9789143127745',45),(6,'9789143127746',42),(6,'9789143127747',28),(6,'9789143127748',44),
(6,'9789143127749',31),

(6,'9789143127750',46),(6,'9789143127751',42),(6,'9789143127752',38),(6,'9789143127753',36),
(6,'9789143127754',49),(6,'9789143127755',44),(6,'9789143127756',29),(6,'9789143127757',40),

(6,'9789143127758',47),(6,'9789143127759',43),(6,'9789143127760',38),(6,'9789143127761',36),
(6,'9789143127762',50),(6,'9789143127763',45),(6,'9789143127764',32),(6,'9789143127765',30),

(6,'9789143127766',47),(6,'9789143127767',43),(6,'9789143127768',38),(6,'9789143127769',36),
(6,'9789143127770',44),(6,'9789143127771',47),(6,'9789143127772',32),(6,'9789143127773',40),
(6,'9789143127774',36),

(6,'9789143127775',44),(6,'9789143127776',43),(6,'9789143127777',38),(6,'9789143127778',36),
(6,'9789143127779',47),(6,'9789143127780',44),(6,'9789143127781',29),(6,'9789143127782',36),

(6,'9789143127783',47),(6,'9789143127784',43),(6,'9789143127785',38),(6,'9789143127786',36),
(6,'9789143127787',50),(6,'9789143127788',45),(6,'9789143127789',32),(6,'9789143127790',30),

(6,'9789143127791',47),(6,'9789143127792',43),(6,'9789143127793',38),(6,'9789143127794',36),
(6,'9789143127795',44),(6,'9789143127796',43),(6,'9789143127797',32),(6,'9789143127798',30),
(6,'9789143127799',50),(6,'9789143127800',43),

(6,'9789143127801',44),(6,'9789143127802',43),(6,'9789143127803',38),(6,'9789143127804',36),
(6,'9789143127805',47),(6,'9789143127806',43),(6,'9789143127807',29),(6,'9789143127808',36),
(6,'9789143127809',32),(6,'9789143127810',43);

--Store 7 Outlet Hede Inventory
INSERT INTO InventoryBalance (store_id, ISBN, Quantity) VALUES
(7,'9789143127741',4),(7,'9789143127742',3),(7,'9789143127743',2),(7,'9789143127744',3),
(7,'9789143127745',5),(7,'9789143127746',4),(7,'9789143127747',2),(7,'9789143127748',4),
(7,'9789143127749',3),

(7,'9789143127750',5),(7,'9789143127751',4),(7,'9789143127752',3),(7,'9789143127753',3),
(7,'9789143127754',6),(7,'9789143127755',5),(7,'9789143127756',2),(7,'9789143127757',4),

(7,'9789143127758',5),(7,'9789143127759',4),(7,'9789143127760',3),(7,'9789143127761',3),
(7,'9789143127762',6),(7,'9789143127763',5),(7,'9789143127764',2),(7,'9789143127765',2),

(7,'9789143127766',5),(7,'9789143127767',4),(7,'9789143127768',3),(7,'9789143127769',3),
(7,'9789143127770',4),(7,'9789143127771',5),(7,'9789143127772',2),(7,'9789143127773',4),
(7,'9789143127774',3),

(7,'9789143127775',4),(7,'9789143127776',4),(7,'9789143127777',3),(7,'9789143127778',3),
(7,'9789143127779',5),(7,'9789143127780',4),(7,'9789143127781',2),(7,'9789143127782',3),

(7,'9789143127783',5),(7,'9789143127784',4),(7,'9789143127785',3),(7,'9789143127786',3),
(7,'9789143127787',6),(7,'9789143127788',5),(7,'9789143127789',2),(7,'9789143127790',2),

(7,'9789143127791',5),(7,'9789143127792',4),(7,'9789143127793',3),(7,'9789143127794',3),
(7,'9789143127795',4),(7,'9789143127796',4),(7,'9789143127797',2),(7,'9789143127798',2),
(7,'9789143127799',6),(7,'9789143127800',4),

(7,'9789143127801',4),(7,'9789143127802',4),(7,'9789143127803',3),(7,'9789143127804',3),
(7,'9789143127805',5),(7,'9789143127806',4),(7,'9789143127807',2),(7,'9789143127808',3),
(7,'9789143127809',3),(7,'9789143127810',4);

/* Create a trigger for automatically updating InventoryBalance after an InventoryTransaction is inserted. */
GO
CREATE TRIGGER trg_UpdateInventoryBalance
ON InventoryTransactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Changes AS (
        SELECT store_id, ISBN, SUM(quantity_change) AS quantity_change
        FROM inserted
        GROUP BY store_id, ISBN
    )
    UPDATE ib
    SET ib.Quantity = ib.Quantity + c.quantity_change
    FROM InventoryBalance ib
    INNER JOIN Changes c
        ON ib.store_id = c.store_id
       AND ib.ISBN = c.ISBN;

    ;WITH Changes AS (
        SELECT store_id, ISBN, SUM(quantity_change) AS quantity_change
        FROM inserted
        GROUP BY store_id, ISBN
    )
    INSERT INTO InventoryBalance (store_id, ISBN, Quantity)
    SELECT 
        c.store_id,
        c.ISBN,
        c.quantity_change
    FROM Changes c
    LEFT JOIN InventoryBalance ib
        ON ib.store_id = c.store_id
       AND ib.ISBN = c.ISBN
    WHERE ib.store_id IS NULL;  -- Missing → create new row with quantity_change as initial quantity
END;
GO


INSERT INTO InventoryTransactions (
    store_id,
    ISBN,
    quantity_change,
    reason,
    order_id,
    shipment_id,
    created_by_user_id,
    created_at
) VALUES
-- 1–20: Sales kopplade till Orders 1–20
(1,'9789143127741',-1,'sale',1,NULL,2,'2026-01-12'),
(4,'9789143127766',-1,'sale',2,NULL,3,'2026-01-15'),
(6,'9789143127791',-2,'sale',3,NULL,1,'2026-01-18'),
(2,'9789143127758',-1,'sale',4,NULL,4,'2026-01-20'),
(3,'9789143127775',-1,'sale',5,NULL,2,'2026-01-22'),
(5,'9789143127768',-1,'sale',6,NULL,3,'2026-01-25'),
(1,'9789143127744',-1,'sale',7,NULL,1,'2026-01-27'),
(4,'9789143127787',-1,'sale',8,NULL,5,'2026-01-29'),
(6,'9789143127801',-1,'sale',9,NULL,2,'2026-02-01'),
(3,'9789143127793',-1,'sale',10,NULL,4,'2026-02-03'),
(2,'9789143127754',-1,'sale',11,NULL,3,'2026-02-05'),
(5,'9789143127779',-1,'sale',12,NULL,1,'2026-02-07'),
(1,'9789143127763',-1,'sale',13,NULL,4,'2026-02-10'),
(4,'9789143127769',-1,'sale',14,NULL,5,'2026-02-12'),
(6,'9789143127799',-1,'sale',15,NULL,2,'2026-02-14'),
(3,'9789143127788',-1,'sale',16,NULL,3,'2026-02-16'),
(2,'9789143127806',-1,'sale',17,NULL,1,'2026-02-18'),
(5,'9789143127807',-1,'sale',18,NULL,4,'2026-02-20'),
(1,'9789143127808',-1,'sale',19,NULL,5,'2026-02-22'),
(4,'9789143127810',-1,'sale',20,NULL,2,'2026-02-25'),

-- 21–120: Extra sales (utan order_id, spridda över 2026)
(1,'9789143127742',-1,'sale',NULL,NULL,2,'2026-01-03'),
(4,'9789143127767',-1,'sale',NULL,NULL,3,'2026-01-04'),
(6,'9789143127783',-1,'sale',NULL,NULL,1,'2026-01-05'),
(3,'9789143127776',-1,'sale',NULL,NULL,4,'2026-01-06'),
(5,'9789143127751',-1,'sale',NULL,NULL,5,'2026-01-07'),
(2,'9789143127750',-1,'sale',NULL,NULL,3,'2026-01-08'),
(7,'9789143127749',-1,'sale',NULL,NULL,2,'2026-01-09'),
(1,'9789143127768',-1,'sale',NULL,NULL,1,'2026-01-10'),
(4,'9789143127771',-1,'sale',NULL,NULL,4,'2026-01-11'),
(6,'9789143127789',-1,'sale',NULL,NULL,5,'2026-01-12'),
(3,'9789143127752',-1,'sale',NULL,NULL,2,'2026-01-13'),
(5,'9789143127753',-1,'sale',NULL,NULL,3,'2026-01-14'),
(2,'9789143127755',-1,'sale',NULL,NULL,4,'2026-01-15'),
(7,'9789143127756',-1,'sale',NULL,NULL,1,'2026-01-16'),
(1,'9789143127757',-1,'sale',NULL,NULL,5,'2026-01-17'),
(4,'9789143127758',-1,'sale',NULL,NULL,2,'2026-01-18'),
(6,'9789143127759',-1,'sale',NULL,NULL,3,'2026-01-19'),
(3,'9789143127760',-1,'sale',NULL,NULL,4,'2026-01-20'),
(5,'9789143127761',-1,'sale',NULL,NULL,1,'2026-01-21'),
(2,'9789143127762',-1,'sale',NULL,NULL,5,'2026-01-22'),
(7,'9789143127763',-1,'sale',NULL,NULL,2,'2026-01-23'),
(1,'9789143127764',-1,'sale',NULL,NULL,3,'2026-01-24'),
(4,'9789143127765',-1,'sale',NULL,NULL,4,'2026-01-25'),
(6,'9789143127766',-1,'sale',NULL,NULL,1,'2026-01-26'),
(3,'9789143127767',-1,'sale',NULL,NULL,5,'2026-01-27'),
(5,'9789143127768',-1,'sale',NULL,NULL,2,'2026-01-28'),
(2,'9789143127769',-1,'sale',NULL,NULL,3,'2026-01-29'),
(7,'9789143127770',-1,'sale',NULL,NULL,4,'2026-01-30'),
(1,'9789143127771',-1,'sale',NULL,NULL,1,'2026-01-31'),
(4,'9789143127772',-1,'sale',NULL,NULL,2,'2026-02-01'),
(6,'9789143127773',-1,'sale',NULL,NULL,3,'2026-02-02'),
(3,'9789143127774',-1,'sale',NULL,NULL,4,'2026-02-03'),
(5,'9789143127775',-1,'sale',NULL,NULL,5,'2026-02-04'),
(2,'9789143127776',-1,'sale',NULL,NULL,1,'2026-02-05'),
(7,'9789143127777',-1,'sale',NULL,NULL,2,'2026-02-06'),
(1,'9789143127778',-1,'sale',NULL,NULL,3,'2026-02-07'),
(4,'9789143127779',-1,'sale',NULL,NULL,4,'2026-02-08'),
(6,'9789143127780',-1,'sale',NULL,NULL,5,'2026-02-09'),
(3,'9789143127781',-1,'sale',NULL,NULL,1,'2026-02-10'),
(5,'9789143127782',-1,'sale',NULL,NULL,2,'2026-02-11'),
(2,'9789143127783',-1,'sale',NULL,NULL,3,'2026-02-12'),
(7,'9789143127784',-1,'sale',NULL,NULL,4,'2026-02-13'),
(1,'9789143127785',-1,'sale',NULL,NULL,5,'2026-02-14'),
(4,'9789143127786',-1,'sale',NULL,NULL,1,'2026-02-15'),
(6,'9789143127787',-1,'sale',NULL,NULL,2,'2026-02-16'),
(3,'9789143127788',-1,'sale',NULL,NULL,3,'2026-02-17'),
(5,'9789143127789',-1,'sale',NULL,NULL,4,'2026-02-18'),
(2,'9789143127790',-1,'sale',NULL,NULL,5,'2026-02-19'),
(7,'9789143127791',-1,'sale',NULL,NULL,1,'2026-02-20'),
(1,'9789143127792',-1,'sale',NULL,NULL,2,'2026-02-21'),
(4,'9789143127793',-1,'sale',NULL,NULL,3,'2026-02-22'),
(6,'9789143127794',-1,'sale',NULL,NULL,4,'2026-02-23'),
(3,'9789143127795',-1,'sale',NULL,NULL,5,'2026-02-24'),
(5,'9789143127796',-1,'sale',NULL,NULL,1,'2026-02-25'),
(2,'9789143127797',-1,'sale',NULL,NULL,2,'2026-02-26'),
(7,'9789143127798',-1,'sale',NULL,NULL,3,'2026-02-27'),
(1,'9789143127799',-1,'sale',NULL,NULL,4,'2026-02-28'),
(4,'9789143127800',-1,'sale',NULL,NULL,5,'2026-03-01'),
(6,'9789143127801',-1,'sale',NULL,NULL,1,'2026-03-02'),
(3,'9789143127802',-1,'sale',NULL,NULL,2,'2026-03-03'),
(5,'9789143127803',-1,'sale',NULL,NULL,3,'2026-03-04'),
(2,'9789143127804',-1,'sale',NULL,NULL,4,'2026-03-05'),
(7,'9789143127805',-1,'sale',NULL,NULL,5,'2026-03-06'),
(1,'9789143127806',-1,'sale',NULL,NULL,1,'2026-03-07'),
(4,'9789143127807',-1,'sale',NULL,NULL,2,'2026-03-08'),
(6,'9789143127808',-1,'sale',NULL,NULL,3,'2026-03-09'),
(3,'9789143127809',-1,'sale',NULL,NULL,4,'2026-03-10'),
(5,'9789143127810',-1,'sale',NULL,NULL,5,'2026-03-11'),
(2,'9789143127741',-1,'sale',NULL,NULL,1,'2026-03-12'),
(7,'9789143127742',-1,'sale',NULL,NULL,2,'2026-03-13'),
(1,'9789143127743',-1,'sale',NULL,NULL,3,'2026-03-14'),
(4,'9789143127744',-1,'sale',NULL,NULL,4,'2026-03-15'),
(6,'9789143127745',-1,'sale',NULL,NULL,5,'2026-03-16'),
(3,'9789143127746',-1,'sale',NULL,NULL,1,'2026-03-17'),
(5,'9789143127747',-1,'sale',NULL,NULL,2,'2026-03-18'),
(2,'9789143127748',-1,'sale',NULL,NULL,3,'2026-03-19'),
(7,'9789143127749',-1,'sale',NULL,NULL,4,'2026-03-20'),
(1,'9789143127750',-1,'sale',NULL,NULL,5,'2026-03-21'),
(4,'9789143127751',-1,'sale',NULL,NULL,1,'2026-03-22'),
(6,'9789143127752',-1,'sale',NULL,NULL,2,'2026-03-23'),
(3,'9789143127753',-1,'sale',NULL,NULL,3,'2026-03-24'),
(5,'9789143127754',-1,'sale',NULL,NULL,4,'2026-03-25'),
(2,'9789143127755',-1,'sale',NULL,NULL,5,'2026-03-26'),
(7,'9789143127756',-1,'sale',NULL,NULL,1,'2026-03-27'),
(1,'9789143127757',-1,'sale',NULL,NULL,2,'2026-03-28'),
(4,'9789143127758',-1,'sale',NULL,NULL,3,'2026-03-29'),
(6,'9789143127759',-1,'sale',NULL,NULL,4,'2026-03-30'),
(3,'9789143127760',-1,'sale',NULL,NULL,5,'2026-03-31'),
(5,'9789143127761',-1,'sale',NULL,NULL,1,'2026-04-01'),
(2,'9789143127762',-1,'sale',NULL,NULL,2,'2026-04-02'),
(7,'9789143127763',-1,'sale',NULL,NULL,3,'2026-04-03'),
(1,'9789143127764',-1,'sale',NULL,NULL,4,'2026-04-04'),
(4,'9789143127765',-1,'sale',NULL,NULL,5,'2026-04-05'),
(6,'9789143127766',-1,'sale',NULL,NULL,1,'2026-04-06'),
(3,'9789143127767',-1,'sale',NULL,NULL,2,'2026-04-07'),
(5,'9789143127768',-1,'sale',NULL,NULL,3,'2026-04-08'),
(2,'9789143127769',-1,'sale',NULL,NULL,4,'2026-04-09'),
(7,'9789143127770',-1,'sale',NULL,NULL,5,'2026-04-10'),

-- 121–160: Shipment_in (40 st, positiva)
(1,'9789143127741',10,'shipment_in',NULL,1,1,'2026-01-05'),
(4,'9789143127766',12,'shipment_in',NULL,2,2,'2026-01-06'),
(6,'9789143127791',20,'shipment_in',NULL,3,3,'2026-01-07'),
(3,'9789143127775',8,'shipment_in',NULL,4,4,'2026-01-08'),
(5,'9789143127750',6,'shipment_in',NULL,5,5,'2026-01-09'),
(2,'9789143127758',7,'shipment_in',NULL,6,1,'2026-01-10'),
(7,'9789143127783',5,'shipment_in',NULL,7,2,'2026-01-11'),
(1,'9789143127742',9,'shipment_in',NULL,8,3,'2026-01-12'),
(4,'9789143127767',11,'shipment_in',NULL,9,4,'2026-01-13'),
(6,'9789143127784',15,'shipment_in',NULL,10,5,'2026-01-14'),
(3,'9789143127776',8,'shipment_in',NULL,11,1,'2026-01-15'),
(5,'9789143127751',7,'shipment_in',NULL,12,2,'2026-01-16'),
(2,'9789143127752',6,'shipment_in',NULL,13,3,'2026-01-17'),
(7,'9789143127753',5,'shipment_in',NULL,14,4,'2026-01-18'),
(1,'9789143127754',9,'shipment_in',NULL,15,5,'2026-01-19'),
(4,'9789143127755',10,'shipment_in',NULL,16,1,'2026-01-20'),
(6,'9789143127756',12,'shipment_in',NULL,17,2,'2026-01-21'),
(3,'9789143127757',8,'shipment_in',NULL,18,3,'2026-01-22'),
(5,'9789143127758',7,'shipment_in',NULL,19,4,'2026-01-23'),
(2,'9789143127759',6,'shipment_in',NULL,20,5,'2026-01-24'),
(7,'9789143127760',5,'shipment_in',NULL,21,1,'2026-01-25'),
(1,'9789143127761',9,'shipment_in',NULL,22,2,'2026-01-26'),
(4,'9789143127762',11,'shipment_in',NULL,23,3,'2026-01-27'),
(6,'9789143127763',13,'shipment_in',NULL,24,4,'2026-01-28'),
(3,'9789143127764',8,'shipment_in',NULL,25,5,'2026-01-29'),
(5,'9789143127765',7,'shipment_in',NULL,26,1,'2026-01-30'),
(2,'9789143127766',6,'shipment_in',NULL,27,2,'2026-01-31'),
(7,'9789143127767',5,'shipment_in',NULL,28,3,'2026-02-01'),
(1,'9789143127768',9,'shipment_in',NULL,29,4,'2026-02-02'),
(4,'9789143127769',10,'shipment_in',NULL,30,5,'2026-02-03'),
(6,'9789143127770',12,'shipment_in',NULL,31,1,'2026-02-04'),
(3,'9789143127771',8,'shipment_in',NULL,32,2,'2026-02-05'),
(5,'9789143127772',7,'shipment_in',NULL,33,3,'2026-02-06'),
(2,'9789143127773',6,'shipment_in',NULL,34,4,'2026-02-07'),
(7,'9789143127774',5,'shipment_in',NULL,35,5,'2026-02-08'),
(1,'9789143127775',9,'shipment_in',NULL,36,1,'2026-02-09'),
(4,'9789143127776',10,'shipment_in',NULL,37,2,'2026-02-10'),
(6,'9789143127777',12,'shipment_in',NULL,38,3,'2026-02-11'),
(3,'9789143127778',8,'shipment_in',NULL,39,4,'2026-02-12'),
(7,'9789143127809',5,'shipment_in',NULL,40,2,'2026-02-13'),

-- 161–180: Shipment_out (20 st, negativa)
(1,'9789143127741',-5,'shipment_out',NULL,41,3,'2026-02-15'),
(4,'9789143127766',-6,'shipment_out',NULL,42,4,'2026-02-16'),
(6,'9789143127791',-8,'shipment_out',NULL,43,2,'2026-02-17'),
(3,'9789143127775',-4,'shipment_out',NULL,44,1,'2026-02-18'),
(5,'9789143127750',-3,'shipment_out',NULL,45,5,'2026-02-19'),
(2,'9789143127758',-4,'shipment_out',NULL,46,3,'2026-02-20'),
(7,'9789143127783',-2,'shipment_out',NULL,47,4,'2026-02-21'),
(1,'9789143127742',-3,'shipment_out',NULL,48,1,'2026-02-22'),
(4,'9789143127767',-4,'shipment_out',NULL,49,2,'2026-02-23'),
(6,'9789143127784',-5,'shipment_out',NULL,50,3,'2026-02-24'),
(3,'9789143127776',-3,'shipment_out',NULL,51,4,'2026-02-25'),
(5,'9789143127751',-2,'shipment_out',NULL,52,5,'2026-02-26'),
(2,'9789143127752',-3,'shipment_out',NULL,53,1,'2026-02-27'),
(7,'9789143127753',-2,'shipment_out',NULL,54,2,'2026-02-28'),
(1,'9789143127754',-3,'shipment_out',NULL,55,3,'2026-03-01'),
(4,'9789143127755',-4,'shipment_out',NULL,56,4,'2026-03-02'),
(6,'9789143127756',-5,'shipment_out',NULL,57,5,'2026-03-03'),
(3,'9789143127757',-3,'shipment_out',NULL,58,1,'2026-03-04'),
(5,'9789143127758',-2,'shipment_out',NULL,59,2,'2026-03-05'),
(7,'9789143127809',-3,'shipment_out',NULL,60,1,'2026-03-06'),

-- 181–190: Returns (10 st, positiva, kopplade till orders)
(1,'9789143127741',1,'return',1,NULL,2,'2026-01-13'),
(4,'9789143127766',1,'return',2,NULL,3,'2026-01-16'),
(6,'9789143127791',1,'return',3,NULL,1,'2026-01-19'),
(2,'9789143127758',1,'return',4,NULL,4,'2026-01-21'),
(3,'9789143127775',1,'return',5,NULL,2,'2026-01-23'),
(5,'9789143127768',1,'return',6,NULL,3,'2026-01-26'),
(1,'9789143127744',1,'return',7,NULL,1,'2026-01-28'),
(4,'9789143127787',1,'return',8,NULL,5,'2026-01-30'),
(6,'9789143127801',1,'return',9,NULL,2,'2026-02-02'),
(3,'9789143127793',1,'return',10,NULL,4,'2026-02-04'),

-- 191–200: Adjustments (10 st, blandat +/‑)
(1,'9789143127741',-1,'adjustment',NULL,NULL,1,'2026-01-02'),
(4,'9789143127766',2,'adjustment',NULL,NULL,3,'2026-01-09'),
(6,'9789143127791',-2,'adjustment',NULL,NULL,2,'2026-01-18'),
(3,'9789143127775',1,'adjustment',NULL,NULL,4,'2026-01-24'),
(5,'9789143127750',-1,'adjustment',NULL,NULL,5,'2026-02-01'),
(2,'9789143127758',1,'adjustment',NULL,NULL,1,'2026-02-08'),
(7,'9789143127783',-1,'adjustment',NULL,NULL,2,'2026-02-15'),
(1,'9789143127763',2,'adjustment',NULL,NULL,3,'2026-02-22'),
(4,'9789143127779',-2,'adjustment',NULL,NULL,4,'2026-03-01'),
(6,'9789143127801',1,'adjustment',NULL,NULL,5,'2026-03-08');

SET IDENTITY_INSERT OrderDetails ON;
INSERT INTO OrderDetails (order_detail_id, order_id, ISBN, Quantity, UnitPrice)
VALUES
(1, 1, '9789143127741', 1, 499),
(2, 2, '9789143127766', 1, 720),
(3, 3, '9789143127791', 2, 525),
(4, 4, '9789143127758', 1, 650),
(5, 5, '9789143127775', 1, 390),
(6, 6, '9789143127768', 1, 660),
(7, 7, '9789143127744', 1, 620),
(8, 8, '9789143127787', 1, 680),
(9, 9, '9789143127801', 1, 499),
(10, 10, '9789143127793', 1, 680),
(11, 11, '9789143127754', 1, 600),
(12, 12, '9789143127779', 1, 485),
(13, 13, '9789143127763', 1, 460),
(14, 14, '9789143127769', 1, 700),
(15, 15, '9789143127799', 1, 650),
(16, 16, '9789143127788', 1, 500),
(17, 17, '9789143127806', 1, 430),
(18, 18, '9789143127807', 1, 510),
(19, 19, '9789143127808', 1, 645),
(20, 20, '9789143127810', 1, 510);
SET IDENTITY_INSERT OrderDetails OFF;

/* =========================================================
   ADDITIONAL FEATURES: VIEWS AND MOVEBOOK PROCEDURE
   ========================================================= */
GO

CREATE VIEW dbo.TitlesPerAuthor AS
SELECT
    a.author_id,
    a.FirstName + ' ' + a.LastName AS Author,
    DATEDIFF(YEAR, a.birthdate, GETDATE())
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, a.birthdate, GETDATE()), a.birthdate) > GETDATE()
            THEN 1 ELSE 0
          END AS Age,
    COUNT(DISTINCT b.ISBN) AS Titles,
    COALESCE(SUM(b.price * COALESCE(ib.Quantity, 0)), 0) AS [Inventory Value]
FROM dbo.Authors AS a
LEFT JOIN dbo.AuthorsBooks AS ab ON ab.author_id = a.author_id
LEFT JOIN dbo.Books AS b ON b.ISBN = ab.ISBN
LEFT JOIN dbo.InventoryBalance AS ib ON ib.ISBN = b.ISBN
GROUP BY a.author_id, a.FirstName, a.LastName, a.birthdate;
GO

CREATE VIEW dbo.MostSoldBooks AS
SELECT
    b.ISBN,
    b.title AS Title,
    COALESCE(
        (
            SELECT STRING_AGG(a2.FirstName + ' ' + a2.LastName, ', ')
            FROM dbo.AuthorsBooks AS ab2
            INNER JOIN dbo.Authors AS a2 ON a2.author_id = ab2.author_id
            WHERE ab2.ISBN = b.ISBN
        ),
        'Unknown'
    ) AS Author,
    c.CategoryName AS Category,
    COALESCE(SUM(CASE WHEN t.reason = 'sale' THEN ABS(t.quantity_change) ELSE 0 END), 0) AS [Total sold Books],
    COALESCE(SUM(CASE WHEN t.reason = 'sale' THEN ABS(t.quantity_change) * b.price ELSE 0 END), 0) AS [Total Revenue]
FROM dbo.Books AS b
LEFT JOIN dbo.Categories AS c ON c.categoryID = b.categoryID
LEFT JOIN dbo.InventoryTransactions AS t ON t.ISBN = b.ISBN
GROUP BY b.ISBN, b.title, c.CategoryName;
GO

CREATE PROCEDURE dbo.MoveBook
    @ISBN CHAR(13),
    @FromStoreId INT,
    @ToStoreId INT,
    @Quantity INT,
    @CreatedByUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0
        THROW 51000, 'Quantity must be greater than zero.', 1;

    IF @FromStoreId = @ToStoreId
        THROW 51001, 'Source and destination stores must be different.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE store_id = @FromStoreId)
        THROW 51002, 'Source store does not exist.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE store_id = @ToStoreId)
        THROW 51003, 'Destination store does not exist.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Books WHERE ISBN = @ISBN)
        THROW 51004, 'Book does not exist.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_id = @CreatedByUserId)
        THROW 51005, 'User does not exist.', 1;

    BEGIN TRANSACTION;

    DECLARE @AvailableQuantity INT;
    SELECT @AvailableQuantity = COALESCE(Quantity, 0)
    FROM dbo.InventoryBalance WITH (UPDLOCK, HOLDLOCK)
    WHERE store_id = @FromStoreId AND ISBN = @ISBN;

    IF @AvailableQuantity IS NULL OR @AvailableQuantity < @Quantity
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 51006, 'The exact requested quantity is not available at the source store.', 1;
    END;

    INSERT INTO dbo.InventoryTransactions
        (store_id, ISBN, quantity_change, reason, created_by_user_id)
    VALUES
        (@FromStoreId, @ISBN, -@Quantity, 'movebook_out', @CreatedByUserId),
        (@ToStoreId, @ISBN, @Quantity, 'movebook_in', @CreatedByUserId);

    COMMIT TRANSACTION;
END;
GO

CREATE VIEW dbo.InventoryByStore AS
SELECT
    s.store_id,
    s.store_name,
    COUNT(DISTINCT CASE WHEN COALESCE(ib.Quantity, 0) > 0 THEN ib.ISBN END) AS BookTitles,
    COALESCE(SUM(COALESCE(ib.Quantity, 0)), 0) AS TotalCopies,
    COALESCE(SUM(COALESCE(ib.Quantity, 0) * COALESCE(b.price, 0)), 0) AS InventoryValue
FROM dbo.Stores AS s
LEFT JOIN dbo.InventoryBalance AS ib ON ib.store_id = s.store_id
LEFT JOIN dbo.Books AS b ON b.ISBN = ib.ISBN
GROUP BY s.store_id, s.store_name;
GO

CREATE VIEW dbo.DailySalesStatistics AS
SELECT
    CAST(t.created_at AS DATE) AS SalesDate,
    SUM(ABS(t.quantity_change)) AS SoldCopies,
    SUM(ABS(t.quantity_change) * b.price) AS SalesValue
FROM dbo.InventoryTransactions AS t
INNER JOIN dbo.Books AS b ON b.ISBN = t.ISBN
WHERE t.reason = 'sale'
GROUP BY CAST(t.created_at AS DATE);
GO

/* =========================================================
   ADDITIONAL TEST DATA: 25 CUSTOMERS
   ========================================================= */
INSERT INTO dbo.Customers
    (first_name, last_name, email, phone, adress)
VALUES
    ('Emma', 'Andersson', 'emma.andersson@example.com', '070-100 00 01', 'Kungsbacka 1'),
    ('Liam', 'Berg', 'liam.berg@example.com', '070-100 00 02', 'Goteborg 2'),
    ('Nora', 'Carlsson', 'nora.carlsson@example.com', '070-100 00 03', 'Molndal 3'),
    ('William', 'Dahl', 'william.dahl@example.com', '070-100 00 04', 'Kungsbacka 4'),
    ('Alice', 'Eklund', 'alice.eklund@example.com', '070-100 00 05', 'Varberg 5'),
    ('Hugo', 'Forsberg', 'hugo.forsberg@example.com', '070-100 00 06', 'Falkenberg 6'),
    ('Elsa', 'Gustafsson', 'elsa.gustafsson@example.com', '070-100 00 07', 'Halmstad 7'),
    ('Noah', 'Holm', 'noah.holm@example.com', '070-100 00 08', 'Goteborg 8'),
    ('Maja', 'Isaksson', 'maja.isaksson@example.com', '070-100 00 09', 'Kungsbacka 9'),
    ('Lucas', 'Johansson', 'lucas.johansson@example.com', '070-100 00 10', 'Partille 10'),
    ('Freja', 'Karlsson', 'freja.karlsson@example.com', '070-100 00 11', 'Molndal 11'),
    ('Oscar', 'Lindberg', 'oscar.lindberg@example.com', '070-100 00 12', 'Lerum 12'),
    ('Alva', 'Magnusson', 'alva.magnusson@example.com', '070-100 00 13', 'Kungsbacka 13'),
    ('Elias', 'Nilsson', 'elias.nilsson@example.com', '070-100 00 14', 'Goteborg 14'),
    ('Saga', 'Olsson', 'saga.olsson@example.com', '070-100 00 15', 'Varberg 15'),
    ('Leo', 'Pettersson', 'leo.pettersson@example.com', '070-100 00 16', 'Falkenberg 16'),
    ('Selma', 'Rosenberg', 'selma.rosenberg@example.com', '070-100 00 17', 'Halmstad 17'),
    ('Elliot', 'Sjoberg', 'elliot.sjoberg@example.com', '070-100 00 18', 'Goteborg 18'),
    ('Astrid', 'Thomasson', 'astrid.thomasson@example.com', '070-100 00 19', 'Kungsbacka 19'),
    ('Viggo', 'Ullman', 'viggo.ullman@example.com', '070-100 00 20', 'Lerum 20'),
    ('Ella', 'Viklund', 'ella.viklund@example.com', '070-100 00 21', 'Molndal 21'),
    ('Arvid', 'Wester', 'arvid.wester@example.com', '070-100 00 22', 'Partille 22'),
    ('Sigrid', 'Akesson', 'sigrid.akesson@example.com', '070-100 00 23', 'Kungsbacka 23'),
    ('Gustav', 'Oberg', 'gustav.oberg@example.com', '070-100 00 24', 'Goteborg 24'),
    ('Ida', 'Lundqvist', 'ida.lundqvist@example.com', '070-100 00 25', 'Varberg 25');
GO

/* =========================================================
   ADDITIONAL TEST DATA: MAY 2026 SALES
   ========================================================= */
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

IF EXISTS (
    SELECT 1
    FROM dbo.InventoryTransactions
    WHERE reason = 'sale'
      AND created_at >= '2026-05-12'
      AND created_at < '2026-05-15'
)
    THROW 52000, 'May 2026 demo sales already exist. The seed section was not run.', 1;

DECLARE @SalesUserId INT;
SELECT TOP (1) @SalesUserId = user_id
FROM dbo.Users
ORDER BY user_id;

IF @SalesUserId IS NULL
    THROW 52001, 'No application user exists to record the demo sales.', 1;

DECLARE @SoldOutStoreId INT = 7;
DECLARE @SoldOutISBN CHAR(13) = '9789143127810';
DECLARE @SoldOutQuantity INT;

SELECT @SoldOutQuantity = Quantity
FROM dbo.InventoryBalance WITH (UPDLOCK, HOLDLOCK)
WHERE store_id = @SoldOutStoreId
  AND ISBN = @SoldOutISBN;

IF @SoldOutQuantity IS NULL
    THROW 52002, 'The selected sold-out store/book inventory row does not exist.', 1;

IF @SoldOutQuantity <= 0
    THROW 52003, 'The selected sold-out book already has zero stock.', 1;

DECLARE @SalesPlan TABLE (
    store_id INT NOT NULL,
    ISBN CHAR(13) NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL
);

INSERT INTO @SalesPlan (store_id, ISBN, sale_date, quantity)
VALUES
    (1, '9789143127741', '2026-05-12', 1),
    (2, '9789143127742', '2026-05-12', 1),
    (3, '9789143127743', '2026-05-12', 1),
    (4, '9789143127744', '2026-05-12', 1),
    (5, '9789143127745', '2026-05-12', 1),
    (6, '9789143127746', '2026-05-12', 1),
    (7, '9789143127747', '2026-05-12', 1),
    (1, '9789143127750', '2026-05-13', 1),
    (2, '9789143127751', '2026-05-13', 1),
    (3, '9789143127752', '2026-05-13', 1),
    (4, '9789143127753', '2026-05-13', 1),
    (5, '9789143127754', '2026-05-13', 1),
    (6, '9789143127755', '2026-05-13', 1),
    (7, '9789143127757', '2026-05-13', 1),
    (1, '9789143127760', '2026-05-14', 1),
    (2, '9789143127761', '2026-05-14', 1),
    (3, '9789143127762', '2026-05-14', 1),
    (4, '9789143127763', '2026-05-14', 1),
    (5, '9789143127764', '2026-05-14', 1),
    (6, '9789143127765', '2026-05-14', 1),
    (7, '9789143127766', '2026-05-14', 1),
    (7, @SoldOutISBN, '2026-05-14', @SoldOutQuantity);

IF EXISTS (
    SELECT 1
    FROM @SalesPlan AS p
    LEFT JOIN dbo.InventoryBalance AS ib WITH (UPDLOCK, HOLDLOCK)
      ON ib.store_id = p.store_id
     AND ib.ISBN = p.ISBN
    WHERE ib.Quantity IS NULL OR ib.Quantity < p.quantity
)
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52004, 'One or more demo sales exceed the available inventory.', 1;
END;

IF EXISTS (
    SELECT 1
    FROM @SalesPlan AS p
    LEFT JOIN dbo.Books AS b ON b.ISBN = p.ISBN
    LEFT JOIN dbo.Stores AS s ON s.store_id = p.store_id
    WHERE b.ISBN IS NULL OR s.store_id IS NULL
)
BEGIN
    ROLLBACK TRANSACTION;
    THROW 52005, 'A planned demo sale refers to a missing book or store.', 1;
END;

INSERT INTO dbo.InventoryTransactions
    (store_id, ISBN, quantity_change, reason, created_by_user_id, created_at)
SELECT
    store_id,
    ISBN,
    -quantity,
    'sale',
    @SalesUserId,
    CAST(sale_date AS DATETIME2)
FROM @SalesPlan;

COMMIT TRANSACTION;
GO

SELECT
    s.store_id,
    s.store_name,
    b.ISBN,
    b.title,
    ib.Quantity AS remaining_quantity,
    'SOLD OUT' AS status
FROM dbo.InventoryBalance AS ib
INNER JOIN dbo.Stores AS s ON s.store_id = ib.store_id
INNER JOIN dbo.Books AS b ON b.ISBN = ib.ISBN
WHERE ib.store_id = 7
  AND ib.ISBN = '9789143127810';
GO

/* =========================================================
   APPLICATION PERMISSIONS
   ========================================================= */
IF SUSER_ID(N'admin') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.database_principals
       WHERE name = N'admin'
   )
BEGIN
    CREATE USER [admin] FOR LOGIN [admin];
END;
GO

IF DATABASE_PRINCIPAL_ID(N'admin') IS NOT NULL
BEGIN
    GRANT SELECT, INSERT, UPDATE ON dbo.Roles TO [admin];
    GRANT SELECT, INSERT, UPDATE ON dbo.Users TO [admin];
    GRANT SELECT, INSERT, UPDATE ON dbo.Employees TO [admin];
    GRANT SELECT, INSERT, UPDATE ON dbo.UserStoreAccess TO [admin];
    GRANT SELECT, UPDATE ON dbo.Customers TO [admin];
    GRANT SELECT ON dbo.Books TO [admin];
    GRANT SELECT ON dbo.Authors TO [admin];
    GRANT SELECT ON dbo.AuthorsBooks TO [admin];
    GRANT SELECT ON dbo.Stores TO [admin];
    GRANT SELECT ON dbo.InventoryBalance TO [admin];
    GRANT SELECT ON dbo.InventoryTransactions TO [admin];
    GRANT SELECT ON dbo.TitlesPerAuthor TO [admin];
    GRANT SELECT ON dbo.MostSoldBooks TO [admin];
    GRANT SELECT ON dbo.InventoryByStore TO [admin];
    GRANT SELECT ON dbo.DailySalesStatistics TO [admin];
    GRANT EXECUTE ON dbo.MoveBook TO [admin];
END;
GO
