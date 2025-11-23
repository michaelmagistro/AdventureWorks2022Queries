-- Example: Multi-row INSERT using VALUES in Northwind database
-- This inserts multiple rows into the Products table in a single statement.
-- Note: Ensure the database schema matches Northwind standards.
-- For practice, run this in a test environment or after backing up data.

CREATE TABLE #Products (
    ProductName VARCHAR(30), SupplierID INT, CategoryID INT, QuantityPerUnit VARCHAR(30), UnitPrice DECIMAL, UnitsInStock INT
)

INSERT INTO #Products (ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock)
VALUES 
    ('Organic Coffee', 1, 1, '10 boxes', 18.50, 200),
    ('Herbal Tea', 2, 2, '20 bags', 12.00, 150),
    ('Spice Mix', 3, 4, '5 jars', 8.75, 100),
    ('Exotic Fruit', 4, 7, '12 cans', 22.00, 75);

-- Verify the inserts
SELECT ProductName, UnitPrice, UnitsInStock 
FROM #Products 
WHERE ProductName IN ('Organic Coffee', 'Herbal Tea', 'Spice Mix', 'Exotic Fruit')
ORDER BY ProductName;

DROP TABLE #Products