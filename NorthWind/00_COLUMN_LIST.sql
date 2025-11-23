USE Northwind
GO
-- See every column of the database
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS
ORDER BY 
    TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;

GO

-- Tiny window in to each table
DECLARE @topN INT
SET @topN = 8
SELECT TOP (@topN) * FROM Categories
SELECT TOP (@topN) * FROM CustomerCustomerDemo
SELECT TOP (@topN) * FROM CustomerDemographics
SELECT TOP (@topN) * FROM Customers
SELECT TOP (@topN) * FROM Employees
SELECT TOP (@topN) * FROM EmployeeTerritories
SELECT TOP (@topN) * FROM [Order Details]
SELECT TOP (@topN) * FROM [Order Subtotals]
SELECT TOP (@topN) * FROM Orders
SELECT TOP (@topN) * FROM Products
SELECT TOP (@topN) * FROM Region
SELECT TOP (@topN) * FROM Shippers
SELECT TOP (@topN) * FROM Territories

-- for convenience, look closer
SELECT TOP 20 * FROM Categories
SELECT TOP 20 * FROM CustomerCustomerDemo
SELECT TOP 20 * FROM CustomerDemographics
SELECT TOP 20 * FROM Customers
SELECT TOP 20 * FROM Employees
SELECT TOP 20 * FROM EmployeeTerritories
SELECT TOP 20 * FROM [Order Details]
SELECT TOP 20 * FROM [Order Subtotals]
SELECT TOP 20 * FROM Orders
SELECT TOP 20 * FROM Products
SELECT TOP 20 * FROM Region
SELECT TOP 20 * FROM Shippers
SELECT TOP 20 * FROM Territories