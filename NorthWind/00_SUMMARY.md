# NorthWind SQL Queries Summary

## 00_BASIC.sql
```sql
USE Northwind
GO
-- basic queries to grasp the datbase structure
select top 10 * from Employees
select top 10 * from Customers
select top 10 * from Orders
select top 10 * from [Order Details]
select top 10 * from Territories
select top 10 * from Region
select top 10 * from Products
select top 10 * from EmployeeTerritories
-- some basic joins
-- Orders & Details
SELECT TOP 10 *
FROM Orders o
LEFT JOIN [Order Details] od on o.OrderID = od.OrderID
-- employees and territories
SELECT TOP 100 et.*, e.*
FROM Employees e
LEFT JOIN EmployeeTerritories et on e.EmployeeID = et.EmployeeID
-- check territories for duplicates
SELECT COUNT(TerritoryID)-COUNT(DISTINCT(TerritoryID)) FROM EmployeeTerritories -- 0 dupes
-- check customers for duplicate last names
SELECT COUNT(ContactName)-COUNT(DISTINCT(ContactName)) FROM Customers -- 0 dupes
-- check orders for duplicate address
SELECT COUNT(ShipAddress)-COUNT(DISTINCT(ShipAddress)) FROM Orders -- 741 dupes
```

## 00_COLUMN_LIST.sql
```sql
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
```

## 00_DATE_GAPS_ISLANDS.sql
```sql
-- with CTE -- use instead of subqueries for readability and able to re-use the same subquery (the CTE) multiple times
WITH Src AS (
    SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
    FROM Orders
)
SELECT 
    MIN(OrderDay) AS PeriodStart,
    MAX(OrderDay) AS PeriodEnd,
    COUNT(*) AS OrdersInPeriod,
    DATEDIFF(DAY, MIN(OrderDay), MAX(OrderDay)) + 1 AS TotalCalendarDays
FROM (
    SELECT OrderDay,
           DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS Grp
    FROM Src
) x
GROUP BY Grp
ORDER BY PeriodStart;

-- without CTE for understanding
SELECT
    MIN(OrderDay) AS PeriodStart,
    MAX(OrderDay) AS PeriodEnd,
    COUNT(*) AS OrdersInPeriod,
    DATEDIFF(DAY, MIN(OrderDay), MAX(OrderDay)) + 1 AS TotalCalendarDays
FROM (
    SELECT OrderDay
    , DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS Grp
    FROM (
        SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
        FROM Orders
    ) o
) x
GROUP BY Grp
ORDER BY PeriodStart;

-- granular dissection for understanding & accuracy
SELECT OrderDay
-- , DATEADD(WEEK,1,GetDate()) AS DateAddEx
-- , ROW_NUMBER() OVER (ORDER BY OrderDay) AS RowPos -- give each distinct date a rank ascending
-- , DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS PeriodStartReverse
-- ,OrderDay
, -ROW_NUMBER() OVER (ORDER BY OrderDay) AS RowNeg  -- give each distinct date a rank descending (DISTINCT in the FROM statement)
, DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS PeriodStart
    -- based off of the distinct date values, and using row_number as a clever method, we are able to assign a "group" by assigning a "rank" to each non-blank date. DATEADD becomes "DATESUBSTRACT" due to to "-ROW_NUMBER"
    -- if the dates are out of order in the table, that's ok, as the row_number OVER window has the ORDER BY clause.
FROM (
    SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
    FROM Orders
) o

select cast(orderdate as date) from orders
```

## 00_DELETE_DUPLICATES.sql
```sql
-- insert duplicate example if not already there
-- INSERT INTO Employees (
-- 	LastName, FirstName
-- )
-- VALUES ('Doe', 'Jane')

SELECT * FROM Employees

BEGIN TRAN; -- Inside a transaction, SQL Server requires every statement after BEGIN TRAN to end with a semicolon
-- check for potential duplicates
WITH CTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY e.FirstName, e.LastName ORDER BY e.LastName, e.FirstName) Rn
	FROM Employees e
)
SELECT Rn, * FROM CTE WHERE Rn > 1;
-- DELETE FROM CTE WHERE Rn > 1;
ROLLBACK;
```

