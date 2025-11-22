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