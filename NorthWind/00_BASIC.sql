USE Northwind
GO
-- basic queries to grasp the datbase structure
select top 10 * from Employees
select top 10 * from Customers
select top 10 * from Orders
select top 10 * from [Order Details]
select top 10 * from Territories
select top 10 * from Region
select top 10 * from Products
select top 10 * from EmployeeTerritories
-- some basic joins
-- Orders & Details
SELECT TOP 10 *
FROM Orders o
LEFT JOIN [Order Details] od on o.OrderID = od.OrderID
-- employees and territories
SELECT TOP 100 et.*, e.*
FROM Employees e
LEFT JOIN EmployeeTerritories et on e.EmployeeID = et.EmployeeID
-- check territories for duplicates
SELECT COUNT(TerritoryID)-COUNT(DISTINCT(TerritoryID)) FROM EmployeeTerritories -- 0 dupes
-- check customers for duplicate last names
SELECT COUNT(ContactName)-COUNT(DISTINCT(ContactName)) FROM Customers -- 0 dupes
-- check orders for duplicate address
SELECT COUNT(ShipAddress)-COUNT(DISTINCT(ShipAddress)) FROM Orders -- 741 dupes