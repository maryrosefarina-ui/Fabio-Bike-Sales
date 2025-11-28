-- Business Question in Data Analytics

/*
==============================================
         Changes Over Time Analysis
==============================================

-- Analyze Sales Performance Over Time
-- Calculate the total number of Customers 
-- Find total number of Solds
*/

SELECT * FROM retail.fact_sales

SELECT 
	YEAR(order_date) AS order_year, 
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_solds
FROM retail.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year

/*
====================================================================================
                                Cumulative Analysis
====================================================================================

- Calculate the total sales per month and the running total of sales over time
- Get the moving average of the price
*/

SELECT * FROM retail.fact_sales

SELECT 
	order_month, 
	total_sales,
	SUM(total_sales) OVER(PARTITION BY order_month ORDER BY order_month) AS running_total_sales,
	AVG(avg_price) OVER(PARTITION BY order_month ORDER BY order_month) AS avg_total_sales
FROM (
	SELECT 
		DATETRUNC(MONTH, order_date) AS order_month,
		SUM(sales_amount) AS total_sales,
		AVG(price) AS avg_price
	FROM retail.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
) AS sales_overtime

/*
=====================================================================================
                                Performance Analysis
=====================================================================================

- Analyze the yearly performance of the products by comparing their sales 
   to both average sales performance of the product and the previous years sales. 
*/
-- Using Window Function

WITH Yearly_Product_Sales AS 
(
SELECT 
	YEAR(fs.order_date) AS order_year, 
	product_name,
	SUM(fs.sales_amount) AS current_sales
FROM retail.fact_sales AS fs
LEFT JOIN retail.dim_products AS dp
	ON fs.product_key = dp.product_key
WHERE order_date IS NOT NULL
GROUP BY YEAR(fs.order_date), product_name
) 
SELECT 
	order_year, 
	product_name, 
	current_sales,
	AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
	CASE
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Average'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Low Average'
		ELSE 'Average'
	END average_status,
	-- Year-Over-Year Analysis
	LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_prev_years,
	CASE 
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increased'
		WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Dropped'
		ELSE 'Steady'
	END trend_status
FROM Yearly_Product_Sales
ORDER BY product_name, order_year

/*
============================================================
                  Part-To-Whole Analysis
============================================================

- Which categories contribute the most to overall sales?
*/

WITH CTE_Contribution_Sales AS
(
SELECT 
	category,
	SUM(sales_amount) AS total_sales
FROM retail.dim_products AS dp
LEFT JOIN retail.fact_sales AS fs
	ON dp.product_key = fs.product_key
WHERE category IS NOT NULL
GROUP BY category
)
SELECT 
	category, 
	total_sales, 
	SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER())*100, 2), '%') AS total_percentage
FROM CTE_Contribution_Sales
WHERE total_sales IS NOT NULL
ORDER BY total_sales DESC

/*
=========================================================================================
                                    Data Segmentation 
=========================================================================================

- Segment products into cost ranges and count how many products fall into each segment
*/

WITH product_segments AS 
(
SELECT 
	product_id,
	product_name,
	CASE
		WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END AS cost_range
FROM retail.dim_products
)
SELECT 
	cost_range, 
	COUNT(product_name) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

/* Group customers into three segments based on their spending behavior:
	- VIP: Customers with atleast 12 months of history and spending more that  5,000.
	- Regular: Customers with atleast 12 months of history and spending  5,000 or less.
	- New: Customers with a lifespan less than 12 months.
	- Find the total number of customers by each group */

WITH CTE_Customers_Spending_Behavior AS 
(
SELECT 
	dc.customer_key,
	SUM(fs.sales_amount) AS total_spending,
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS customer_durations
FROM retail.dim_customers AS dc
LEFT JOIN retail.fact_sales AS fs
	ON dc.customer_key = fs.customer_key
GROUP BY dc.customer_key
	) 

SELECT 
	customer_status, 
	COUNT(customer_key) AS total_customers
FROM (
	SELECT customer_key, total_spending, customer_durations,
		CASE
			WHEN customer_durations >= 12 AND total_spending > 5000 THEN 'VIP'
			WHEN customer_durations >= 12 AND total_spending <= 5000 THEN 'Regular'
			ELSE'New'
		END AS customer_status
	FROM CTE_Customers_Spending_Behavior
	) AS customer_duration_status
GROUP BY customer_status
ORDER BY total_customers DESC

















