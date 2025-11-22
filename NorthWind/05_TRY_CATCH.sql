-- Example: simple fundamental - try catch can allow the script to continue even if there's an error.
BEGIN TRY
    SELECT Discount, 10/Discount, *
	FROM [Order Details]
END TRY
BEGIN CATCH
    PRINT 'Oops, division by zero happened!';
	SELECT TOP 5 'Catch Select', * FROM [Order Details]; -- Semi-colon IS needed after this select statement, otherwise the THROW keyword will not work as SQL will silently IGNORE the THROW keyword.
	THROW
	PRINT 'If THROW was always effective, you would not see this message. Semi-colon or no, see?' -- This runs. Script continues.
END CATCH

-- Example using: Northwind DB
-- try/catch block combo attempting to delete latest 5 orders (should fail due to order details foreign key constraint)
BEGIN TRY
	BEGIN TRAN
	DELETE o
	OUTPUT DELETED.OrderID
	FROM ( -- latest 5 orders. target records must be in a subquery as delete doesn't work with order by clauses.
		SELECT TOP (5) * FROM Orders
		WHERE OrderID IN (SELECT OrderID FROM [Order Details])
		-- include OUTPUT line to see which records would have been deleted
		ORDER BY OrderDate DESC
	) o
	ROLLBACK
END TRY
BEGIN CATCH
	THROW 50000, 'Cannot delete an order which has associated order details.', 1; -- if you use "THROW" keyword, then the script will stop and throw an error.
END CATCH

-- Example using: temp tables
-- declare the temp tables (must use temp tables in this example because SQL Server, like standard SQL implementations, does not allow you to create a FOREIGN KEY constraint that references a table variable
DROP TABLE IF EXISTS #Customers
CREATE TABLE #Customers (
	CustomerID NCHAR(5) PRIMARY KEY,
	CustomerName NVARCHAR(40),
	IsActive BIT)
DROP TABLE IF EXISTS #Orders
CREATE TABLE #Orders (
	OrderID INT IDENTITY PRIMARY KEY,
	CustomerID NCHAR(5),
	OrderDate DATE,
	CONSTRAINT FK_CustomerID FOREIGN KEY (CustomerID) REFERENCES #Customers(CustomerID))
-- insert values
INSERT INTO #Customers (
	CustomerID, CustomerName, IsActive)
VALUES
	('ALFKI','Alfreds',0),
	('ANATR','Ana Trujillo',0),
	('TOMSP','Toms Spezialitäten',0),
	('WELLI','Wellington',1)
INSERT INTO #Orders (
	CustomerID, OrderDate)
VALUES
	('ALFKI','2025-01-01'),
	('TOMSP','2025-02-01')
-- show the table values prior to try/catch deletion
SELECT 'pre-delete -- customers', * FROM #Customers
SELECT 'pre-delete -- orders', * FROM #Orders
BEGIN TRY
	IF EXISTS (SELECT 1 FROM #Orders o JOIN #Customers c ON o.CustomerID = c.CustomerID WHERE c.IsActive = 0)
    RAISERROR('Cannot delete customer(s) because they have existing orders.', 16, 1) -- required to explicitely raise the error due to using #temp tables.
	BEGIN TRAN
		DELETE FROM #Customers
		OUTPUT DELETED.CustomerID
		WHERE IsActive = 0
	ROLLBACK
END TRY
BEGIN CATCH
	THROW;
END CATCH
-- show the table values prior to try/catch deletion
SELECT 'post-delete -- customers', * FROM #Customers
SELECT 'post-delete -- orders', * FROM #Orders