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