-- EXCEPT, NOT EXISTS and NOT IN

-- Example: Using NOT EXISTS (correlated subquery)
-- Find Customers who do not have any Orders.
SELECT CustomerID, CompanyName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);

GO

-- NOT IN: can only be used when you know there are no NULLS. NOT EXISTS is best for any dynamic queries.
SELECT CustomerID, CompanyName
FROM Customers c
WHERE CustomerID NOT IN (SELECT CustomerID from Orders)
-- NOT IN: This returns ONE row (as expected)
SELECT 'ABC' AS abc WHERE 'ABC' NOT IN ('XYZ', '123'); -- OK >> 'ABC'
-- NOT IN: This returns ZERO rows (even though 'ABC' isn't in the list), because NULL changes how the logic works
SELECT 'ABC' AS abc WHERE 'ABC' NOT IN ('XYZ', '123', NULL); -- NULL makes it UNKNOWN >> no rows
-- NOT EXISTS: This returns ONE row (as expected)
SELECT 'ABC' AS abc WHERE NOT EXISTS (SELECT 1 WHERE 'ABC' IN ('XYZ', '123')); -- OK >> 'ABC'
-- NOT EXISTS: This returns ONE row (as expected) even throug there's a NULL value.
SELECT 'ABC' AS abc WHERE NOT EXISTS (SELECT 1 WHERE 'ABC' IN ('XYZ', '123', NULL)); -- OK >> 'ABC'


-- EXCEPT returns distinct rows from the left query that are not present in the right query
-- EXCEPT pitfall with NULL keys: removes NULL from left if right has NULL
SELECT val FROM (VALUES ('ABC'), (NULL)) A(val)
EXCEPT
SELECT val FROM (VALUES ('XYZ'), (NULL)) B(val);   -- returns only 'ABC' (NULL is treated as a literal value and thus excluded)

-- NOT EXISTS keeps NULL because NULL = NULL is UNKNOWN (NOT EXISTS is preferred in real-world scenarios because EXCEPT can drop rows silently if NULLs represent "unknown" rather than a matchable value
SELECT val FROM (VALUES ('ABC'), (NULL)) A(val)
WHERE NOT EXISTS (
    SELECT 1 FROM (VALUES ('XYZ'), (NULL)) B(val) WHERE B.val = A.val
);   -- returns 'ABC' and NULL (NULL is treated as an UNKNOWN, and thus included in the result set)