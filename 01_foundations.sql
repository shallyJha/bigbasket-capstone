-- Orders placed by customers in a specific city (Bengaluru)
SELECT o.order_id, o.customer_id, c.city, o.order_date, o.amount_inr, o.status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.city = 'Bengaluru';

-- Every distinct category in products
SELECT DISTINCT category
FROM products;

-- Top 5 highest-value orders
SELECT order_id, customer_id, product_id, amount_inr
FROM orders
ORDER BY amount_inr DESC
LIMIT 5;

-- Total order count, aliased in the output
SELECT COUNT(*) AS total_orders
FROM orders;

-- Orders paid via UPI or Wallet
SELECT order_id, payment_mode, amount_inr
FROM orders
WHERE payment_mode IN ('UPI', 'Wallet');

-- Orders with amount_inr between 200 and 500 (inclusive)
SELECT order_id, amount_inr
FROM orders
WHERE amount_inr BETWEEN 200 AND 500;
