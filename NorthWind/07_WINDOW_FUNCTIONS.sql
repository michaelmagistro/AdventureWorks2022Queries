-- Table variables (@table) vs Temp tables (#table) – scope, stats, transactions
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- PARTITION BY essentially means "restart the calculation for the distinct values in the following column"
-- OVER is the keyword SQL uses to signal a new "window" function
-- Common window functions: Row_Number, Rank, Dense Rank, Ntile
SELECT 
	CustomerID,
	OrderDate,
	Freight,
	ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Rn, -- this gives an incrementing count of orders BY CUSTOMER
	-- Rank means how many people are ahead of me. if 10 people are tied for Rank 1, then they are all Rank 1 and the next person in line would be rank 11 (2-10 would be skipped as values due to the ties).
	RANK() OVER (ORDER BY Freight DESC) AS Rank, -- no ORDER BY clause in the query, but SQL Server will very often return rows sorted by Freight DESC because the ranking calculation requires the rows to be pre-ordered – this visual sorting in the result set is a common (and confusing) side-effect, not a guarantee; always add ORDER BY in the main query if presentation order matters.
	RANK() OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS RankWPartition, -- rank with partition by (restart the calculation FOR each customer thus ranking the Freight for EACH customer themselves, and not against the entire dataset)
	DENSE_RANK() OVER (ORDER BY Freight DESC) AS DenseRank, -- Dense Rank has to do with ties. it "compresses" the rank number so a number is never "missed", thus no gap is created. e.g. if the first tie occurs at 350 and two people are tied for that rank 350, the next dense rank is 351.
	DENSE_RANK() OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS DenseRankWPartition, -- Dense Rank with partition (restart the calculation FOR each customer thus ranking the Freight for EACH customer themselves, and not against the entire dataset)
	NTILE(5) OVER (ORDER BY Freight DESC) AS NTileEx, -- what NTILE (from play on word "percentile" or "quartile"), is the Freight value in? if NTILE(4), this is quartile. So, the higher values would be in a higher quartile if DESC.
	NTILE(5) OVER (PARTITION BY CustomerID ORDER BY Freight DESC) AS NTileEx, -- same as before, but limit the calculation to each customer, so the customers orders are "competing" against themselves, not against other customer orders.
	SUM(Freight) OVER (PARTITION BY CustomerID ORDER BY OrderDate -- order by essential because it specifies the order in which the running total is to be added upon itself
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW --needed to handle items which have the same customer id and date, otherwise, only the first instance is added to the running total
		) AS RunningTotal,
	LAG(Freight, 2) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as TwoAgo, -- See a window into what the freight was two orders ago
	LEAD(Freight, 1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) as OneAhead -- See a window into what the freight is 1 order ahead
FROM Orders
-- WHERE CustomerID = 'QUICK' -- adding a where clause here would effect the window functions overall dataset which they are looking at, thus changing the relative values the window functions resolve to as they are relative to the overall dataset
ORDER BY CustomerID, OrderDate DESC