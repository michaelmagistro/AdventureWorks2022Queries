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