## 00_EXCEPT_NOT_EXISTS_NOT_IN.sql
```sql
-- EXCEPT, NOT EXISTS and NOT IN

-- Example: Using NOT EXISTS (correlated subquery)
-- Find Customers who do not have any Orders.
SELECT CustomerID, CompanyName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);

GO

-- NOT IN: can only be used when you know there are no NULLS. NOT EXISTS is best for any dynamic queries.
SELECT CustomerID, CompanyName
FROM Customers c
WHERE CustomerID NOT IN (SELECT CustomerID from Orders)
-- NOT IN: This returns ONE row (as expected)
SELECT 'ABC' AS abc WHERE 'ABC' NOT IN ('XYZ', '123'); -- OK >> 'ABC'
-- NOT IN: This returns ZERO rows (even though 'ABC' isn't in the list), because NULL changes how the logic works
SELECT 'ABC' AS abc WHERE 'ABC' NOT IN ('XYZ', '123', NULL); -- NULL makes it UNKNOWN >> no rows
-- NOT EXISTS: This returns ONE row (as expected)
SELECT 'ABC' AS abc WHERE NOT EXISTS (SELECT 1 WHERE 'ABC' IN ('XYZ', '123')); -- OK >> 'ABC'
-- NOT EXISTS: This returns ONE row (as expected) even throug there's a NULL value.
SELECT 'ABC' AS abc WHERE NOT EXISTS (SELECT 1 WHERE 'ABC' IN ('XYZ', '123', NULL)); -- OK >> 'ABC'


-- EXCEPT returns distinct rows from the left query that are not present in the right query
-- EXCEPT pitfall with NULL keys: removes NULL from left if right has NULL
SELECT val FROM (VALUES ('ABC'), (NULL)) A(val)
EXCEPT
SELECT val FROM (VALUES ('XYZ'), (NULL)) B(val);   -- returns only 'ABC' (NULL is treated as a literal value and thus excluded)

-- NOT EXISTS keeps NULL because NULL = NULL is UNKNOWN (NOT EXISTS is preferred in real-world scenarios because EXCEPT can drop rows silently if NULLs represent "unknown" rather than a matchable value
SELECT val FROM (VALUES ('ABC'), (NULL)) A(val)
WHERE NOT EXISTS (
    SELECT 1 FROM (VALUES ('XYZ'), (NULL)) B(val) WHERE B.val = A.val
);   -- returns 'ABC' and NULL (NULL is treated as an UNKNOWN, and thus included in the result set)
```

## 00_INSERT_VALUES_MULTIROW.sql
```sql
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
```

## 00_ISNULL_VS_COALESCE.sql
```sql
-- Comparison query showing both side by side
SELECT 
    OrderID,
    CustomerID,
    ShipRegion,
    ShipCountry,
    ShipPostalCode,
    COALESCE(ShipRegion, ShipCountry, ShipPostalCode, 'Unknown') AS Using_COALESCE, -- Coalesce functions as a "fallback"; if ShipRegion is null, use ShipCountry, if that is NULL, use 'Unknown' and so forth.
    ISNULL(ShipRegion, 'Unknown') AS Using_ISNULL -- Return ShipRegion; unless NULL, then 'Unknown'
FROM Orders 

-- Key Differences:
-- ISNULL: Only two arguments, treats as single type (can cause issues with data types).
-- COALESCE: Variable arguments, more flexible, but evaluates all (performance note for functions).


-- How ISNULL can cause issues with data types
-- ISNULL truncates 'Unknown Location' to fit VARCHAR(15) → 'Unknown Locati'
SELECT ISNULL(ShipRegion, 'Unknown Location') AS BadISNULL
FROM Orders 
WHERE ShipRegion IS NULL;

-- COALESCE uses the "best" type among arguments (here, fits full string)
SELECT COALESCE(ShipRegion, 'Unknown Location') AS GoodCOALESCE
FROM Orders 
WHERE ShipRegion IS NULL;
```

