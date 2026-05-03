# Лабораторна робота №5

**Тема:** Нормалізація бази даних  
**Виконав:** Вовк Андрій, Троценко Максим, група ІО-41

## Мета роботи

Проаналізувати схему бази даних інтернет-магазину гітар, створену в лабораторній роботі №2, визначити функціональні залежності, перевірити відповідність таблиць нормальним формам та усунути надлишковість даних шляхом нормалізації до третьої нормальної форми.

## Вихідна схема бази даних

У лабораторній роботі №2 було створено схему предметної області «Інтернет-магазин гітар». Вона містить такі таблиці:

- `Customer` — клієнти магазину;
- `Category` — категорії товарів;
- `Product` — товари магазину;
- `CustomerOrder` — замовлення клієнтів;
- `OrderItem` — позиції замовлень;
- `Rent` — оренда інструментів;
- `StudioBooking` — записи до студії самозапису;
- `InstrumentBuyIn` — операції викупу вживаних інструментів;
- `RepairService` — послуги ремонту;
- `SetUpService` — послуги налаштування інструментів.

Схема з другої лабораторної вже загалом розбита на окремі сутності: клієнти, товари, категорії, замовлення, оренда та послуги не зберігаються в одній великій таблиці. Тому грубих порушень 1НФ або 2НФ у ній немає.

Під час перевірки основна увага була на тому, чи не зберігаються в таблицях значення, які можна отримати з уже наявних даних. Саме такі поля є головною проблемою початкової схеми:

- `TotalAmount` у `CustomerOrder`;
- `TotalRentPrice` у `Rent`;
- `TotalProfit` та `IsSold` у `InstrumentBuyIn`;
- текстове поле `Brand` у `Product`.

Через ці поля можуть з'являтися суперечності. Наприклад, якщо змінити позиції замовлення, але не оновити `TotalAmount`, сума замовлення в таблиці вже буде неправильною.

## Функціональні залежності початкової схеми

### `Customer`

Первинний ключ: `CustomerID`.

Функціональні залежності:

```text
CustomerID -> FirstName, LastName, Email, Phone, PasswordHash
Email -> CustomerID, FirstName, LastName, Phone, PasswordHash
```

Атрибут `Email` є унікальним, тому він також може бути альтернативним ключем.

### `Category`

Первинний ключ: `CategoryID`.

Функціональні залежності:

```text
CategoryID -> Name, Description
Name -> CategoryID, Description
```

У цій предметній області назву категорії краще зробити унікальною, бо дві категорії з однаковою назвою тільки плутатимуть дані.

### `Product`

Первинний ключ: `ProductID`.

Функціональні залежності:

```text
ProductID -> CategoryID, Brand, Model, Price, StockQuantity
CategoryID -> Category.Name, Category.Description
```

У `Product` бренд зберігається звичайним текстом. Для кількох товарів одного бренду це означає повторення одного й того самого значення. Наприклад, якщо назву `Fender` треба буде змінити або виправити, її доведеться шукати в усіх товарах. Тому бренд краще винести в окрему таблицю `Brand`.

### `CustomerOrder`

Первинний ключ: `OrderID`.

Функціональні залежності:

```text
OrderID -> CustomerID, OrderDate, Status, ShippingAddress, TotalAmount
```

Поле `TotalAmount` не є окремим фактом. Його можна порахувати з позицій замовлення:

```text
SUM(OrderItem.Quantity * OrderItem.UnitPrice)
```

Тому зберігати його в `CustomerOrder` необов'язково. Якщо кількість або ціна в `OrderItem` зміниться, а `TotalAmount` залишиться старим, дані стануть некоректними.

### `OrderItem`

Первинний ключ: `OrderItemID`.

Альтернативний ключ: `(OrderID, ProductID)`.

Функціональні залежності:

```text
OrderItemID -> OrderID, ProductID, Quantity, UnitPrice
OrderID, ProductID -> Quantity, UnitPrice
```

Таблиця `OrderItem` описує конкретний товар у конкретному замовленні. Саме тому `Quantity` і `UnitPrice` залежать від пари `(OrderID, ProductID)`, а не від одного з цих полів окремо.

### `Rent`

Первинний ключ: `RentID`.

Функціональні залежності:

```text
RentID -> CustomerID, ProductID, PickUpDate, Duration, ReturnDate, Status,
          PercentageFromPrice, TotalRentPrice, DepositAmount
ProductID -> Product.Price
```

`TotalRentPrice` також є обчислюваним полем. Його можна отримати з ціни товару, відсотка оренди та тривалості. Через це його краще не дублювати в таблиці `Rent`.

### `StudioBooking`

Первинний ключ: `StudioID`.

