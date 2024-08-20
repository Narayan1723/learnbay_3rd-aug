create database sqlproject;

use sqlproject;

create table product
(Product_ID varchar(max),Product_Name varchar(max),	Product_Category varchar(max),Product_Cost varchar(max),Product_Price varchar(max))

--Commands completed successfully.

select * from product;

bulk insert product
from'C:\nikhil\analyst project\project\sql\products.csv'
with (Fieldterminator=',', rowterminator='\n', firstrow=2)

--(35 rows affected)

select column_name,data_type
from information_schema.columns;

alter table product
alter column Product_ID char(2);

alter table product
alter column Product_Cost money;

alter table product
alter column Product_Price money;

select column_name,data_type
from information_schema.columns;

create table stores
(Store_ID varchar(max),	Store_Name varchar(max),Store_City varchar(max),Store_Location varchar(max),Store_Open_Date varchar(max));

--Commands completed successfully.

bulk insert stores
from'C:\nikhil\analyst project\project\sql\stores.csv'
with (Fieldterminator=',', rowterminator='\n', firstrow=2);

--(50 rows affected)

select * from stores;

select column_name,data_type
from information_schema.columns;

alter table stores
alter column Store_ID char(2);

alter table stores
alter column Store_Open_Date date;

--error--Conversion failed when converting date and/or time from character string.

update stores set Store_Open_Date=convert(date,Store_Open_Date,105);

--(50 rows affected)

--try again

alter table stores
alter column Store_Open_Date date;

--Commands completed successfully.

select column_name,data_type
from information_schema.columns;

--create table sales
drop table sales;

create table sales
(Sale_ID varchar(max),sale_Date varchar(max),Store_ID varchar(max),Product_ID varchar(max),Units varchar(max));

--Commands completed successfully.

bulk insert sales
from'C:\nikhil\analyst project\project\sql\sales.csv'
with (Fieldterminator=',', rowterminator='\n', firstrow=2);

--(829262 rows affected)

select * from sales;

select column_name,data_type
from information_schema.columns;

alter table sales
alter column Sale_ID int;

alter table sales
alter column sale_Date date;

select column_name,data_type
from information_schema.columns;

alter table sales
alter column Store_ID char(2);

alter table sales
alter column Product_ID char(2);

alter table sales
alter column Units int;

select column_name,data_type
from information_schema.columns;

--create inventory table

create table inventory
(Store_ID char(2),Product_ID char(2),Stock_On_Hand int);

--Commands completed successfully.

bulk insert inventory
from'C:\nikhil\analyst project\project\sql\inventory.csv'
with (Fieldterminator=',', rowterminator='\n', firstrow=2);

--(1593 rows affected)

select * from inventory;

select column_name,data_type
from information_schema.columns;

create table calender
(Date date);

bulk insert calender
from'C:\nikhil\analyst project\project\sql\calendar.csv'
with (Fieldterminator=',', rowterminator='\n', firstrow=2);

--(638 rows affected)

select * from product;
select * from stores;
select * from sales;
select * from inventory;
select * from calender;

--make relation in tables

alter table sales
add constraint fk1 foreign key (Store_ID) references stores(Store_ID);

--error--There are no primary or candidate keys in the referenced table 'stores' that match the referencing column list in the foreign key 'fk1'.

alter table stores
add constraint p1 primary key(Store_ID);

--error--Cannot define PRIMARY KEY constraint on nullable column in table 'stores'.

alter table stores
alter column Store_ID  char(2) not null;

--Commands completed successfully.
--now try again

alter table stores
add constraint p1 primary key(Store_ID);

--Commands completed successfully.

alter table sales
add constraint fk1 foreign key (Store_ID) references stores(Store_ID);

--Commands completed successfully.

--make relation into sales and product table
select column_name,data_type
from information_schema.columns;

alter table product
alter column Product_ID  char(2) not null;
--Commands completed successfully.

alter table product
add constraint p2 primary key(Product_ID);
--Commands completed successfully.

alter table sales
add constraint fk2 foreign key (Product_ID) references product(Product_ID);
--Commands completed successfully.

--make relation into inventory and product

alter table inventory
add constraint fk3 foreign key (Product_ID) references product(Product_ID);
--Commands completed successfully.

--make relation into inventory and stores
alter table inventory
add constraint fk4 foreign key (Store_ID) references stores(Store_ID);
--Commands completed successfully.

select * from product;
select * from stores;
select * from sales;
select * from inventory;
select * from calender;

--Identify top-performing products based on total sales and profit.

