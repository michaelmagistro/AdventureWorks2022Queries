-- Example: STRING_AGG in Northwind database

SELECT TOP 4 * FROM Products
SELECT TOP 4 * FROM Categories
SELECT p.*, c.* FROM Products p JOIN Categories c ON p.CategoryID = c.CategoryID

-- show a string of all products per category group.
SELECT
    c.CategoryID, -- optional to include this. a column in select must be in group by, but a column in group by does not necessarily need to be in the select clause.
    c.CategoryName,
    STRING_AGG(p.ProductName, ', ') AS Products, -- string_agg (as the name implies) is an aggregate function. like count or sum etc. but -- concatenate for strings. Omiting this agg function will not cause the query to error.
    STRING_AGG(p.ProductName, ', ') WITHIN GROUP (ORDER BY p.ProductName) AS SortedProducts -- you can sort within the concatenated string itself using WITHIN GROUP
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY c.CategoryName;

-- NULL handling: Skips NULLs automatically
SELECT STRING_AGG(val, ', ') AS Result
FROM (VALUES ('A'), (NULL), ('B')) AS t(val);  -- Returns 'A, B'

-- Key Notes:
-- Use WITHIN GROUP (ORDER BY) for sorted output.
-- Ignores NULLs; no duplicates unless DISTINCT added.
-- For older SQL, use STUFF + FOR XML PATH as alternative.