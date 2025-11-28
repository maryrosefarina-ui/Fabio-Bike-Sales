/* IF OBJECT_ID('retail.Customers', 'U') IS NOT NULL 
	DROP VIEW retail.Customers;
GO
-- Change the table name to create view for products and orders*/

SELECT 
	retail.dim_customers.customer_key AS Customer_ID,
	CONCAT(retail.dim_customers.first_name, ' ', retail.dim_customers.last_name),
	retail.dim_customers.country
FROM retail.dim_customers
WHERE country != 'n/a';

SELECT 
	retail.dim_fact_sales.order_number AS Order_ID, 
	retail.dim_fact_sales.product_key AS Product_ID, 
	retail.dim_fact_sales.customer_key AS Customer_ID,
	retail.dim_fact_sales.order_date AS Order_Date,
	retail.dim_fact_sales.shipping_date AS Shipping_Date,
	retail.dim_fact_sales.due_date AS Due_Date,
	retail.dim_fact_sales.sales_amount AS Sales,
	retail.dim_fact_sales.quantity AS Quantity,
	retail.dim_fact_sales.price AS Price
FROM retail.dim_fact_sales
WHERE retail.dim_fact_sales.order_date IS NOT NULL;

SELECT  
	retail.dim_products.product_key AS Product_ID, 
	retail.dim_products.product_name AS Product_Name,
	retail.dim_products.category AS Category, 
	retail.dim_products.subcategory AS Subcategory, 
	retail.dim_products.cost AS Cost
FROM retail.dim_products;
