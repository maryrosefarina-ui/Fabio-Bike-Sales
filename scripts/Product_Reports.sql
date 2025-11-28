/*
================================================================================================
                Build Product Report - Business Product Insights
================================================================================================
-- Purpose: 
	- This report consolidates key product metrics and behaviours

-- Highlights: 
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Segment products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- last order of customers
		- duration in months
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
================================================================================================
*/

/*---------For Reporting and Analyzis-------------
		CREATE VIEW retail.product_report    		
------------------------------------------------*/
/*-----------------------------------------------------------------------------
Base Query: Retrieves core columns from tables  
-----------------------------------------------------------------------------*/

WITH Product_Details AS (
SELECT 
	fs.order_number, 
	fs.customer_key, 
	order_date, 
	sales_amount, 
	fs.quantity,
	dp.product_key, 
	dp.product_name, 
	dp.category, 
	dp.subcategory, 
	dp.cost
	FROM retail.fact_sales AS fs
	LEFT JOIN retail.dim_products AS dp
		ON fs.product_key = dp.product_key
	WHERE order_date IS NOT NULL
	),
/*-----------------------------------------------------------------------------
Product Aggregations: Summarizes key metrics at the product level 
-----------------------------------------------------------------------------*/
Product_Aggregation AS (
SELECT 
	product_key,
	product_name,
	category, 
	subcategory, 
	cost,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT customer_key) AS total_customers,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS month_duration,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
	FROM Product_Details
	GROUP BY 
	product_key, 
	product_name, 
	category, 
	subcategory,
	cost
	)
/*-----------------------------------------------------------------------------
Final Query: Combines all product result into one output 
-----------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name, 
	category, 
	subcategory, 
	cost,
	total_orders, 
	total_sales, 
	-- Segment product status
	CASE
		WHEN total_sales > 500000 THEN 'High-Performers'
		WHEN total_sales <= 500000 THEN 'Mid_Range'
		ELSE 'Low_Performers'
	END AS product_status,
	total_quantity, 
	total_customers,
	last_order_date, 
	month_duration, 
	DATEDIFF(MONTH, last_order_date, GETDATE()) AS month_recent_sale,
	avg_selling_price,
	-- Compute average order revenue (AOR)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS ave_order_value,
	-- Compute average monthly revenue
	CASE
		WHEN month_duration = 0 THEN total_sales
		ELSE total_sales / month_duration
	END ave_monthly_revenue
FROM Product_Aggregation
