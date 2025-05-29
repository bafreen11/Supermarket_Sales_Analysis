 1. Preview data
SELECT * FROM retail_sales FETCH NEXT 10 ROWS ONLY;
SELECT * FROM (SELECT * FROM retail_sales) WHERE ROWNUM <= 10;

-- 2. Overall sales and profit
SELECT ROUND(SUM(sales), 2) AS total_sales, ROUND(SUM(profit), 2) AS total_profit FROM retail_sales;

-- 3. Sales and profit by category
SELECT category, ROUND(SUM(sales), 2) AS total_sales, ROUND(SUM(profit), 2) AS total_profit
FROM retail_sales
GROUP BY category
ORDER BY total_sales;

-- 4. Top 5 cities by sales
SELECT city, ROUND(SUM(sales), 2) AS total_sales
FROM retail_sales
GROUP BY city
ORDER BY total_sales DESC FETCH FIRST 5 ROWS ONLY;

-- 5. Monthly sales
SELECT TO_CHAR(order_date, 'yyyy-mm') AS order_month, ROUND(SUM(sales), 2) AS total_sales
FROM retail_sales
GROUP BY TO_CHAR(order_date, 'yyyy-mm')
ORDER BY order_month DESC FETCH NEXT 100 ROWS ONLY;

-- 6. Add and populate order_id using sequence and trigger
ALTER TABLE retail_sales ADD order_id VARCHAR2(20);

CREATE SEQUENCE order_id_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_set_order_id
BEFORE INSERT ON retail_sales
FOR EACH ROW
BEGIN
  :new.order_id := order_id_seq.NEXTVAL;
END;
/

UPDATE retail_sales SET order_id = order_id_seq.NEXTVAL;

-- 7. Customer purchase frequency
SELECT customer_name, COUNT(DISTINCT order_id) AS total_orders
FROM retail_sales
GROUP BY customer_name
ORDER BY total_orders DESC;

-- 8. Sales by category and sub-category
SELECT category, sub_category, SUM(sales) AS total_sales, SUM(profit) AS total_profit
FROM retail_sales
GROUP BY category, sub_category
ORDER BY total_sales DESC;

-- 9. Sales by region and state
SELECT region, state, SUM(sales) AS total_sales, SUM(profit) AS total_profit
FROM retail_sales
GROUP BY region, state
ORDER BY total_sales DESC;

-- 10. Customer purchase type
SELECT customer_name, order_id, order_date, first_order_date, last_order_date,
       CASE 
           WHEN order_date = first_order_date THEN 'First Purchase'
           WHEN order_date = last_order_date THEN 'Most Recent'
           ELSE 'Repeat'
       END AS purchase_type
FROM (
    SELECT *,
           MIN(order_date) OVER (PARTITION BY customer_name) AS first_order_date,
           MAX(order_date) OVER (PARTITION BY customer_name) AS last_order_date
    FROM retail_sales
);

-- 11. Running total sales by region and month
SELECT region,
       TO_CHAR(order_date, 'yyyy-mm') AS sales_month,
       SUM(sales) AS monthly_sales,
       SUM(SUM(sales)) OVER (PARTITION BY region ORDER BY TO_CHAR(order_date, 'yyyy-mm')) AS running_total
FROM retail_sales
GROUP BY region, TO_CHAR(order_date, 'yyyy-mm')
ORDER BY region, sales_month;

-- 12. Top customer per category by sales
SELECT *
FROM (
    SELECT category, sub_category, customer_name, SUM(sales) AS total_sales,
           RANK() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS sales_rank
    FROM retail_sales
    GROUP BY category, sub_category, customer_name
)
WHERE sales_rank = 1;

-- 13. Repeat vs one-time customers
WITH customer_order_count AS (
    SELECT customer_name, COUNT(DISTINCT order_id) AS order_count
    FROM retail_sales
    GROUP BY customer_name
)
SELECT 
    COUNT(CASE WHEN order_count = 1 THEN 1 END) AS one_time_customers,
    COUNT(CASE WHEN order_count > 1 THEN 1 END) AS repeat_customers,
    ROUND(100 * COUNT(CASE WHEN order_count > 1 THEN 1 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_order_count;

-- 14. Month-over-month sales growth
WITH monthly_sales AS (
    SELECT TO_CHAR(order_date, 'yyyy-mm') AS sales_month, SUM(sales) AS total_sales
    FROM retail_sales
    GROUP BY TO_CHAR(order_date, 'yyyy-mm')
)
SELECT sales_month, total_sales,
       LAG(total_sales) OVER (ORDER BY sales_month) AS prev_month_sales,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY sales_month)) * 100 / 
             LAG(total_sales) OVER (ORDER BY sales_month), 2) AS growth_pct
FROM monthly_sales;

-- 15. Customer segmentation
WITH customer_value AS (
    SELECT customer_name, SUM(sales) AS total_sales, SUM(profit) AS total_profit
    FROM retail_sales
    GROUP BY customer_name
)
SELECT customer_name, total_sales, total_profit,
       CASE 
           WHEN total_sales >= 1000 THEN 'High Value'
           WHEN total_sales BETWEEN 500 AND 999 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_segment
FROM customer_value
ORDER BY total_sales DESC;

-- 16. Profit margin by region and category
SELECT region, category, SUM(sales) AS total_sales, SUM(profit) AS total_profit,
       ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM retail_sales
GROUP BY region, category
ORDER BY region, profit_margin_pct DESC;

-- 17. Top category per state by sales
SELECT *
FROM (
    SELECT state, category, SUM(sales) AS total_sales,
           RANK() OVER (PARTITION BY state ORDER BY SUM(sales) DESC) AS sales_rank
    FROM retail_sales
    GROUP BY state, category
)
WHERE sales_rank = 1
ORDER BY state;