## 00_STRING_AGG.sql
```sql
-- Example: STRING_AGG in Northwind database

SELECT TOP 4 * FROM Products
SELECT TOP 4 * FROM Categories
SELECT p.*, c.* FROM Products p JOIN Categories c ON p.CategoryID = c.CategoryID

-- show a string of all products per category group.
SELECT
    c.CategoryID, -- optional to include this. a column in select must be in group by, but a column in group by does not necessarily need to be in the select clause.
    c.CategoryName,
    STRING_AGG(p.ProductName, ', ') AS Products, -- string_agg (as the name implies) is an aggregate function. like count or sum etc. but -- concatenate for strings. Omiting this agg function will not cause the query to error.
    STRING_AGG(p.ProductName, ', ') WITHIN GROUP (ORDER BY p.ProductName) AS SortedProducts -- you can sort within the concatenated string itself using WITHIN GROUP
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY c.CategoryName;

-- NULL handling: Skips NULLs automatically
SELECT STRING_AGG(val, ', ') AS Result
FROM (VALUES ('A'), (NULL), ('B')) AS t(val);  -- Returns 'A, B'

-- Key Notes:
-- Use WITHIN GROUP (ORDER BY) for sorted output.
-- Ignores NULLs; no duplicates unless DISTINCT added.
-- For older SQL, use STUFF + FOR XML PATH as alternative.
```

## 01_TOP_TIES_PERCENT.sql
```sql
USE Northwind
GO
-- Top, Ties, Percent
SELECT * FROM Orders
-- with ties
SELECT TOP 10 WITH TIES Country FROM Customers ORDER BY Country -- order by statement is mandatory when using WITH TIES
-- percent - show the top N number of records using PERCENT
select TOP 10 PERCENT * from orders ORDER BY Freight DESC -- this is not finding the top percent based on some value, but rather on record count.
```

## 02_SELECT_VS_SET.sql
```sql
USE Northwind
GO
-- SET vs SELECT statements
-- set a var to some value
DECLARE @someVar as VARCHAR(50); SET @someVar = 5 -- declare/set
SELECT 'select someVar - 1', @someVar as SomeVar -- (select)
SELECT @someVar = 6 -- set using select
SELECT 'select someVar - 2', @someVar as SomeVar -- (select)
SELECT @someVar = ContactName FROM Customers WHERE ContactName = 'Maria Anders' -- assign variable from column; must use SELECT in this case, not SET
SELECT 'select someVar - 3', @someVar as SomeVar -- (select)
SELECT @someVar = ContactName FROM Customers -- assigns last non-NULL value, silently, due to missing WHERE clause: beware!
SELECT 'select someVar - 4', @someVar as SomeVar -- (select)
SET @someVar = (SELECT CustomerID from Customers WHERE CustomerID = 'ALFKI') -- only works because there is only ONE return from the select query
SELECT 'select someVar - 5', @someVar as SomeVar -- (select)
```

## 03_OUTPUT.sql
```sql
USE Northwind
GO

-- OUTPUT to see changes in the Client.
BEGIN TRAN
UPDATE Customers
SET [ContactName] = 'Anna Trujilla'
OUTPUT INSERTED.ContactName as NewName, DELETED.ContactName as OldName -- "INSERTED.c.ContactName" invalid in OUTPUT clause. Never use the alias.
where [ContactName] = 'Ana Trujillo'
ROLLBACK
SELECT * FROM Customers WHERE ContactName = 'Ana Trujillo'
-- same as above query, but with a table alias. Slight difference in how the query is constructed
BEGIN TRAN
UPDATE c
SET c.[ContactName] = 'Anna Trujilla'
OUTPUT INSERTED.ContactName as NewName, DELETED.ContactName as OldName -- "INSERTED.c.ContactName" invalid in OUTPUT clause. Never use the alias.
FROM Customers c
where c.[ContactName] = 'Ana Trujillo'
ROLLBACK
SELECT * FROM Customers WHERE ContactName = 'Ana Trujillo'

-- Output but, but INTO a table variable
DECLARE @NameChange TABLE (TheNewName VARCHAR(50), OldName VARCHAR(50))
BEGIN TRAN
UPDATE c
SET c.[ContactName] = 'Anna Trujilla'
OUTPUT INSERTED.ContactName as NewName, DELETED.ContactName as OldName INTO @NameChange -- "INSERTED.c.ContactName" invalid in OUTPUT clause. Never use the alias.
FROM Customers c
where c.[ContactName] = 'Ana Trujillo'
ROLLBACK
SELECT 'Table Var', * FROM @NameChange
SELECT 'Actual Table', * FROM Customers WHERE ContactName = 'Ana Trujillo'

-- DELETE with OUTPUT and table variable
DECLARE @DeletedRows TABLE (
	OrderID INT,
	ProductID INT
)
BEGIN TRAN
DELETE [Order Details]
OUTPUT DELETED.OrderID, DELETED.ProductID INTO @DeletedRows
WHERE ProductID = 11
ROLLBACK
SELECT 'Table Var', * FROM @DeletedRows
SELECT 'Actual Table', * FROM [Order Details] WHERE ProductID = 11
```