Функціональні залежності:

```text
StudioID -> CustomerID, RecordDate, Status, Duration, Price
```

Порушень нормальних форм не виявлено.

### `InstrumentBuyIn`

Первинний ключ: `BuyInID`.

Альтернативний ключ: `ProductID`, оскільки в початковій схемі він має обмеження `UNIQUE`.

Функціональні залежності:

```text
BuyInID -> CustomerID, ProductID, Condition, Status, BuyInPrice,
           SellingPrice, TotalProfit, IsSold
ProductID -> BuyInID, CustomerID, Condition, Status, BuyInPrice,
             SellingPrice, TotalProfit, IsSold
```

Проблемні поля:

- `TotalProfit` є похідним атрибутом: `SellingPrice - BuyInPrice`;
- `IsSold` дублює частину змісту атрибута `Status`, оскільки статус `Sold` уже означає, що товар продано.

Наприклад, якщо в одному рядку буде `Status = 'Sold'`, але `IsSold = FALSE`, то з такого запису вже незрозуміло, проданий інструмент чи ні. Тому достатньо залишити тільки `Status`, а прибуток рахувати окремо.

### `RepairService`

Первинний ключ: `RepairID`.

Функціональні залежності:

```text
RepairID -> CustomerID, ProductID, AcceptedDate, CompletionDate, Status,
            ProblemDescription, RepairDetails, EstimatedPrice, FinalPrice
```

Окремої проблеми з нормальними формами тут немає. Але для практичності `CompletionDate` і `FinalPrice` краще дозволити залишати порожніми, бо ремонт може бути ще не завершений.

### `SetUpService`

Первинний ключ: `SetUpID`.

Функціональні залежності:

```text
SetUpID -> CustomerID, ProductID, AcceptedDate, CompletedDate, Status,
           SetUpType, Price
```

Окремої проблеми з нормальними формами тут також немає. `CompletedDate` краще зробити необов'язковим, бо налаштування може ще виконуватися.

## Аналіз нормальних форм початкової схеми

### Перша нормальна форма

Усі таблиці перебувають у 1НФ, оскільки:

- усі атрибути мають атомарні значення;
- у таблицях немає списків значень в одному полі;
- немає повторюваних груп колонок.

### Друга нормальна форма

Більшість таблиць має простий первинний ключ типу `SERIAL`, тому часткові залежності від частини ключа неможливі.

Таблиця `OrderItem` має альтернативний складений ключ `(OrderID, ProductID)`. Атрибути `Quantity` і `UnitPrice` залежать від усієї комбінації `(OrderID, ProductID)`, а не лише від `OrderID` або лише від `ProductID`.

Отже, початкова схема перебуває у 2НФ.

### Третя нормальна форма

Основні проблеми схеми пов'язані не з неатомарністю, а з надлишковими похідними атрибутами:

- `CustomerOrder.TotalAmount`;
- `Rent.TotalRentPrice`;
- `InstrumentBuyIn.TotalProfit`;
- `InstrumentBuyIn.IsSold`;
- текстовий атрибут `Product.Brand`, який краще винести в довідникову таблицю.

Ці атрибути створюють аномалії оновлення, тому схема потребує вдосконалення перед фінальним приведенням до 3НФ.

## Нормалізація схеми

### Крок 1. Приведення до 1НФ

Початкова схема вже відповідає 1НФ. Усі поля мають атомарні значення. Наприклад, у таблиці `Customer` ім'я, прізвище, email і телефон зберігаються окремими атрибутами, а не одним текстовим списком.

Змін на цьому етапі не потрібно.

### Крок 2. Приведення до 2НФ

Початкова схема вже відповідає 2НФ, оскільки неключові атрибути не залежать від частини складеного ключа.

Для таблиці `OrderItem` залежності мають такий вигляд:

```text
OrderID, ProductID -> Quantity, UnitPrice
```

Атрибути `Quantity` і `UnitPrice` описують конкретну позицію конкретного замовлення, тому залежать від повної комбінації `OrderID` і `ProductID`.

### Крок 3. Приведення до 3НФ

Для усунення надлишковості виконуються такі зміни:

1. Створюється таблиця `Brand`.
2. У таблиці `Product` текстове поле `Brand` замінюється зовнішнім ключем `BrandID`.
3. З таблиці `CustomerOrder` видаляється похідний атрибут `TotalAmount`.
4. З таблиці `Rent` видаляється похідний атрибут `TotalRentPrice`.
5. З таблиці `InstrumentBuyIn` видаляються похідні або дублюючі атрибути `TotalProfit` та `IsSold`.
6. У таблицях `RepairService` і `SetUpService` дати завершення робляться необов'язковими, щоб незавершені послуги не зберігали штучні дати.

