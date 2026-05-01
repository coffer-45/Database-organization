DROP VIEW IF EXISTS BuyInProfit;
DROP VIEW IF EXISTS RentTotal;
DROP VIEW IF EXISTS OrderTotal;

DROP TABLE IF EXISTS SetUpService CASCADE;
DROP TABLE IF EXISTS RepairService CASCADE;
DROP TABLE IF EXISTS InstrumentBuyIn CASCADE;
DROP TABLE IF EXISTS StudioBooking CASCADE;
DROP TABLE IF EXISTS Rent CASCADE;
DROP TABLE IF EXISTS OrderItem CASCADE;
DROP TABLE IF EXISTS CustomerOrder CASCADE;
DROP TABLE IF EXISTS Product CASCADE;
DROP TABLE IF EXISTS Brand CASCADE;
DROP TABLE IF EXISTS Category CASCADE;
DROP TABLE IF EXISTS Customer CASCADE;

DROP TYPE IF EXISTS setup_type CASCADE;
DROP TYPE IF EXISTS setup_status CASCADE;
DROP TYPE IF EXISTS repair_status CASCADE;
DROP TYPE IF EXISTS buyin_status CASCADE;
DROP TYPE IF EXISTS instrument_condition CASCADE;
DROP TYPE IF EXISTS studio_booking_status CASCADE;
DROP TYPE IF EXISTS rent_status CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;

CREATE TYPE order_status AS ENUM ('New', 'Paid', 'Shipped', 'Delivered', 'Cancelled');
CREATE TYPE rent_status AS ENUM ('Active', 'Returned', 'Cancelled');
CREATE TYPE studio_booking_status AS ENUM ('Booked', 'Completed', 'Cancelled');
CREATE TYPE instrument_condition AS ENUM ('LikeNew', 'Excellent', 'Good', 'Fair', 'NeedsRepair');
CREATE TYPE buyin_status AS ENUM ('Accepted', 'Rejected', 'PreparedForSale', 'Sold');
CREATE TYPE repair_status AS ENUM ('Accepted', 'InProgress', 'WaitingForParts', 'Completed', 'Cancelled', 'IssuedToCustomer');
CREATE TYPE setup_status AS ENUM ('Accepted', 'InProgress', 'Completed', 'Cancelled', 'IssuedToCustomer');
CREATE TYPE setup_type AS ENUM ('Basic', 'Full', 'StringsReplacement', 'IntonationAdjustment', 'NeckAdjustment');

CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    PasswordHash VARCHAR(255) NOT NULL
);

CREATE TABLE Category (
    CategoryID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT
);

CREATE TABLE Brand (
    BrandID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Product (
    ProductID SERIAL PRIMARY KEY,
    CategoryID INT NOT NULL,
    BrandID INT NOT NULL,
    Model VARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    StockQuantity INT NOT NULL CHECK (StockQuantity >= 0),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID) ON DELETE RESTRICT,
    FOREIGN KEY (BrandID) REFERENCES Brand(BrandID) ON DELETE RESTRICT
);

CREATE TABLE CustomerOrder (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status order_status NOT NULL DEFAULT 'New',
    ShippingAddress VARCHAR(255) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE
);

CREATE TABLE OrderItem (
    OrderItemID SERIAL PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10, 2) NOT NULL CHECK (UnitPrice > 0),
    FOREIGN KEY (OrderID) REFERENCES CustomerOrder(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT,
    UNIQUE (OrderID, ProductID)
);

CREATE TABLE Rent (
    RentID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    PickUpDate TIMESTAMP NOT NULL,
    Duration INT NOT NULL CHECK (Duration > 0),
    ReturnDate TIMESTAMP NOT NULL,
    Status rent_status NOT NULL,
    PercentageFromPrice DECIMAL(5, 2) NOT NULL CHECK (PercentageFromPrice > 0),
    DepositAmount DECIMAL(10, 2) NOT NULL CHECK (DepositAmount >= 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT,
    CHECK (ReturnDate >= PickUpDate)
);

CREATE TABLE StudioBooking (
    StudioID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    RecordDate TIMESTAMP NOT NULL,
    Status studio_booking_status NOT NULL,
    Duration INT NOT NULL CHECK (Duration > 0),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE
);

CREATE TABLE InstrumentBuyIn (
    BuyInID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL UNIQUE,
    Condition instrument_condition NOT NULL,
    Status buyin_status NOT NULL,
    BuyInPrice DECIMAL(10, 2) NOT NULL CHECK (BuyInPrice > 0),
    SellingPrice DECIMAL(10, 2) NOT NULL CHECK (SellingPrice > 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT
);

CREATE TABLE RepairService (
    RepairID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    AcceptedDate TIMESTAMP NOT NULL,
    CompletionDate TIMESTAMP,
    Status repair_status NOT NULL,
    ProblemDescription TEXT NOT NULL,
    RepairDetails TEXT NOT NULL,
    EstimatedPrice DECIMAL(10, 2) NOT NULL CHECK (EstimatedPrice > 0),
    FinalPrice DECIMAL(10, 2) CHECK (FinalPrice IS NULL OR FinalPrice > 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT,
    CHECK (CompletionDate IS NULL OR CompletionDate >= AcceptedDate)
);

CREATE TABLE SetUpService (
    SetUpID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    AcceptedDate TIMESTAMP NOT NULL,
    CompletedDate TIMESTAMP,
    Status setup_status NOT NULL,
    SetUpType setup_type NOT NULL,
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE RESTRICT,
    CHECK (CompletedDate IS NULL OR CompletedDate >= AcceptedDate)
);

CREATE VIEW OrderTotal AS
SELECT
    oi.OrderID,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalAmount
FROM OrderItem oi
GROUP BY oi.OrderID;

CREATE VIEW RentTotal AS
SELECT
    r.RentID,
    ROUND(p.Price * r.PercentageFromPrice / 100 * r.Duration, 2) AS TotalRentPrice
FROM Rent r
JOIN Product p ON p.ProductID = r.ProductID;

CREATE VIEW BuyInProfit AS
SELECT
    BuyInID,
    SellingPrice - BuyInPrice AS TotalProfit,
    Status = 'Sold' AS IsSold
FROM InstrumentBuyIn;