## 04_MERGE.sql
```sql
USE Northwind
GO
-- create the temporary tables to demonstrate the merge operation
DECLARE @merge_target TABLE (
	CustomerID INT PRIMARY KEY,
	Name VARCHAR(50),
	Status VARCHAR(20),
	LastUpdated Date)
DECLARE @merge_source TABLE (
	CustomerID INT PRIMARY KEY,
	Name VARCHAR(50),
	Status VARCHAR(20))
-- insert examples values into the tables for the merge operation
INSERT INTO @merge_target (CustomerID, Name, Status, LastUpdated)
VALUES
	(1,'Alice','Active','2025-01-01'),
	(2,'Bob','Inactive','2025-02-01'),
	(4,'David','Active','2025-03-01'),
	(5,'Eve','Active','2025-04-01'),
	(7,'Sam','Active','2025-02-02')
INSERT INTO @merge_source (CustomerID, Name, Status)
VALUES
	(1,'Alice Smith','Active'),
	(2,'Bob','Suspended'),
	(3,'Charlie','Active'),
	(6,'Frank','Active'),
	(7,'Sam','Active') -- even though for customer 7, nothing is different, 'when matched' blindly updates ALL records. This is the merge "gotcha" and one of the reasons MERGE may wish to be avoided because it will update the update date even if no change. There are ways around this like making use of INTERSECT or a comparison between the involved columns & also NULL check to only update that record if the values are different.
SELECT 'pre-Merge target', * FROM @merge_target
SELECT 'pre-Merge source', * FROM @merge_source
-- merge using customerID as the match column.
MERGE @merge_target as t
USING @merge_source as s ON t.CustomerID = s.CustomerID
WHEN MATCHED THEN UPDATE SET t.Name = s.Name, t.Status = s.Status, t.LastUpdated = GETDATE() -- target Name and Status will be updated to match source
WHEN NOT MATCHED BY TARGET THEN INSERT (CustomerID, Name, Status, LastUpdated) VALUES (s.CustomerID, s.Name, s.Status, GETDATE()) -- insert customers customers from source into target which are missing from target
WHEN NOT MATCHED BY SOURCE THEN UPDATE SET t.Status = 'Deleted', t.LastUpdated = GETDATE()
-- !!DANGER!! HARD-DELETION EXAMPLE: "WHEN NOT MATCHED BY SOURCE THEN DELETE" -- Hard-delete customers which do NOT exist in the source
; -- end of merge statement
SELECT 'post-Merge target (see updates)', * FROM @merge_target ORDER BY CustomerID
SELECT 'post-Merge source (no changes)', * FROM @merge_source ORDER BY CustomerID
```

## 05_TRY_CATCH.sql
```sql
-- Example: simple fundamental - try catch can allow the script to continue even if there's an error.
BEGIN TRY
    SELECT Discount, 10/Discount, *
	FROM [Order Details]
END TRY
BEGIN CATCH
    PRINT 'Oops, division by zero happened!';
	SELECT TOP 5 'Catch Select', * FROM [Order Details]; -- Semi-colon IS needed after this select statement, otherwise the THROW keyword will not work as SQL will silently IGNORE the THROW keyword.
	THROW -- you don't always need to throw an error. Omit if you wish the script to continue and you can catch (handle the error)
	PRINT 'If THROW was always effective, you would not see this message. Semi-colon must terminate SELECT statements in the catch block.' -- This runs. Script continues.
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
	('TOMSP','Toms Spezialitten',0),
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
```

