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

-- Table variable – session scope, no stats, no transaction rollback, minimal logging
DECLARE @T TABLE (ID int PRIMARY KEY, Val money);
INSERT @T VALUES (1, 100), (2, 200);
SELECT 'Select Initial @T', * FROM @T;

-- Temp table – session or global (# vs ##), has statistics, participates in transactions
CREATE TABLE #Temp (ID int PRIMARY KEY, Val money);
INSERT #Temp VALUES (1, 100), (2, 200);

BEGIN TRAN;
DELETE #Temp; -- rolls back
DELETE @T; -- does NOT roll back (@T variable get deleted even if this transaction is rolled back -- comment out to see behavior
ROLLBACK;
SELECT 'Select Post #Temp', * FROM #Temp;  -- still empty
SELECT 'Select Post @T', * FROM @T;     -- still has rows
DROP TABLE #Temp;