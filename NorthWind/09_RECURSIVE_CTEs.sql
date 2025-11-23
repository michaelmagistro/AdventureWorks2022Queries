-- Recursive CTEs (hierarchy/org chart, MAXRECURSION)
-- Org chart
WITH OrgChart AS (
	SELECT EmployeeID, ManagerID, Name, 1 AS Level
	FROM Employees WHERE ManagerID IS NULL

	UNION ALL

	SELECT e.EmployeeID, e.ManagerID, e.Name, Level + 1
	FROM Employees e
	INNER JOIN OrgChart o ON e.ManagerID = o.EmployeeID
)
SELECT * FROM OrgChart OPTION (MAXRECURSION 100)  -- important!