## 06_TABLE_TEMP_VS_VARIABLE.sql
```sql
USE Northwind
GO -- Batch 1
BEGIN TRY
	DROP TABLE #MyTemp;
END TRY
BEGIN CATCH
END CATCH
-- Batch 1: Create and populate both tables
DECLARE @MyTable TABLE (ID INT, Name VARCHAR(50)); -- Table variable: Batch-scoped
CREATE TABLE #MyTemp (ID INT IDENTITY PRIMARY KEY, Name VARCHAR(50)); -- Temp table: Session-scoped

-- Insert sample data
INSERT INTO @MyTable VALUES (1, 'Alice'), (2, 'Bob'); -- no need to specify columns if inserting a value for each column.
INSERT INTO #MyTemp (Name) VALUES ('Alice'), ('Bob'); -- IDENTITY will auto-increment and does not need to be specified.

-- Query both (should work)
SELECT 'Table Variable' AS TableType, * FROM @MyTable;
SELECT 'Temp Table' AS TableType, * FROM #MyTemp;

GO  -- End of Batch 1: @MyTable is destroyed here; comment out to see behavior

-- Batch 2: Try to query again
SELECT 'Table Variable' AS TableType, * FROM @MyTable; -- This will error as the variable is destroyed by keyword "GO"
SELECT 'Temp Table' AS TableType, * FROM #MyTemp; -- This works

-- Clean up temp table
DROP TABLE #MyTemp;

GO -- End of Batch 2: New example of rollback.

-- Table variable  session scope, no stats, no transaction rollback, minimal logging
DECLARE @T TABLE (ID int PRIMARY KEY, Val money);
INSERT @T VALUES (1, 100), (2, 200);
SELECT 'Select Initial @T', * FROM @T;

-- Temp table  session or global (# vs ##), has statistics, participates in transactions
CREATE TABLE #Temp (ID int PRIMARY KEY, Val money);
INSERT #Temp VALUES (1, 100), (2, 200);

BEGIN TRAN;
DELETE #Temp; -- rolls back
DELETE @T; -- does NOT roll back (@T variable get deleted even if this transaction is rolled back -- comment out to see behavior
ROLLBACK;
SELECT 'Select Post #Temp', * FROM #Temp;  -- still empty
SELECT 'Select Post @T', * FROM @T;     -- still has rows
DROP TABLE #Temp;
```

## 07_WINDOW_FUNCTIONS.sql
```sql
-- Table variables (@table) vs Temp tables (#table)  scope, stats, transactions
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- PARTITION BY essentially means "restart the calculation for the distinct values in the following column"
-- OVER is the keyword SQL uses to signal a new "window" function
-- Common window functions: Row_Number, Rank, Dense Rank, Ntile
SELECT 
	CustomerID,
	OrderDate,
	Freight,
	ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Rn, -- this gives an incrementing count of orders BY CUSTOMER
	-- Rank means how many people are ahead of me. if 10 people are tied for Rank 1, then they are all Rank 1 and the next person in line would be rank 11 (2-10 would be skipped as values due to the ties).
	RANK() OVER (ORDER BY Freight DESC) AS Rank, -- no ORDER BY clause in the query, but SQL Server will very often return rows sorted by Freight DESC because the ranking calculation requires the rows to be pre-ordered  this visual sorting in the result set is a common (and confusing) side-effect, not a guarantee; always add ORDER BY in the main query if presentation order matters.
	RANK() OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS RankWPartition, -- rank with partition by (restart the calculation FOR each customer thus ranking the Freight for EACH customer themselves, and not against the entire dataset)
	DENSE_RANK() OVER (ORDER BY Freight DESC) AS DenseRank, -- Dense Rank has to do with ties. it "compresses" the rank number so a number is never "missed", thus no gap is created. e.g. if the first tie occurs at 350 and two people are tied for that rank 350, the next dense rank is 351.
	DENSE_RANK() OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS DenseRankWPartition, -- Dense Rank with partition (restart the calculation FOR each customer thus ranking the Freight for EACH customer themselves, and not against the entire dataset)
	NTILE(5) OVER (ORDER BY Freight DESC) AS NTileEx, -- what NTILE (from play on word "percentile" or "quartile"), is the Freight value in? if NTILE(4), this is quartile. So, the higher values would be in a higher quartile if DESC.
	NTILE(5) OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS NTileEx, -- same as before, but limit the calculation to each customer, so the customers orders are "competing" against themselves, not against other customer orders.
	SUM(Freight) OVER (PARTITION BY CustomerID ORDER BY OrderDate -- order by essential because it specifies the order in which the running total is to be added upon itself
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW --needed to handle items which have the same customer id and date, otherwise, only the first instance is added to the running total
		) AS RunningTotal,
	LAG(Freight, 2) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as TwoAgo, -- See a window into what the freight was two orders ago
	LEAD(Freight, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as OneAhead -- See a window into what the freight is 1 order ahead
FROM Orders
-- WHERE CustomerID = 'QUICK' -- adding a where clause here would effect the window functions overall dataset which they are looking at, thus changing the relative values the window functions resolve to as they are relative to the overall dataset
ORDER BY CustomerID, OrderDate DESC
```

