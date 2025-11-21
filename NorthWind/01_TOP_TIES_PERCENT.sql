USE Northwind
GO
-- Top, Ties, Percent
SELECT * FROM Orders
-- with ties
SELECT TOP 10 WITH TIES Country FROM Customers ORDER BY Country -- order by statement is mandatory when using WITH TIES
-- percent - show the top N number of records using PERCENT
select TOP 10 PERCENT * from orders ORDER BY Freight DESC -- this is not finding the top percent based on some value, but rather on record count.