# NorthWind SQL Queries Concise Summary

## 00_BASIC.sql
**Concept:** Basic table explorations and simple joins to understand database structure; duplicate checks.
```sql
SELECT TOP 10 * FROM Employees;
SELECT TOP 10 * FROM Customers;
-- Joins
SELECT TOP 10 * FROM Orders o LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID;
-- Dupe checks
SELECT COUNT(ShipAddress) - COUNT(DISTINCT(ShipAddress)) FROM Orders; -- 741 dupes
```
## 00_DATE_GAPS_ISLANDS.sql
**Concept:** Identify date gaps/islands using ROW_NUMBER() for grouping consecutive order dates.
```sql
WITH Src AS (SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay FROM Orders)
SELECT MIN(OrderDay) AS PeriodStart, MAX(OrderDay) AS PeriodEnd,
       COUNT(*) AS OrdersInPeriod
FROM (SELECT OrderDay, DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS Grp
      FROM Src) x
GROUP BY Grp ORDER BY PeriodStart;
```
## 00_DELETE_DUPLICATES.sql
**Concept:** Detect and delete duplicates using CTE with ROW_NUMBER() partitioned by key columns.
```sql
WITH CTE AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY FirstName, LastName ORDER BY LastName, FirstName) AS Rn
             FROM Employees)
SELECT * FROM CTE WHERE Rn > 1;
-- DELETE FROM CTE WHERE Rn > 1;
```
## 00_EXCEPT_NOT_EXISTS_NOT_IN.sql
**Concept:** Compare set operations for excluding rows; NOT EXISTS handles NULLs better than NOT IN; EXCEPT pitfalls with NULLs.
```sql
-- NOT EXISTS: Customers without orders
SELECT CustomerID FROM Customers c WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);
-- EXCEPT drops NULL if present in right
SELECT val FROM (VALUES ('ABC'), (NULL)) A(val) EXCEPT SELECT val FROM (VALUES ('XYZ'), (NULL)) B(val); -- 'ABC' only
```
## 00_INSERT_VALUES_MULTIROW.sql
**Concept:** Insert multiple rows in one VALUES statement into temp table.
```sql
INSERT INTO #Products (ProductName, SupplierID, CategoryID, UnitPrice, UnitsInStock)
VALUES ('Organic Coffee', 1, 1, 18.50, 200),
       ('Herbal Tea', 2, 2, 12.00, 150);
SELECT * FROM #Products;
DROP TABLE #Products;
```
## 00_ISNULL_VS_COALESCE.sql
**Concept:** COALESCE for multi-fallback NULL handling (flexible types); ISNULL limited to two args, type issues.
```sql
SELECT COALESCE(ShipRegion, ShipCountry, 'Unknown') AS Using_COALESCE,
       ISNULL(ShipRegion, 'Unknown') AS Using_ISNULL
FROM Orders;
-- ISNULL truncates if types mismatch
SELECT ISNULL(ShipRegion, 'Unknown Location') FROM Orders WHERE ShipRegion IS NULL; -- Truncated
```
## 00_STRING_AGG.sql
**Concept:** Aggregate strings with STRING_AGG; supports sorting via WITHIN GROUP; skips NULLs.
```sql
SELECT c.CategoryName, STRING_AGG(p.ProductName, ', ') AS Products,
       STRING_AGG(p.ProductName, ', ') WITHIN GROUP (ORDER BY p.ProductName) AS SortedProducts
FROM Products p JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName ORDER BY c.CategoryName;
```
## 01_TOP_TIES_PERCENT.sql
**Concept:** TOP with TIES for ranking ties; PERCENT for top N% by count.
```sql
SELECT TOP 10 WITH TIES Country FROM Customers ORDER BY Country; -- Includes ties
SELECT TOP 10 PERCENT * FROM Orders ORDER BY Freight DESC; -- Top 10% rows
```
## 02_SELECT_VS_SET.sql
**Concept:** SET for simple var assignment; SELECT for multi-row or column assignment (last non-NULL).
```sql
DECLARE @someVar VARCHAR(50); SET @someVar = 5;
SELECT @someVar = ContactName FROM Customers WHERE ContactName = 'Maria Anders'; -- From column
SELECT @someVar = ContactName FROM Customers; -- Last non-NULL (beware no WHERE)
```
## 03_OUTPUT.sql
**Concept:** OUTPUT clause to capture inserted/deleted values during DML; into table vars.
```sql
UPDATE Customers SET ContactName = 'Anna Trujilla'
OUTPUT INSERTED.ContactName AS NewName, DELETED.ContactName AS OldName
WHERE ContactName = 'Ana Trujillo';

DECLARE @Deleted TABLE (OrderID INT, ProductID INT);
DELETE [Order Details] OUTPUT DELETED.OrderID, DELETED.ProductID INTO @Deleted
WHERE ProductID = 11;
```
## 04_MERGE.sql
**Concept:** MERGE for upsert (update/insert/delete) based on match; watch blind updates.
```sql
MERGE @target AS t USING @source AS s ON t.CustomerID = s.CustomerID
WHEN MATCHED THEN UPDATE SET t.Name = s.Name, t.Status = s.Status
WHEN NOT MATCHED BY TARGET THEN INSERT (CustomerID, Name, Status) VALUES (s.CustomerID, s.Name, s.Status)
WHEN NOT MATCHED BY SOURCE THEN UPDATE SET t.Status = 'Deleted';
```
## 05_TRY_CATCH.sql
**Concept:** TRY-CATCH for error handling; THROW to re-raise; handles constraints.
```sql
BEGIN TRY
    SELECT 10 / Discount FROM [Order Details]; -- Div by zero
END TRY
BEGIN CATCH
    PRINT 'Division by zero!'; THROW;
END CATCH;

BEGIN TRY
    DELETE TOP(5) o FROM Orders o ORDER BY OrderDate DESC; -- FK fail
END TRY
BEGIN CATCH
    THROW 50000, 'Cannot delete orders with details.', 1;
END CATCH;
```
## 06_TABLE_TEMP_VS_VARIABLE.sql
**Concept:** Table vars (@) batch-scoped, no rollback/stats; Temp (#) session-scoped, transaction-aware.
```sql
DECLARE @T TABLE (ID INT, Val MONEY); INSERT @T VALUES (1, 100);
CREATE TABLE #Temp (ID INT, Val MONEY); INSERT #Temp VALUES (1, 100);

BEGIN TRAN; DELETE @T; DELETE #Temp; ROLLBACK; -- @T keeps rows, #Temp empty
```
## 07_WINDOW_FUNCTIONS.sql
**Concept:** Window funcs for ranking/aggregates without grouping; PARTITION BY restarts.
```sql
SELECT CustomerID, Freight,
       ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Rn,
       RANK() OVER (ORDER BY Freight DESC) AS Rank,
       DENSE_RANK() OVER (ORDER BY Freight DESC) AS DenseRank,
       NTILE(4) OVER (ORDER BY Freight DESC) AS Quartile,
       SUM(Freight) OVER (PARTITION BY CustomerID ORDER BY OrderDate ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM Orders ORDER BY CustomerID, OrderDate;
```
## 08_PIVOT_UNPIVOT.sql
**Concept:** PIVOT to transform rows to columns via aggregate.
```sql
SELECT * FROM (
    SELECT YEAR(OrderDate) Yr, DATEPART(quarter, OrderDate) Qtr, SUM(UnitPrice) AS Total
    FROM Orders o JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY YEAR(OrderDate), DATEPART(quarter, OrderDate)
) src PIVOT (SUM(Total) FOR Qtr IN ([1], [2], [3], [4])) p;
```
## 09_RECURSIVE_CTEs.sql
**Concept:** Recursive CTE for hierarchies (org chart); detect cycles with path tracking.
```sql
WITH OrgChart AS (
    SELECT EmployeeID, ReportsTo, FirstName + ' ' + LastName AS Name, 1 AS Lvl
    FROM Employees WHERE ReportsTo IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.ReportsTo, e.FirstName + ' ' + e.LastName, oc.Lvl + 1
    FROM Employees e JOIN OrgChart oc ON e.ReportsTo = oc.EmployeeID
)
SELECT * FROM OrgChart OPTION (MAXRECURSION 100);