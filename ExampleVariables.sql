USE AdventureWorks2022;
GO

-- Scalar Variable
-- declare simple int var
DECLARE @x as INT
set @x = 5
select @x
-- Table Variable
-- place values from a column into a var; not able to set var to an entire column. instead, must be a table and then insert vals.
DECLARE @y TABLE (firstName varchar(50))
insert into @y
select top 100 FirstName from Person.Person
select * from @y