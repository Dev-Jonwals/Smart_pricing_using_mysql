CREATE DATABASE pricing_db;
USE pricing_db;

CREATE TABLE users (
    user_id VARCHAR(10),
    city VARCHAR(50),
    city_tier VARCHAR(10),
    signup_date DATE,
    loyalty_score INT
);

CREATE TABLE products (
    product_id VARCHAR(10),
    product_name VARCHAR(100),
    category VARCHAR(50),
    base_price DECIMAL(10,2),
    cost_price DECIMAL(10,2)
);

CREATE TABLE transactions (
    transaction_id VARCHAR(15),
    user_id VARCHAR(10),
    product_id VARCHAR(10),
    transaction_date DATE,
    discount_percent DECIMAL(5,2),
    price_after_discount DECIMAL(10,2),
    purchased TINYINT
);


CREATE OR REPLACE VIEW user_metrics AS
SELECT
    u.user_id,
    COUNT(t.transaction_id) AS total_orders,
    DATEDIFF(CURDATE(), MAX(t.transaction_date)) AS recency_days,
    DATEDIFF(CURDATE(), u.signup_date) AS tenure_days,
    ROUND(AVG(t.price_after_discount), 2) AS avg_order_value
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id AND t.purchased = 1
GROUP BY u.user_id, u.signup_date;
select * from user_metrics;


SELECT 
    user_id,

    -- Normalize total orders (purchase frequency)
    ROUND(100 * (total_orders - MIN(total_orders) OVER()) /
                NULLIF((MAX(total_orders) OVER() - MIN(total_orders) OVER()), 0), 2) AS freq_score,

    -- Normalize average order value
    ROUND(100 * (avg_order_value - MIN(avg_order_value) OVER()) /
                NULLIF((MAX(avg_order_value) OVER() - MIN(avg_order_value) OVER()), 0), 2) AS value_score,

    -- Normalize recency (inverse: more recent = higher score)
    ROUND(100 * (MAX(recency_days) OVER() - recency_days) /
                NULLIF((MAX(recency_days) OVER() - MIN(recency_days) OVER()), 0), 2) AS recency_score,

    -- Normalize tenure
    ROUND(100 * (tenure_days - MIN(tenure_days) OVER()) /
                NULLIF((MAX(tenure_days) OVER() - MIN(tenure_days) OVER()), 0), 2) AS tenure_score

FROM user_metrics;


SELECT 
    user_id,
    ROUND(0.4 * freq_score + 0.3 * value_score + 0.2 * recency_score + 0.1 * tenure_score, 2) AS loyalty_score
FROM (
    -- Use the previous normalization query as a subquery
    SELECT 
        user_id,
        ROUND(100 * (total_orders - MIN(total_orders) OVER()) /
                    NULLIF((MAX(total_orders) OVER() - MIN(total_orders) OVER()), 0), 2) AS freq_score,

        ROUND(100 * (avg_order_value - MIN(avg_order_value) OVER()) /
                    NULLIF((MAX(avg_order_value) OVER() - MIN(avg_order_value) OVER()), 0), 2) AS value_score,

        ROUND(100 * (MAX(recency_days) OVER() - recency_days) /
                    NULLIF((MAX(recency_days) OVER() - MIN(recency_days) OVER()), 0), 2) AS recency_score,

        ROUND(100 * (tenure_days - MIN(tenure_days) OVER()) /
                    NULLIF((MAX(tenure_days) OVER() - MIN(tenure_days) OVER()), 0), 2) AS tenure_score
    FROM user_metrics
) sub;

Select * from users;
Select * from products;
Select * from transactions;


CREATE OR REPLACE VIEW user_loyalty_cohort AS
SELECT 
    u.user_id,
    u.city,
    u.city_tier,

    -- Categorize loyalty
    CASE 
        WHEN ls.loyalty_score >= 70 THEN 'High'
        WHEN ls.loyalty_score >= 40 THEN 'Mid'
        ELSE 'Low'
    END AS loyalty_segment,

    ls.loyalty_score
FROM (
    SELECT 
        user_id,
        ROUND(0.4 * freq_score + 0.3 * value_score + 0.2 * recency_score + 0.1 * tenure_score, 2) AS loyalty_score
    FROM (
        SELECT 
            user_id,
            ROUND(100 * (total_orders - MIN(total_orders) OVER()) /
                        NULLIF((MAX(total_orders) OVER() - MIN(total_orders) OVER()), 0), 2) AS freq_score,

            ROUND(100 * (avg_order_value - MIN(avg_order_value) OVER()) /
                        NULLIF((MAX(avg_order_value) OVER() - MIN(avg_order_value) OVER()), 0), 2) AS value_score,

            ROUND(100 * (MAX(recency_days) OVER() - recency_days) /
                        NULLIF((MAX(recency_days) OVER() - MIN(recency_days) OVER()), 0), 2) AS recency_score,

            ROUND(100 * (tenure_days - MIN(tenure_days) OVER()) /
                        NULLIF((MAX(tenure_days) OVER() - MIN(tenure_days) OVER()), 0), 2) AS tenure_score
        FROM user_metrics
    ) sub
) ls
JOIN users u ON u.user_id = ls.user_id;

SELECT city_tier, loyalty_segment, COUNT(*) AS user_count
FROM user_loyalty_cohort
GROUP BY city_tier, loyalty_segment;


CREATE OR REPLACE VIEW discount_performance AS
SELECT
    t.product_id,
    p.product_name,
    p.category,
    
    c.city_tier,
    c.loyalty_segment,
    
    t.discount_percent,
    
    COUNT(*) AS total_users_seen,
    SUM(t.purchased) AS total_purchases,
    
    ROUND(100.0 * SUM(t.purchased) / COUNT(*), 2) AS conversion_rate,

    ROUND(AVG(t.price_after_discount - p.cost_price), 2) AS avg_absolute_margin,
    ROUND(AVG((t.price_after_discount - p.cost_price) / NULLIF(t.price_after_discount, 0)), 2) AS avg_margin_pct

FROM transactions t
JOIN products p ON t.product_id = p.product_id
JOIN user_loyalty_cohort c ON t.user_id = c.user_id

GROUP BY 
    t.product_id, p.product_name, p.category,
    c.city_tier, c.loyalty_segment,
    t.discount_percent
ORDER BY conversion_rate DESC;

SELECT *
FROM discount_performance;

CREATE OR REPLACE VIEW best_discount_recommendation AS
SELECT *
FROM (
    SELECT
        product_id,
        product_name,
        category,
        city_tier,
        loyalty_segment,
        discount_percent,
        conversion_rate,
        avg_margin_pct,
        
        RANK() OVER (
            PARTITION BY product_id, city_tier, loyalty_segment
            ORDER BY discount_percent ASC
        ) AS discount_rank

    FROM discount_performance
    WHERE conversion_rate >= 60   -- set your desired threshold
      AND avg_margin_pct >= 0.15  -- 15% minimum margin
) sub
WHERE discount_rank = 1;


select * from best_discount_recommendation;

