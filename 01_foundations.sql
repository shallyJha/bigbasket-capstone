-- 1.4.1 WHERE: orders placed by customers in a specific city (Bengaluru)
SELECT o.order_id, o.customer_id, c.city, o.order_date, o.amount_inr, o.status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.city = 'Bengaluru';
