-- Sales by year/quarter with a LEFT JOIN & a PIVOT
select * from (
	select YEAR(o.OrderDate) Yr, DATEPART(quarter, o.OrderDate) Qtr, sum(od.unitprice) as total
	from Orders o
	left join [Order Details] od on o.OrderID = od.OrderID
	group by YEAR(o.OrderDate), DATEPART(quarter, o.OrderDate)
) src -- you must structure the original query as a SUBQUERY because PIVOT must occur IMMEDIATELY after the FROM clause. Can't do that otherwise, and you need the aggregate functions as well, so this format is going to be standard when using PIVOT.
PIVOT (
	SUM(total) FOR Qtr IN ([1], [2], [3], [4]) -- sum seems redundant here (since SUM aggregrate function is in the original select query, but pivot requires a calculation. can use min or max for testing if it feels less redundant
) p