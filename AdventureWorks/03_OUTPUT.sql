USE AdventureWorks2022;

GO
-- Output the changes directly to the client using 'output'. Use tran + rollback to avoid changes
BEGIN TRAN
UPDATE Production.Product
SET ListPrice = ListPrice * 1.10
OUTPUT
	INSERTED.ProductID, DELETED.ListPrice as Price_Old, INSERTED.ListPrice as Price_New
	WHERE ProductID IN (707, 708)
ROLLBACK
-- view that no changes effectuated to table, due to rollback, and despite output showing the new values
SELECT ProductID, ListPrice FROM Production.Product WHERE ProductID IN (707, 708)

GO
-- Output to TABLE variable, instead of to the client
DECLARE @ChangedPrices TABLE (ProductID INT, Price_Old MONEY, Price_New MONEY);
BEGIN TRAN
UPDATE Production.Product
SET ListPrice = ListPrice * 1.10
OUTPUT
	INSERTED.ProductID, DELETED.ListPrice as Price_Old, INSERTED.ListPrice as Price_New
	INTO @ChangedPrices
	WHERE ProductID IN (707, 708);
ROLLBACK
-- view the var
SELECT * FROM @ChangedPrices
-- view that no changes effectuated to table, due to rollback, and despite output showing the new values
SELECT ProductID, ListPrice FROM Production.Product WHERE ProductID IN (707, 708)

GO
-- 3. OUTPUT with DELETE (capture rows before they disappear)
-- Need to choose a better example for a table without a foreign key constraint
DECLARE @Deleted TABLE (
    ProductID   INT,
    Name        NVARCHAR(50),
    ListPrice   MONEY
);

BEGIN TRAN;
DELETE Production.Product
OUTPUT DELETED.ProductID, DELETED.Name, DELETED.ListPrice
INTO @Deleted
WHERE ProductID = 999;   -- safe - no such product

-- If you want to actually test with a real row, use a known zero-price product or create a test row first
ROLLBACK;

SELECT * FROM @Deleted;   -- shows captured deleted rows