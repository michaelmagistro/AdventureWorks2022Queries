USE AdventureWorks2022
GO

-- Step 1: Create one real duplicate email (same email for two different people)
BEGIN TRAN;
INSERT INTO Person.EmailAddress (BusinessEntityID, EmailAddress, rowguid, ModifiedDate)
VALUES 
(1, 'ken0@adventure-works.com', NEWID(), GETDATE()),   -- Ken Sánchez original
(2, 'ken0@adventure-works.com', NEWID(), GETDATE());  -- Terri Duffy now has same email → duplicate
COMMIT;   -- remove COMMIT if you want to rollback later
GO

BEGIN TRAN;
;WITH CTE AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY p.EmailAddress ORDER BY EmailAddressId) Rn
	FROM Person.EmailAddress p
)
-- DELETE FROM CTE WHERE Rn > 1
SELECT Rn, * FROM CTE where Rn > 1;
ROLLBACK
SELECT TOP 5 * FROM Person.EmailAddress;