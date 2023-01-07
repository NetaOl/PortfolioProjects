use AdventureWorks2019

--Question 1 - Show products that were never purchased 
--             Show Columns: ProductID, Name (of product), Color, ListPrice, Size

select ProductID, Name, Color, ListPrice, Size
from Production.Product
where ProductID not in (select ProductID from Sales.SalesOrderDetail)
order by ProductID


-- Updates to complete before answering question 2

update sales.Customer
set PersonID = CustomerID
where CustomerID <= 290

update Sales.Customer
set PersonID = CustomerID+1700
where CustomerID >= 300 and CustomerID <= 350

update Sales.Customer
set PersonID = CustomerID+1700
where CustomerID >= 352 and CustomerID <= 701


--Question 2 - Show customers that have not placed any orders
--             Show columns: CustomerID, FirstName, LastName in ascending order
--             If there is missing data in columns FirstName and LastName - show value "Unknown"

select c.CustomerID, iif (p.firstname is null, 'Unknown', p.firstname ) as 'FirstName',
		iif (p.lastname is null, 'Unknown', p.lastname ) as 'LastName'
from Person.Person P
	 right join Sales.Customer c 
	 on p.BusinessEntityID = c.PersonID
     left join Sales.SalesOrderHeader SOH 
	 on c.CustomerID = SOH.CustomerID
where c.CustomerID not in (select CustomerID from Sales.SalesOrderHeader)
order by c.CustomerID


--Question 3 - how the 10 customers that have placed the most orders
--             Show columns: CustomerID, FirstName, LastName and the amount of orders in descending order

select c.CustomerID, p.FirstName, p.LastName, count(distinct soh.salesorderid) as 'OrderCount'
from Sales.SalesOrderHeader soh
right join Sales.Customer c on SOH.CustomerID = C.CustomerID
right join Person.Person p on c.PersonID = p.BusinessEntityID
group by c.CustomerID, p.FirstName, p.LastName
order by 'OrderCount' desc
offset 0 rows fetch next 10 rows only


--Question 4 - Show data regarding employees and their job titles
--             Show columns: FirstName, LastName, JobTitle, HireDate and the amount of employees that share the same job title

select p.FirstName, p.LastName, e.JobTitle, e.HireDate, 
	   count (e.jobtitle) over (partition by e.jobtitle) as 'JobTitleCount'
from HumanResources.Employee E
join Person.Person P
on e.BusinessEntityID = p.BusinessEntityID
group by p.FirstName, p.LastName, e.JobTitle, e.HireDate
order by e.JobTitle


--Question 5 - For every customer, show their most recent order date and the second most recent order date.
--             Show columns: SalesOrderID, CustomerID, LastName, FirstName, LastOrder, PreviousOrder

go
with CTE_1 
as (select SOH.salesorderid, C.customerid, P.lastname, P.firstname, SOH.orderdate as LastOrder,
	lag(SOH.orderdate) over(partition by SOH.customerid order by SOH.customerid ) as PreviosOrder
	from Sales.SalesOrderHeader SOH
	join Sales.Customer C 
	on SOH.CustomerID = C.CustomerID
	join Person.Person P
	on C.PersonID = P.BusinessEntityID)
select * from CTE_1 C1
where LastOrder = (select max(LastOrder)
					from CTE_1 C2
					where C1.CustomerID = C2.CustomerID)


--Question 6 - For every year, show the order with the highest total payment and which customer placed the order
--             Show columns: Year, SalesOrderID, LastName, FirstName, Total

select tbl1.OrderYear, tbl1.SalesOrderID, tbl1.LastName, tbl1.FirstName, tbl1.OrderTotal
from (select tbl.OrderYear, tbl.salesorderid, max(tbl.ordertotal) over (partition by tbl.OrderYear) as OrderTotal,
	  max(tbl.OrderTotal) over (partition by tbl.salesorderid) as MaxOrder, firstname, lastname
	  from(select year(SOH.orderdate) as OrderYear, SOD.salesorderid, sum(linetotal) as OrderTotal, p.firstname, p.lastname
			from Sales.SalesOrderDetail SOD join Sales.SalesOrderHeader SOH
											on SOD.SalesOrderID = SOH.SalesOrderID
											join Sales.Customer C 
											on SOH.CustomerID = C.CustomerID
											join Person.Person P 
											on C.PersonID = P.BusinessEntityID
		group by year(SOH.OrderDate), SOD.SalesOrderID, P.FirstName, P.LastName) tbl) tbl1
where tbl1.MaxOrder = tbl1.OrderTotal

--Question 7 - Show the number of orders for by month, for every year
--             Show Columns: Month and a column for every year

select *
from (select year(orderdate) as Year, month(orderdate) as Month, salesorderid
	  from Sales.SalesOrderHeader) O
	  pivot (count(salesorderid) for year in ([2011], [2012], [2013], [2014])) PVT
	  order by Month


--question 8 - Show employees sorted by their hire date in every department from most to least recent, name and hire date for the last employee hired before them 
--             and the number of days between the two hire dates
--             Show Columns: DepartmentName, EmployeeID, EmployeeFullName, HireDate, Seniority, PreviousEmpName, PreviousEmpHDate, DiffDays

go
with CTE_3 (Departmentname, EmployeeID, EmployeeFullName, HireDate, Seniority, PreviousEmpName, PreviousEmpDate, DiffDays) as
	(select D.Name, E.BusinessEntityID, CONCAT(P.firstname, ' ', p.LastName) as EmployeeFullName, E.HireDate, datediff(mm, E.HireDate, getdate()),
	lead (CONCAT(P.firstname, ' ', p.LastName)) over (partition by D.name order by E.hiredate desc),
	lead (E.HireDate) over(partition by D.name order by E.hiredate desc) as PreviousEmpDate,
	datediff(dd,E.HireDate, lead (E.HireDate) over(partition by D.name order by E.hiredate desc) )
	from HumanResources.Employee E
	join Person.Person P 
	on E.BusinessEntityID = P.BusinessEntityID
	join HumanResources.EmployeeDepartmentHistory EDH
	on P.BusinessEntityID = EDH.BusinessEntityID
	join HumanResources.Department D
	on EDH.DepartmentID = D.DepartmentID
	where EDH.EndDate is null)
select * from CTE_3