SELECT P.Product_id,Product_name,SUM(units) AS total_units_sold,SUM(units * Product_price) AS total_sales,
SUM((Product_price - Product_cost) * units) AS total_profit
FROM Product P
INNER JOIN Sales S ON P.Product_id = S.product_id
GROUP BY P.Product_id, P.Product_name
ORDER BY total_profit DESC, total_sales DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------

--Analyze sales performance for each store, including total revenue and profit margin.

SELECT ST.Store_id,Store_name,SUM(units * Product_price) AS 'total_revenue',
SUM((Product_price - Product_cost) * units) AS 'total_profit'
FROM stores ST
INNER JOIN Sales S 
ON ST.Store_id = S.store_id
INNER JOIN Product P 
ON S.product_id = P.Product_id
GROUP BY ST.Store_id, Store_name
ORDER BY total_revenue DESC, total_profit DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

--Examine monthly sales trends, considering the rolling 3-month average and identifying months with significant growth or decline.

WITH MonthlySales AS (SELECT YEAR(S.sale_date) AS 'Year',MONTH(S.sale_date) AS 'Month',
SUM(units *Product_price) AS 'Total_sales'
FROM Sales S
INNER JOIN Product P 
ON S.product_id = P.Product_id
GROUP BY YEAR(S.sale_date), MONTH(S.sale_date)),

RollingAvg AS (SELECT Year,Month,total_sales,
AVG(total_sales) OVER (ORDER BY Year, MONTH ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS 'rolling_3_month_avg'--This calculates the average sales for the current month and the two previous months.
FROM MonthlySales)
SELECT Year,Month,total_sales,rolling_3_month_avg,
total_sales - LAG(total_sales) OVER (ORDER BY Year, MONTH) AS 'sales_difference',

CASE 
     WHEN total_sales - LAG(total_sales) OVER (ORDER BY Year, MONTH) > 0 THEN 'Growth'
     ELSE 'Decline'
     END AS 'trend'

FROM RollingAvg

ORDER BY Year, MONTH;

--LAG Function:Retrieves the sales amount from the previous month.
--OVER: Defines the order in which rows are processed, so that LAG knows which row is the "previous" one.

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Calculate the cumulative distribution of profit margin for each product category, considering where products are having profit.

WITH ProductProfit AS (SELECT P.product_category,P.Product_id,P.Product_name,
SUM((P.Product_price - P.Product_cost) * S.units) AS profit_margin
FROM Product P
INNER JOIN Sales S ON P.Product_id = S.product_id
GROUP BY P.product_category, P.Product_id, P.Product_name),

--Understanding Cumulative Profit
--As we've established, cumulative profit is the total profit accumulated over a specific period. 
--It's a running tally of profits from the beginning of the period to the present.

CumulativeProfit AS (SELECT product_category,Product_id,Product_name,profit_margin,
SUM(profit_margin) OVER (PARTITION BY product_category ORDER BY profit_margin DESC) AS cumulative_profit
FROM ProductProfit)
SELECT product_category,Product_id,Product_name,profit_margin,cumulative_profit
FROM CumulativeProfit
ORDER BY product_category, cumulative_profit DESC;

--PARTITION BY product_category divides the data into partitions based on the product_category
--The data is divided into groups based on the specified column(s) in the PARTITION BY clause.
--Key Points about Cumulative Profit
--It's essential for trend analysis.
--Helpful in forecasting.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Analyze the efficiency of inventory turnover for each store by calculating the Inventory Turnover Ratio.

SELECT ST.store_id,ST.Store_name,P.Product_id,P.Product_name,COALESCE(SUM(S.units), 0) AS 'total_units_sold',
COALESCE(I.Stock_on_hand, 0) AS 'stock_on_hand', 
CASE 
    WHEN COALESCE(I.Stock_on_hand, 0) > 0 
	THEN COALESCE(SUM(S.units), 0) / COALESCE(I.Stock_on_hand, 0)
    ELSE 0
END AS 'inventory_turnover_ratio'
FROM Stores ST
INNER JOIN Inventory I 
ON ST.Store_id = I.store_id
INNER JOIN Product P 
ON I.Product_id = P.Product_id
LEFT JOIN Sales S 
ON ST.Store_id = S.store_id AND P.Product_id = S.product_id
GROUP BY ST.store_id, ST.Store_name, P.Product_id, P.Product_name, I.Stock_on_hand
ORDER BY store_id,inventory_turnover_ratio DESC;

--here I use Coalesce for handle null values.

--Inventory Turnover Ratio: Calculated by dividing the total units sold by the stock on hand.
--LEFT JOIN Sales: Ensures all products in inventory are included.

--Thank You--