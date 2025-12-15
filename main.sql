CREATE DATABASE instacart_qcommerce;


drop table orders;
drop table order_products__prior;


SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_products__prior;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM aisles;
SELECT COUNT(*) FROM departments;

CREATE TABLE user_cohorts AS
SELECT user_id, MAX(order_number) AS total_orders,
    ROUND(AVG(days_since_prior_order), 2) AS avg_days_between_orders,
    CASE
        WHEN MAX(order_number) = 1 THEN 'First-Time'
        WHEN MAX(order_number) BETWEEN 2 AND 5 THEN 'Occasional'
        ELSE 'Loyal'
    END AS loyalty_cohort
FROM orders
GROUP BY user_id;

SELECT loyalty_cohort, COUNT(*) 
FROM user_cohorts
GROUP BY loyalty_cohort;

select * from user_cohorts;

CREATE TABLE sku_metrics AS
SELECT
    op.product_id,
    COUNT(*) AS total_orders,
    SUM(op.reordered) AS reordered_orders,
    ROUND(SUM(op.reordered) / COUNT(*), 3) AS reorder_rate
FROM order_products__prior op
GROUP BY op.product_id;

SELECT *
FROM sku_metrics
ORDER BY reorder_rate DESC;

ALTER TABLE sku_metrics
ADD COLUMN price_sensitivity VARCHAR(20);

UPDATE sku_metrics
SET price_sensitivity =
    CASE
        WHEN reorder_rate >= 0.60 THEN 'Low Sensitivity'
        WHEN reorder_rate >= 0.30 THEN 'Medium Sensitivity'
        ELSE 'High Sensitivity'
    END;
    
    
SELECT price_sensitivity, COUNT(*)
FROM sku_metrics
GROUP BY price_sensitivity;

CREATE TABLE cohort_sku_metrics 
SELECT
    uc.loyalty_cohort,
    op.product_id,
    COUNT(*) AS total_orders,
    ROUND(SUM(op.reordered) / COUNT(*), 3) AS cohort_reorder_rate
FROM order_products__prior op
JOIN orders o
    ON op.order_id = o.order_id
JOIN user_cohorts uc
    ON o.user_id = uc.user_id
GROUP BY
    uc.loyalty_cohort,
    op.product_id;
    
SELECT *
FROM cohort_sku_metrics;

CREATE TABLE order_cohorts AS
SELECT
    order_id,
    user_id,
    order_number,
    CASE
        WHEN order_number = 1 THEN 'First-Time'
        WHEN order_number BETWEEN 2 AND 5 THEN 'Occasional'
        ELSE 'Loyal'
    END AS loyalty_cohort
FROM orders;

SELECT loyalty_cohort, COUNT(*)
FROM order_cohorts
GROUP BY loyalty_cohort;

CREATE TABLE cohort_sku_metrics_v2 AS
SELECT
    oc.loyalty_cohort,
    op.product_id,
    COUNT(*) AS total_orders,
    ROUND(SUM(op.reordered) / COUNT(*), 3) AS cohort_reorder_rate
FROM order_products__prior op
JOIN order_cohorts oc
    ON op.order_id = oc.order_id
GROUP BY
    oc.loyalty_cohort,
    op.product_id;
    
SELECT loyalty_cohort, COUNT(*) 
FROM cohort_sku_metrics_v2
GROUP BY loyalty_cohort;

CREATE TABLE cohort_sku_metrics_clean_v2 AS
SELECT *
FROM cohort_sku_metrics_v2
WHERE total_orders >= 5;

SELECT loyalty_cohort, COUNT(*)
FROM cohort_sku_metrics_clean_v2
GROUP BY loyalty_cohort;

DROP TABLE cohort_sku_metrics_clean_v2;

CREATE TABLE cohort_sku_metrics_clean_v2 AS
SELECT *
FROM cohort_sku_metrics_v2
WHERE total_orders >= 3;

SELECT loyalty_cohort, COUNT(*)
FROM cohort_sku_metrics_clean_v2
GROUP BY loyalty_cohort;


CREATE TABLE cohort_department_metrics AS
SELECT
    oc.loyalty_cohort,
    d.department,
    COUNT(*) AS total_orders,
    ROUND(SUM(op.reordered) / COUNT(*), 3) AS reorder_rate
FROM order_products__prior op
JOIN order_cohorts oc
    ON op.order_id = oc.order_id
JOIN products p
    ON op.product_id = p.product_id
JOIN departments d
    ON p.department_id = d.department_id
GROUP BY
    oc.loyalty_cohort,
    d.department;
    
SELECT loyalty_cohort, COUNT(*)
FROM cohort_department_metrics
GROUP BY loyalty_cohort;

CREATE TABLE pricing_actions AS
SELECT
    cdm.loyalty_cohort,
    cdm.department,
    cdm.reorder_rate AS cohort_reorder_rate,
    sm.price_sensitivity,
    CASE
        WHEN cdm.loyalty_cohort = 'Loyal'
             AND cdm.reorder_rate >= 0.6
             AND sm.price_sensitivity = 'Low Sensitivity'
            THEN 'Reduce Discount'

        WHEN cdm.loyalty_cohort = 'First-Time'
             AND cdm.reorder_rate < 0.4
             AND sm.price_sensitivity = 'High Sensitivity'
            THEN 'Increase Discount'

        ELSE 'Maintain Discount'
    END AS pricing_action
FROM cohort_department_metrics cdm
JOIN products p
    ON cdm.department = (
        SELECT d.department
        FROM departments d
        WHERE d.department_id = p.department_id
        LIMIT 1
    )
JOIN sku_metrics sm
    ON p.product_id = sm.product_id;
    
SELECT pricing_action, COUNT(*)
FROM pricing_actions
GROUP BY pricing_action;
























