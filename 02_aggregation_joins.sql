-- Category revenue summary for Delivered orders, categories above 10000 in total revenue
SELECT p.category,
       COUNT(*) AS order_count,
       SUM(o.amount_inr) AS total_revenue,
       AVG(o.amount_inr) AS avg_order_value
FROM orders o
INNER JOIN products p ON p.product_id = o.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
HAVING total_revenue > 10000;

-- Order count per product, least-ordered first, keeping products with zero orders
SELECT p.product_name,
       COUNT(o.order_id) AS order_count
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY order_count ASC;
