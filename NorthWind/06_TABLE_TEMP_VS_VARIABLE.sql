-- Table variables (@table) vs Temp tables (#table) – scope, stats, transactions
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE
SELECT 
	CustomerID, 
	OrderDate,
	Freight,
	ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Rn, -- this gives an incrementing count of orders BY CUSTOMER
	-- Rank means how many people are ahead of me. if 10 people are tied for Rank 1, then they are all Rank 1 and the next person in line would be rank 11 (2-10 would be skipped as values due to the ties).
	RANK() OVER (ORDER BY Freight DESC) AS Rank, -- no ORDER BY clause in the query, but SQL Server will very often return rows sorted by Freight DESC because the ranking calculation requires the rows to be pre-ordered – this visual sorting in the result set is a common (and confusing) side-effect, not a guarantee; always add ORDER BY in the main query if presentation order matters.
	-- Dense Rank has to do with ties. it "compresses" the rank number so a number is never "missed", thus no gap is created. e.g. if the first tie occurs at 350 and two people are tied for that rank 350, the next dense rank is 351.
	DENSE_RANK() OVER (ORDER BY Freight DESC) AS DenseRank
FROM Orders
ORDER BY Freight DESC

-- get a window into what the running freight total is for each customer
SELECT CustomerID, 
OrderDate,
Freight,
SUM(Freight) OVER (
	PARTITION BY CustomerID
	ORDER BY OrderDate
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) --needed to handle items which have the same customer id and date, otherwise, only the first instance is added to the running total
FROM Orders
ORDER BY CustomerID, OrderDate DESC

-- See a window into what the freight was two orders ago.
SELECT CustomerID, 
OrderDate,
Freight,
LAG(Freight, 2) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as PrevOrder
FROM Orders
ORDER BY CustomerID, OrderDate DESC