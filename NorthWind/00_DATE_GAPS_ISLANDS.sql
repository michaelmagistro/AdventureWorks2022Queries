-- with CTE -- use instead of subqueries for readability and able to re-use the same subquery (the CTE) multiple times
WITH Src AS (
    SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
    FROM Orders
)
SELECT 
    MIN(OrderDay) AS PeriodStart,
    MAX(OrderDay) AS PeriodEnd,
    COUNT(*) AS OrdersInPeriod,
    DATEDIFF(DAY, MIN(OrderDay), MAX(OrderDay)) + 1 AS TotalCalendarDays
FROM (
    SELECT OrderDay,
           DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS Grp
    FROM Src
) x
GROUP BY Grp
ORDER BY PeriodStart;

-- without CTE for understanding
SELECT
    MIN(OrderDay) AS PeriodStart,
    MAX(OrderDay) AS PeriodEnd,
    COUNT(*) AS OrdersInPeriod,
    DATEDIFF(DAY, MIN(OrderDay), MAX(OrderDay)) + 1 AS TotalCalendarDays
FROM (
    SELECT OrderDay
    , DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS Grp
    FROM (
        SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
        FROM Orders
    ) o
) x
GROUP BY Grp
ORDER BY PeriodStart;

-- granular dissection for understanding & accuracy
SELECT OrderDay
-- , DATEADD(WEEK,1,GetDate()) AS DateAddEx
-- , ROW_NUMBER() OVER (ORDER BY OrderDay) AS RowPos -- give each distinct date a rank ascending
-- , DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS PeriodStartReverse
-- ,OrderDay
, -ROW_NUMBER() OVER (ORDER BY OrderDay) AS RowNeg  -- give each distinct date a rank descending (DISTINCT in the FROM statement)
, DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDay), OrderDay) AS PeriodStart
    -- based off of the distinct date values, and using row_number as a clever method, we are able to assign a "group" by assigning a "rank" to each non-blank date. DATEADD becomes "DATESUBSTRACT" due to to "-ROW_NUMBER"
    -- if the dates are out of order in the table, that's ok, as the row_number OVER window has the ORDER BY clause.
FROM (
    SELECT DISTINCT CAST(OrderDate AS date) AS OrderDay
    FROM Orders
) o

select cast(orderdate as date) from orders