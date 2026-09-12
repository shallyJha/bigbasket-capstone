-- Revenue tier per product, based on total Delivered revenue (High >= 3000, Medium >= 1000, else Low)
SELECT p.product_id, p.product_name,
       COALESCE(SUM(o.amount_inr), 0) AS total_revenue,
       CASE
         WHEN COALESCE(SUM(o.amount_inr), 0) >= 3000 THEN 'High'
         WHEN COALESCE(SUM(o.amount_inr), 0) >= 1000 THEN 'Medium'
         ELSE 'Low'
       END AS revenue_tier
FROM products p
LEFT JOIN orders o ON o.product_id = p.product_id AND o.status = 'Delivered'
GROUP BY p.product_id, p.product_name;

-- Monthly revenue by category for Delivered orders, grouped and ordered by category then month
SELECT p.category,
       strftime('%Y-%m', o.order_date) AS month,
       COUNT(*) AS order_count,
       SUM(o.amount_inr) AS total_revenue,
       AVG(o.amount_inr) AS avg_revenue
FROM orders o
JOIN products p ON p.product_id = o.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category, month
ORDER BY p.category, month;

-- Category revenue versus target, with variance and a three-way status tag
SELECT p.category,
       SUM(o.amount_inr) AS total_revenue,
       ct.target_revenue_inr,
       ct.target_revenue_inr - SUM(o.amount_inr) AS variance,
       ((SUM(o.amount_inr) - ct.target_revenue_inr) * 100.0) / ct.target_revenue_inr AS percentage_variance,
       CASE
         WHEN SUM(o.amount_inr) >= ct.target_revenue_inr THEN 'Above Target'
         WHEN ((ct.target_revenue_inr - SUM(o.amount_inr)) * 100.0) / ct.target_revenue_inr <= 15 THEN 'Below Target - Watch'
         ELSE 'Below Target - Critical'
       END AS target_status
FROM orders o
JOIN products p ON p.product_id = o.product_id
JOIN category_targets ct ON ct.category = p.category
WHERE o.status = 'Delivered'
GROUP BY p.category, ct.target_revenue_inr
ORDER BY p.category;
