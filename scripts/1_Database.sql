/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'RetailSalesAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called retail
	
WARNING:
    Running this script will drop the entire 'RetailSalesAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'RetailSalesAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RetailSalesAnalytics')
BEGIN
    ALTER DATABASE RetailSalesAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RetailSalesAnalytics;
END;
GO

-- Create the 'RetailSalesAnalytics' database
CREATE DATABASE RetailSalesAnalytics;
GO

USE RetailSalesAnalytics;
GO

-- Create Schemas

CREATE SCHEMA retail;
GO

CREATE TABLE retail.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE retail.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE retail.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE retail.dim_customers;
GO

BULK INSERT retail.dim_customers
FROM 'C:\Users\maryr\OneDrive\PROJECTS\SQL-Retail_Sales_Analytics_Project\datasets\retail.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE retail.dim_products;
GO

BULK INSERT retail.dim_products
FROM 'C:\Users\maryr\OneDrive\PROJECTS\SQL-Retail_Sales_Analytics_Project\datasets\retail.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE retail.fact_sales;
GO

BULK INSERT retail.fact_sales
FROM 'C:\Users\maryr\OneDrive\PROJECTS\SQL-Retail_Sales_Analytics_Project\datasets\retail.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO
