
TRUNCATE TABLE Purchases, TicketTypes, Events, Customers, Venues RESTART IDENTITY CASCADE;

-- Початкові дані
INSERT INTO Venues (name, location, capacity) VALUES
('Палац Спорту', 'Київ', 10000),
('Оперний театр', 'Львів', 1200),
('Стадіон Чорноморець', 'Одеса', 34000);

INSERT INTO Events (venue_id, name, event_date, event_time, event_type) VALUES
(1, 'Концерт Океан Ельзи', '2026-10-20', '19:00', 'Концерт'),
(2, 'Балет Лебедине озеро', '2026-10-20', '18:00', 'Театр'),
(3, 'Футбольний матч', '2026-11-05', '20:00', 'Спорт');

INSERT INTO Customers (username, first_name, last_name, email, phone, password_hash, registration_date) VALUES
('ivan_pedrenko', 'Іван', 'Петренко', 'ivan.goida@gmail.com', '0501112233', 'hash_ivan_123', '2026-03-01'),
('artem_davydchuk', 'Артем', 'Давидчук', 'artem.davydchuk@gmail.com', '0671112233', 'hash_artem_123', '2026-03-05'),
('andrii_vovk', 'Андрій', 'Вовк', 'andrii.vovk@edu.kpi.ua', '0631112233', 'hash_andrii_123', '2026-03-10');

INSERT INTO TicketTypes (event_id, type_name, price, allocated_quantity) VALUES
(1, 'VIP', 2500.00, 200),
(1, 'Звичайний', 800.00, 5000),
(1, 'Студентський', 500.00, 1000),
(2, 'VIP', 1800.00, 100),
(2, 'Звичайний', 1200.00, 500),
(3, 'Звичайний', 400.00, 10000);

INSERT INTO Purchases (customer_id, ticket_type_id, quantity, total_price) VALUES
(1, 2, 2, 1600.00),
(1, 5, 1, 1200.00),
(2, 1, 1, 2500.00),
(3, 6, 4, 1600.00);

-- OLTP: 2 INSERT запити
INSERT INTO Venues (name, location, capacity)
VALUES ('Арена Львів', 'Львів', 34915);

INSERT INTO Customers (username, first_name, last_name, email, phone, password_hash, registration_date)
VALUES ('delete_customer', 'Клієнт', 'ДляВидалення', 'delete.me@example.com', '0000000000', 'hash_delete_123', '2026-03-15');

-- OLTP: 2 UPDATE запити
UPDATE Venues
SET capacity = 12000
WHERE name = 'Палац Спорту';

UPDATE Events
SET event_time = '20:00'
WHERE name = 'Концерт Океан Ельзи';

-- OLTP: 2 DELETE запити
DELETE FROM Customers
WHERE email = 'delete.me@example.com';

DELETE FROM Venues
WHERE name = 'Арена Львів';

-- OLTP: 2 прості SELECT
-- 1. Знайти всі події на конкретному майданчику
SELECT e.name AS event_name, e.event_date, e.event_time, e.event_type
FROM Events e
JOIN Venues v ON e.venue_id = v.venue_id
WHERE v.name = 'Палац Спорту';

-- 2. Порахувати доступні квитки для події за типом квитка
SELECT
    tt.type_name,
    tt.allocated_quantity,
    COALESCE(SUM(p.quantity), 0) AS tickets_sold,
    tt.allocated_quantity - COALESCE(SUM(p.quantity), 0) AS tickets_available
FROM TicketTypes tt
LEFT JOIN Purchases p ON tt.ticket_type_id = p.ticket_type_id
WHERE tt.event_id = 1
GROUP BY tt.ticket_type_id, tt.type_name, tt.allocated_quantity
ORDER BY tt.type_name;

-- OLAP: 1. Обчислити загальний дохід за типом події
SELECT
    e.event_type,
    COALESCE(SUM(p.total_price), 0) AS total_revenue
FROM Events e
LEFT JOIN TicketTypes tt ON e.event_id = tt.event_id
LEFT JOIN Purchases p ON tt.ticket_type_id = p.ticket_type_id
GROUP BY e.event_type
ORDER BY total_revenue DESC;

-- OLAP: 2. Знайти топ-10 найбільш продаваних подій
SELECT
    e.name AS event_name,
    COALESCE(SUM(p.quantity), 0) AS total_tickets_sold
FROM Events e
LEFT JOIN TicketTypes tt ON e.event_id = tt.event_id
LEFT JOIN Purchases p ON tt.ticket_type_id = p.ticket_type_id
GROUP BY e.event_id, e.name
ORDER BY total_tickets_sold DESC
LIMIT 10;

-- OLAP: 3. Обчислити середню ціну квитка за майданчиком
SELECT
    v.name AS venue_name,
    ROUND(AVG(tt.price), 2) AS average_ticket_price
FROM Venues v
JOIN Events e ON v.venue_id = e.venue_id
JOIN TicketTypes tt ON e.event_id = tt.event_id
GROUP BY v.venue_id, v.name
ORDER BY average_ticket_price DESC;

-- OLAP: 4. Знайти клієнтів, які купили квитки на декілька подій на одну і ту ж дату
SELECT
    c.first_name,
    c.last_name,
    e.event_date,
    COUNT(DISTINCT e.event_id) AS events_count
FROM Customers c
JOIN Purchases p ON c.customer_id = p.customer_id
JOIN TicketTypes tt ON p.ticket_type_id = tt.ticket_type_id
JOIN Events e ON tt.event_id = e.event_id
GROUP BY c.customer_id, c.first_name, c.last_name, e.event_date
HAVING COUNT(DISTINCT e.event_id) > 1
ORDER BY e.event_date, c.last_name, c.first_name;