## Змінені таблиці

### `Brand`

Нова довідникова таблиця брендів:

```sql
CREATE TABLE Brand (
    BrandID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE
);
```

Функціональна залежність:

```text
BrandID -> Name
Name -> BrandID
```

### `Product` після нормалізації

Було:

```text
Product(ProductID, CategoryID, Brand, Model, Price, StockQuantity)
```

Стало:

```text
Product(ProductID, CategoryID, BrandID, Model, Price, StockQuantity)
```

Поле `Brand` більше не дублюється як текст. Замість нього використовується `BrandID`.

### `CustomerOrder` після нормалізації

Було:

```text
CustomerOrder(OrderID, CustomerID, OrderDate, Status, ShippingAddress, TotalAmount)
```

Стало:

```text
CustomerOrder(OrderID, CustomerID, OrderDate, Status, ShippingAddress)
```

Сума замовлення обчислюється запитом:

```sql
SELECT
    OrderItem.OrderID,
    SUM(OrderItem.Quantity * OrderItem.UnitPrice) AS TotalAmount
FROM OrderItem
GROUP BY OrderItem.OrderID;
```

### `Rent` після нормалізації

Було:

```text
Rent(RentID, CustomerID, ProductID, PickUpDate, Duration, ReturnDate,
     Status, PercentageFromPrice, TotalRentPrice, DepositAmount)
```

Стало:

```text
Rent(RentID, CustomerID, ProductID, PickUpDate, Duration, ReturnDate,
     Status, PercentageFromPrice, DepositAmount)
```

Загальна сума оренди обчислюється запитом:

```sql
SELECT
    Rent.RentID,
    ROUND(Product.Price * Rent.PercentageFromPrice / 100 * Rent.Duration, 2) AS TotalRentPrice
FROM Rent
JOIN Product ON Product.ProductID = Rent.ProductID;
```

### `InstrumentBuyIn` після нормалізації

Було:

```text
InstrumentBuyIn(BuyInID, CustomerID, ProductID, Condition, Status,
                BuyInPrice, SellingPrice, TotalProfit, IsSold)
```

Стало:

```text
InstrumentBuyIn(BuyInID, CustomerID, ProductID, Condition, Status,
                BuyInPrice, SellingPrice)
```

Прибуток обчислюється запитом:

```sql
SELECT
    BuyInID,
    SellingPrice - BuyInPrice AS TotalProfit
FROM InstrumentBuyIn;
```

Факт продажу визначається через статус:

```sql
SELECT *
FROM InstrumentBuyIn
WHERE Status = 'Sold';
```

## Приклади `ALTER TABLE` для переходу від початкової схеми

```sql
CREATE TABLE Brand (
    BrandID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO Brand (Name)
SELECT DISTINCT Brand
FROM Product;

ALTER TABLE Product
ADD COLUMN BrandID INT;

UPDATE Product
SET BrandID = Brand.BrandID
FROM Brand
WHERE Product.Brand = Brand.Name;

ALTER TABLE Product
ALTER COLUMN BrandID SET NOT NULL;

ALTER TABLE Product
ADD CONSTRAINT fk_product_brand
FOREIGN KEY (BrandID) REFERENCES Brand(BrandID) ON DELETE RESTRICT;

ALTER TABLE Product
DROP COLUMN Brand;

ALTER TABLE CustomerOrder
DROP COLUMN TotalAmount;

ALTER TABLE Rent
DROP COLUMN TotalRentPrice;

ALTER TABLE InstrumentBuyIn
DROP COLUMN TotalProfit,
DROP COLUMN IsSold;

ALTER TABLE RepairService
ALTER COLUMN CompletionDate DROP NOT NULL,
ALTER COLUMN FinalPrice DROP NOT NULL;

ALTER TABLE SetUpService
ALTER COLUMN CompletedDate DROP NOT NULL;
```

<div align="center">
  <img src="media/image.png" alt="виконання normalization.sql у Query Tool pgAdmin без помилок.">
  <p><em>виконання normalization.sql у Query Tool pgAdmin без помилок.</em></p>
</div>

## Фінальна схема у 3НФ

Після нормалізації схема містить такі таблиці:

