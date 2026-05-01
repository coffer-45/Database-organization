TRUNCATE TABLE
    SetUpService,
    RepairService,
    InstrumentBuyIn,
    StudioBooking,
    Rent,
    OrderItem,
    CustomerOrder,
    Product,
    Brand,
    Category,
    Customer
RESTART IDENTITY CASCADE;

INSERT INTO Customer (FirstName, LastName, Email, Phone, PasswordHash) VALUES
    ('Олександр', 'Шевченко', 'alex.shev@gmail.com', '+380501234567', 'hash_123qwerty'),
    ('Марія', 'Коваленко', 'maria.kov@gmail.com', '+380671234567', 'hash_987asdfgh'),
    ('Іван', 'Бойко', 'ivan.boyko@gmail.com', '+380931234567', 'hash_555zxcvbn'),
    ('Олена', 'Ткачук', 'olena.tk@gmail.com', '+380661234567', 'hash_111poiuyt'),
    ('Андрій', 'Вовк', 'andriy.vovk@io41.edu.ua', '+380991234567', 'hash_mysecurepass');

INSERT INTO Category (Name, Description) VALUES
    ('Електрогітари', 'Гітари із суцільним корпусом та магнітними звукознімачами'),
    ('Акустичні гітари', 'Класичні та естрадні акустичні гітари з дерев''яним корпусом'),
    ('Бас-гітари', 'Чотири- та п''ятиструнні бас-гітари'),
    ('Укулеле', 'Маленькі чотириструнні гавайські гітари');

INSERT INTO Brand (Name) VALUES
    ('Fender'),
    ('Gibson'),
    ('Yamaha'),
    ('Taylor'),
    ('Cort'),
    ('Ibanez'),
    ('Takamine');

INSERT INTO Product (CategoryID, BrandID, Model, Price, StockQuantity) VALUES
    (1, 1, 'Stratocaster Player', 35000.00, 10),
    (1, 2, 'Les Paul Standard', 95000.00, 3),
    (2, 3, 'F310', 6500.00, 25),
    (2, 4, '114ce', 42000.00, 5),
    (3, 5, 'Action Bass Plus', 8500.00, 12),
    (1, 6, 'RG421 Used', 18000.00, 1),
    (2, 7, 'GD20 Used', 9000.00, 1);

INSERT INTO CustomerOrder (CustomerID, Status, ShippingAddress) VALUES
    (1, 'New', 'Київ, вул. Хрещатик, 15, кв. 4'),
    (2, 'Paid', 'Львів, пл. Ринок, 10, кв. 2'),
    (3, 'Shipped', 'Одеса, вул. Дерибасівська, 5'),
    (4, 'New', 'Київ, вул. Богатирська 34/12'),
    (4, 'Shipped', 'Київ, вул. Виноградарська 44а, кв. 76');

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice) VALUES
    (1, 1, 1, 35000.00),
    (2, 3, 2, 6500.00),
    (3, 2, 1, 95000.00);

INSERT INTO Rent (CustomerID, ProductID, PickUpDate, Duration, ReturnDate, Status, PercentageFromPrice, DepositAmount) VALUES
    (2, 1, '2026-03-20 10:00:00', 7, '2026-03-27 10:00:00', 'Returned', 10.00, 5000.00),
    (4, 4, '2026-03-25 12:00:00', 3, '2026-03-28 12:00:00', 'Active', 8.00, 6000.00);

INSERT INTO StudioBooking (CustomerID, RecordDate, Status, Duration, Price) VALUES
    (1, '2026-03-29 14:00:00', 'Booked', 2, 1200.00),
    (5, '2026-03-22 16:00:00', 'Completed', 3, 1800.00);

INSERT INTO InstrumentBuyIn (CustomerID, ProductID, Condition, Status, BuyInPrice, SellingPrice) VALUES
    (3, 6, 'Good', 'PreparedForSale', 12000.00, 18000.00),
    (4, 7, 'Fair', 'Sold', 6000.00, 9000.00);

INSERT INTO RepairService (
    CustomerID,
    ProductID,
    AcceptedDate,
    CompletionDate,
    Status,
    ProblemDescription,
    RepairDetails,
    EstimatedPrice,
    FinalPrice
) VALUES
    (2, 2, '2026-03-18 11:00:00', '2026-03-22 15:00:00', 'Completed', 'Не працює перемикач звукознімачів', 'Замінено перемикач та виконано перевірку електроніки', 1500.00, 1700.00),
    (5, 6, '2026-03-26 10:30:00', NULL, 'InProgress', 'Потрібне усунення брязкоту ладів', 'Виконується шліфування ладів та загальна діагностика', 1800.00, NULL);

INSERT INTO SetUpService (CustomerID, ProductID, AcceptedDate, CompletedDate, Status, SetUpType, Price) VALUES
    (1, 1, '2026-03-17 09:00:00', '2026-03-17 13:00:00', 'Completed', 'Full', 1200.00),
    (3, 3, '2026-03-24 10:00:00', '2026-03-24 12:00:00', 'IssuedToCustomer', 'StringsReplacement', 500.00);
