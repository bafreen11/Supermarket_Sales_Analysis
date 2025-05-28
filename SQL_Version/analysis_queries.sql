-- Monthly Sales Trend
SELECT TO_CHAR(order_date, 'YYYY-MM') AS order_month,
       SUM(sales) AS total_sales
FROM sales_table
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Profit by State
SELECT state, SUM(profit) AS total_profit
FROM sales_table
GROUP BY state
ORDER BY total_profit DESC;