- `Customer(CustomerID, FirstName, LastName, Email, Phone, PasswordHash)`;
- `Category(CategoryID, Name, Description)`;
- `Brand(BrandID, Name)`;
- `Product(ProductID, CategoryID, BrandID, Model, Price, StockQuantity)`;
- `CustomerOrder(OrderID, CustomerID, OrderDate, Status, ShippingAddress)`;
- `OrderItem(OrderItemID, OrderID, ProductID, Quantity, UnitPrice)`;
- `Rent(RentID, CustomerID, ProductID, PickUpDate, Duration, ReturnDate, Status, PercentageFromPrice, DepositAmount)`;
- `StudioBooking(StudioID, CustomerID, RecordDate, Status, Duration, Price)`;
- `InstrumentBuyIn(BuyInID, CustomerID, ProductID, Condition, Status, BuyInPrice, SellingPrice)`;
- `RepairService(RepairID, CustomerID, ProductID, AcceptedDate, CompletionDate, Status, ProblemDescription, RepairDetails, EstimatedPrice, FinalPrice)`;
- `SetUpService(SetUpID, CustomerID, ProductID, AcceptedDate, CompletedDate, Status, SetUpType, Price)`.

У фінальній схемі:

- кожен факт зберігається в одному місці;
- похідні значення не дублюються у таблицях;
- довідникові значення брендів винесені в окрему таблицю;
- усі неключові атрибути залежать тільки від ключа своєї таблиці;
- транзитивні та надлишкові залежності усунено.


<div align="center">
  <img src="media/list_of_tables.png" alt="список створених таблиць у pgAdmin після виконання нормалізованої схеми.">
  <p><em>список створених таблиць у pgAdmin після виконання нормалізованої схеми.</em></p>
</div>

## SQL-скрипт фінальної схеми

Фінальний SQL-скрипт нормалізованої схеми наведено у файлі:

```text
normalization.sql
```

Тестові дані для нормалізованої схеми наведено у файлі:

```text
test_data.sql
```

<div align="center">
  <img src="media/test_data.png" alt="виконаний файл `test_data.sql` у Query Tool pgAdmin.">
  <p><em>виконаний файл `test_data.sql` у Query Tool pgAdmin.</em></p>
</div>

## Перевірка обчислюваних значень

Після видалення похідних атрибутів значення суми замовлення, вартості оренди та прибутку від викупу можна отримати через представлення `OrderTotal`, `RentTotal` та `BuyInProfit`.

<div align="center">
  <img src="media/OrderTotal.png" alt="результат запиту `SELECT * FROM OrderTotal;` у pgAdmin.">
  <p><em>результат запиту `SELECT * FROM OrderTotal;` у pgAdmin.</em></p>
</div>

<div align="center">
  <img src="media/RentTotal.png" alt="результат запиту `SELECT * FROM RentTotal;` у pgAdmin.">
  <p><em>результат запиту `SELECT * FROM RentTotal;` у pgAdmin.</em></p>
</div>

<div align="center">
  <img src="media/BuyInProfit.png" alt="результат запиту `SELECT * FROM BuyInProfit;` у pgAdmin.">
  <p><em>результат запиту `SELECT * FROM BuyInProfit;` у pgAdmin.</em></p>
</div>

## Оновлена ER-діаграма

Після нормалізації до ER-діаграми потрібно додати нову таблицю `Brand`, пов'язану з таблицею `Product` зв'язком один-до-багатьох:

```text
Brand 1 --- N Product
Category 1 --- N Product
Customer 1 --- N CustomerOrder
CustomerOrder 1 --- N OrderItem
Product 1 --- N OrderItem
Customer 1 --- N Rent
Product 1 --- N Rent
Customer 1 --- N StudioBooking
Customer 1 --- N InstrumentBuyIn
Product 1 --- 0..1 InstrumentBuyIn
Customer 1 --- N RepairService
Product 1 --- N RepairService
Customer 1 --- N SetUpService
Product 1 --- N SetUpService
```

Оновлену ER-діаграму можна згенерувати в pgAdmin після виконання SQL-скрипта `normalization.sql`.

<div align="center">
  <img src="media/ER_diagram.png" alt="оновлена ER-діаграма з pgAdmin, де видно таблицю `Brand` і зв'язок `Brand` — `Product`">
  <p><em>оновлена ER-діаграма з pgAdmin, де видно таблицю `Brand` і зв'язок `Brand` — `Product`</em></p>
</div>

## Висновок

У ході виконання лабораторної роботи було проаналізовано схему бази даних інтернет-магазину гітар, створену в лабораторній роботі №2. Було визначено функціональні залежності для всіх таблиць, перевірено відповідність схеми 1НФ, 2НФ та 3НФ, а також виявлено надлишкові похідні атрибути.

Для усунення аномалій оновлення було винесено бренди товарів в окрему таблицю `Brand`, видалено похідні поля `TotalAmount`, `TotalRentPrice`, `TotalProfit`, а також дублюючий атрибут `IsSold`. Після внесених змін фінальна схема відповідає третій нормальній формі, оскільки кожен неключовий атрибут залежить тільки від ключа відповідної таблиці та не дублює дані з інших таблиць.
