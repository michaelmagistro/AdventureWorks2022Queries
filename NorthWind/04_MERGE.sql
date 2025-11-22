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