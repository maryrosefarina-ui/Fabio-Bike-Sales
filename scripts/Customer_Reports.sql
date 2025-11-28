/*
=================================================================================
                                 CUSTOMER REPORT
=================================================================================

-- Purpose: 
	- This report consolidates key customer metrics and behaviours

-- Highlights: 
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segment customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- duration in months
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend

=================================================================================
*/
/*---------For Reporting and Analyzis-------------
		CREATE VIEW retail.customer_report    		
------------------------------------------------*/
/*--------------------------------------------------------------------
Base Query: Retrieves core columns from tables  
--------------------------------------------------------------------*/

	WITH Customer_Details AS (
	SELECT 
		fs.order_number, 
		fs.product_key, 
		fs.order_date, 
		fs.sales_amount, 
		fs.quantity,
		dc.customer_key,
		dc.customer_number,
		CONCAT(dc.first_name, ' ', dc.last_name) AS customer_name,
		DATEDIFF(YEAR, dc.birthdate, GETDATE()) AS age
	FROM retail.fact_sales AS fs
	JOIN retail.dim_customers AS dc
		ON fs.customer_key = dc.customer_key
	WHERE fs.order_date IS NOT NULL
	),
/*--------------------------------------------------------------------
Customer Aggregations: Summarizes key metrics at the customer level 
--------------------------------------------------------------------*/
	Customer_Metrics AS (
	SELECT customer_key, customer_number, customer_name, age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS month_duration
	FROM Customer_Details
	GROUP BY customer_key, customer_number, customer_name, age
	)
/*--------------------------------------------------------------------
Final Query: Combines all product result into one output 
--------------------------------------------------------------------*/
	SELECT 
		customer_key, 
		customer_number, 
		customer_name, 
		age,
		-- segment age status
		CASE 
			WHEN age < 18 THEN 'Under age'
			WHEN age BETWEEN 18 AND 29 THEN '18-29'
			WHEN age BETWEEN 30 AND 39 THEN '30-39'
			WHEN age BETWEEN 40 AND 49 THEN '40-49'
			ELSE '50 and Above'
		END AS age_group,
		total_orders,
		total_sales,
		month_duration,
		CASE 
			WHEN month_duration >= 12 AND total_sales >= 5000 THEN 'VIP'
			WHEN month_duration >= 12 AND total_sales <= 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_status,
		total_quantity,
		total_products, 
		last_order,
		DATEDIFF(MONTH, last_order, GETDATE()) recent_order_month,
		-- Compute the Average Order Value (AOV)
		CASE
			WHEN total_sales = 0 THEN 0
			ELSE total_sales / total_orders
		END avg_order_value,
		-- Compute the Average Monthly Spend
		CASE 
			WHEN month_duration = 0 THEN total_sales
			ELSE total_sales / month_duration
		END AS avg_monthly_spend
	FROM Customer_Metrics