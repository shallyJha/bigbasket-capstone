-- 1.4.1 WHERE: orders placed by customers in a specific city (Bengaluru)
SELECT o.order_id, o.customer_id, c.city, o.order_date, o.amount_inr, o.status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.city = 'Bengaluru';

-- 1.4.2 DISTINCT: every distinct category in products
SELECT DISTINCT category
FROM products;

-- 1.4.3 ORDER BY + LIMIT: top 5 highest-value orders
SELECT order_id, customer_id, product_id, amount_inr
FROM orders
ORDER BY amount_inr DESC
LIMIT 5;
