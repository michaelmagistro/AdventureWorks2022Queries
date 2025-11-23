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