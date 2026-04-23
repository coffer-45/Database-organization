-- Лабораторна робота 4
-- Аналітичні SQL-запити (OLAP)

-- 1. Загальна кількість клієнтів
SELECT COUNT(*) AS total_customers
FROM Customer;

-- 2. Статистика цін на товари
SELECT
    AVG(Price) AS avg_product_price,
    MIN(Price) AS min_product_price,
    MAX(Price) AS max_product_price
FROM Product;

-- 3. Загальна вартість залишків товарів на складі
SELECT SUM(Price * StockQuantity) AS total_inventory_value
FROM Product;

-- 4. Кількість товарів у кожній категорії
SELECT
    c.Name AS category_name,
    COUNT(p.ProductID) AS product_count
FROM Category c
LEFT JOIN Product p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.Name
ORDER BY product_count DESC, c.Name;

-- 5. Категорії, у яких більше одного товару
SELECT
    c.Name AS category_name,
    COUNT(p.ProductID) AS product_count
FROM Category c
JOIN Product p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.Name
HAVING COUNT(p.ProductID) > 1
ORDER BY product_count DESC, c.Name;

-- 6. INNER JOIN: список замовлень із клієнтами
SELECT
    co.OrderID,
    c.FirstName,
    c.LastName,
    co.OrderDate,
    co.Status,
    co.TotalAmount
FROM CustomerOrder co
INNER JOIN Customer c ON c.CustomerID = co.CustomerID
ORDER BY co.OrderDate;

-- 7. LEFT JOIN: усі категорії та середня ціна товарів у них
SELECT
    c.Name AS category_name,
    COUNT(p.ProductID) AS product_count,
    AVG(p.Price) AS avg_category_price
FROM Category c
LEFT JOIN Product p ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.Name
ORDER BY c.Name;

-- 8. RIGHT JOIN: товари та їх категорії
SELECT
    c.Name AS category_name,
    p.Brand,
    p.Model,
    p.Price
FROM Product p
RIGHT JOIN Category c ON p.CategoryID = c.CategoryID
ORDER BY c.Name, p.Brand, p.Model;

-- 9. Багатотаблична агрегація: скільки витратив кожен клієнт
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    SUM(oi.Quantity * oi.UnitPrice) AS total_spent
FROM Customer c
JOIN CustomerOrder co ON co.CustomerID = c.CustomerID
JOIN OrderItem oi ON oi.OrderID = co.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY total_spent DESC;

-- 10. Підзапит у WHERE: товари дорожчі за середню ціну
SELECT
    Brand,
    Model,
    Price
FROM Product
WHERE Price > (
    SELECT AVG(Price)
    FROM Product
)
ORDER BY Price DESC;

-- 11. Підзапит у SELECT: кількість замовлень кожного клієнта
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    (
        SELECT COUNT(*)
        FROM CustomerOrder co
        WHERE co.CustomerID = c.CustomerID
    ) AS order_count
FROM Customer c
ORDER BY order_count DESC, c.LastName, c.FirstName;

-- 12. Підзапит у HAVING: клієнти, які витратили більше за середні витрати
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    SUM(oi.Quantity * oi.UnitPrice) AS total_spent
FROM Customer c
JOIN CustomerOrder co ON co.CustomerID = c.CustomerID
JOIN OrderItem oi ON oi.OrderID = co.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING SUM(oi.Quantity * oi.UnitPrice) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(oi2.Quantity * oi2.UnitPrice) AS customer_total
        FROM CustomerOrder co2
        JOIN OrderItem oi2 ON oi2.OrderID = co2.OrderID
        GROUP BY co2.CustomerID
    ) AS avg_totals
)
ORDER BY total_spent DESC;
