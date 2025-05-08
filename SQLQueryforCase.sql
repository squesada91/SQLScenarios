USE [v-stevenq]; -- db creation to host my fact table
GO


/* ++++++++++++++++++++++++++++++++++++++++ Creation of the fctSales table ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists

IF OBJECT_ID('dbo.FctSales','U') IS NOT NULL
	DROP TABLE dbo.FctSales;
GO 


WITH FctSales AS (
	SELECT
		SOH.SalesOrderID
		,FORMAT(SOH.OrderDate, 'yyyy-MM-dd') as OrderDate
		,C.CustomerID
		,C.TerritoryID
		,P.ProductID
		--,P.Name AS 'ProductName'
		,PC.ProductCategoryID
		,PS.ProductSubcategoryID
		,SOD.UnitPrice
		,SOD.OrderQty
		,CAST(SOD.LineTotal as decimal(7,2)) as LineTotal

	FROM
		AdventureWorks2022.Sales.SalesOrderHeader SOH
		JOIN AdventureWorks2022.Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
		JOIN AdventureWorks2022.Production.Product P ON SOD.ProductID = P.ProductID
		JOIN AdventureWorks2022.Production.ProductSubCategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
		JOIN AdventureWorks2022.Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
		JOIN AdventureWorks2022.Sales.Customer C ON C.CustomerID = SOH.CustomerID
	
	WHERE
	OrderDate > '2012-05-31' -- Captures last 3 years data
)

SELECT 
	* 
INTO 
	dbo.FctSales
FROM 
	FctSales 





/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimDate ++++++++++++++++++++++++++++++++++++++++ */


--Drop if it already exists

IF OBJECT_ID('dbo.DimDate','U') IS NOT NULL
	DROP TABLE dbo.DimDate;
GO 

-- Create the DimDate table

--This CTE will generate date ranges between the min and max order date from fctSales table 
With DateSequence AS (
	SELECT
		CAST('2012-05-01' AS DATE) AS DateValue  --Starting from the first day of the first month of orders available data
	UNION ALL
	SELECT 
		DATEADD(DAY, 1, DateValue)
	FROM DateSequence
	WHERE
		DateValue <= '2014-06-30' --Max order date

)

	SELECT 
		DateValue as Date
		,DATENAME(WEEKDAY, Datevalue) AS DayName
		,DATEPART(DAY, DateValue) AS Day
		,DATEPART(MONTH, DateValue) AS Month
		,DATENAME(MONTH, DateValue) AS MonthName
		,DATEPART(YEAR, DateValue) AS Year
		,DATEPART(QUARTER, Datevalue) AS Quarter
	INTO 
		dbo.DimDate
	FROM
		DateSequence
	OPTION (MAXRECURSION 0);



/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimCustomer ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists
IF OBJECT_ID('dbo.DimCustomer','U') IS NOT NULL 
	DROP TABLE dbo.DimCustomer;
GO

SELECT
	c.CustomerID
	,c.TerritoryID
INTO
	dbo.DimCustomer
FROM	
	AdventureWorks2022.Sales.Customer c;


/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimProduct ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists

IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL 
	DROP TABLE dbo.DimProduct;
GO

SELECT 
	p.ProductID
	,p.Name
	,p.ProductNumber
	,p.Color
	,p.StandardCost
	,p.ListPrice
	,p.Size
	,p.Weight
	,pc.ProductCategoryID
	,ps.ProductSubcategoryID
INTO 
	dbo.DimProduct
FROM 
	AdventureWorks2022.Production.Product p 
	LEFT JOIN AdventureWorks2022.Production.ProductSubCategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
	JOIN AdventureWorks2022.Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID


/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimProductCategory ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists	

IF OBJECT_ID('dbo.DimCategory','U') IS NOT NULL 
	DROP TABLE dbo.DimCategory;
GO

SELECT 
	pc.ProductCategoryID
	,pc.Name
INTO
	dbo.DimCategory
FROM
	 AdventureWorks2022.Production.ProductCategory pc

/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimProductSubCategory ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists	

IF OBJECT_ID('dbo.DimSubCategory','U') IS NOT NULL 
	DROP TABLE dbo.DimSubCategory;
GO

SELECT 
	ps.ProductSubcategoryID
	,ps.Name
	,ps.ProductCategoryID
	
INTO
	dbo.DimSubCategory
FROM
	 AdventureWorks2022.Production.ProductSubcategory ps



/* ++++++++++++++++++++++++++++++++++++++++ Creation of DimLocation ++++++++++++++++++++++++++++++++++++++++ */

--Drop if it already exists	

IF OBJECT_ID('dbo.DimLocation','U') IS NOT NULL 
	DROP TABLE dbo.DimLocation;
GO

SELECT 
	st.TerritoryID
	,st.Name
	,st.CountryRegionCode

INTO
	dbo.DimLocation
FROM 
	AdventureWorks2022.Sales.SalesTerritory st


/* ++++++++++++++++++++++++++++++++++++++++ Altering tables to add PK's and FK's ++++++++++++++++++++++++++++++++++++++++ */

----- PRIMARY KEYS -----

--PK DimCustomer
ALTER TABLE dbo.DimCustomer
ADD CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerID);

--PK DimProduct
ALTER TABLE dbo.DimProduct
ADD CONSTRAINT PK_DimProduct PRIMARY KEY (ProductID);

--PK DimDate
ALTER TABLE dbo.DimDate
ADD CONSTRAINT PK_DimDate PRIMARY KEY (Date);

--PK DimCategory
ALTER TABLE dbo.DimCategory
ADD CONSTRAINT PK_DimCategory PRIMARY KEY (ProductCategoryID);

--PK DimLocation
ALTER TABLE dbo.DimLocation
ADD CONSTRAINT PK_DimLocation PRIMARY KEY (TerritoryID);

----- FOREIGN KEYS TO FCTSALES-----

--FK to dimCustomer
ALTER TABLE dbo.FctSales
ADD CONSTRAINT FK_FctSales_Customer
FOREIGN KEY (CustomerID) REFERENCES dbo.DimCustomer(CustomerID);

--FK to dimProduct
ALTER TABLE dbo.FctSales
ADD CONSTRAINT FK_FctSales_Product
FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct(ProductID);

--FK to DimDate
ALTER TABLE dbo.FctSales
ADD CONSTRAINT FK_FctSales_Date
FOREIGN KEY (OrderDate) REFERENCES dbo.DimDate(Date);