## 08_PIVOT_UNPIVOT.sql
```sql
-- Sales by year/quarter with a LEFT JOIN & a PIVOT
select * from (
	select YEAR(o.OrderDate) Yr, DATEPART(quarter, o.OrderDate) Qtr, sum(od.unitprice) as total
	from Orders o
	left join [Order Details] od on o.OrderID = od.OrderID
	group by YEAR(o.OrderDate), DATEPART(quarter, o.OrderDate)
) src -- you must structure the original query as a SUBQUERY because PIVOT must occur IMMEDIATELY after the FROM clause. Can't do that otherwise, and you need the aggregate functions as well, so this format is going to be standard when using PIVOT.
PIVOT (
	SUM(total) FOR Qtr IN ([1], [2], [3], [4]) -- sum seems redundant here (since SUM aggregrate function is in the original select query, but pivot requires a calculation. can use min or max for testing if it feels less redundant
) p
```

## 09_RECURSIVE_CTEs.sql
```sql
-- Setup circular manager scenario if not already done
-- INSERT SOME EXAMPLE EMPLOYEES FOR CIRCULAR MANAGER
-- INSERT INTO Employees (
-- 	LastName, FirstName
-- )
-- VALUES ('Doe', 'John'), ('Doe', 'Jane')
-- 
-- -- SET JOHN DOE SUPER TO JANE DOE
-- BEGIN TRAN
-- UPDATE e
-- SET ReportsTo = 11
-- FROM Employees e
-- WHERE LastName = 'Doe' AND FirstName = 'John'
-- COMMIT
-- 
-- -- SET JANE DOE SUPER TO JOHN DOE
-- BEGIN TRAN
-- UPDATE e
-- SET ReportsTo = 10
-- FROM Employees e
-- WHERE LastName = 'Doe' AND FirstName = 'Jane'
-- COMMIT

SELECT EmployeeID, LastName, FirstName, ReportsTo FROM Employees

GO

-- Recursive CTE must be constructed like so:
-- WITH statment signaling start of the CTE
-- Apex of the Org (manager who has no manager)
-- UNION ALL
-- Recursion through the rest, indicated by INNER JOIN to the name of the CTE (OrgChart in this case)
-- SELECT after that with an optional MaxRecursion option. E.g. if you have EE 3 reporting to 2, who reports to 1, but recursion is only at 2, it won't catch the full genealogy and will end in error.

-- Typical Org chart query (recursive CTE)
WITH OrgChart AS (
    -- 1. Anchor: you MUST have at least one starting row
    SELECT EmployeeID, ReportsTo, FirstName + ' ' + LastName AS Name, 1 AS Lvl
    FROM Employees
    WHERE ReportsTo IS NULL                     -- top boss(es)

    UNION ALL

    -- 2. Recursive part
    SELECT e.EmployeeID, e.ReportsTo, e.FirstName + ' ' + e.LastName, oc.Lvl + 1
    FROM Employees e
    INNER JOIN OrgChart oc ON e.ReportsTo = oc.EmployeeID
)
SELECT * FROM OrgChart
OPTION (MAXRECURSION 100);

GO

-- Advanced Org Chart to detect circular managers (recursive CTE)
WITH OrgChart2 AS (
    SELECT 
        EmployeeID,
        ReportsTo AS ManagerID,
        FirstName + ' ' + LastName AS Name,
        1 AS Level,
        CAST(EmployeeID AS varchar(max)) AS Path
    FROM Employees

    UNION ALL

    SELECT 
        e.EmployeeID,
        e.ReportsTo,
        e.FirstName + ' ' + e.LastName,
        oc.Level + 1,
        oc.Path + '.' + CAST(e.EmployeeID AS varchar(10))
    FROM Employees e
    INNER JOIN OrgChart2 oc ON e.ReportsTo = oc.EmployeeID
    WHERE oc.Level < 30
),
Ranked AS (
    SELECT 
        Level,
        EmployeeID,
        ManagerID,
        Name,
        Path,
        ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY Level DESC) AS rn
    FROM OrgChart2
)
SELECT 
    Level,
    EmployeeID,
    ManagerID,
    Name,
    Path + 
      CASE WHEN Level >= 15 THEN ' (LOOP DETECTED)' ELSE '' END AS Path
FROM Ranked
WHERE rn = 1
ORDER BY EmployeeID;