-- ====================================================================
-- Project: Customer Lifecycle & Churn Intelligence Engine
-- Database: PostgreSQL
-- Author: Kishor Ravi
-- ====================================================================

-- 1. DIMENSION: dim_customers
CREATE TABLE dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE NOT NULL,
    customer_city VARCHAR(100),
    customer_state VARCHAR(50),
    signup_date TIMESTAMP NOT NULL
);

-- 2. DIMENSION: dim_products
CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE NOT NULL,
    product_category VARCHAR(100),
    standard_price NUMERIC(10, 2) NOT NULL
);

-- 3. FACT TABLE: fact_orders
CREATE TABLE fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT REFERENCES dim_customers(customer_key),
    product_key INT REFERENCES dim_products(product_key),
    order_timestamp TIMESTAMP NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    discount_amount NUMERIC(10, 2) DEFAULT 0.00,
    net_revenue NUMERIC(10, 2) NOT NULL,
    order_status VARCHAR(25) NOT NULL
);

-- Indexing for warehouse performance optimization
CREATE INDEX idx_fact_orders_cust ON fact_orders(customer_key);
CREATE INDEX idx_fact_orders_timestamp ON fact_orders(order_timestamp);

-- ====================================================================
-- ANALYTICAL QUERY 1: Customer Lifetime Value (LTV) & Order Recency
-- Utilizes Window Functions (ROW_NUMBER, LAG) and CTEs
-- ====================================================================
WITH customer_order_history AS (
    SELECT 
        c.customer_id,
        f.order_id,
        f.order_timestamp,
        f.net_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY f.order_timestamp ASC) AS order_sequence,
        LAG(f.order_timestamp) OVER (PARTITION BY c.customer_id ORDER BY f.order_timestamp ASC) AS prev_order_timestamp
    FROM fact_orders f
    JOIN dim_customers c ON f.customer_key = c.customer_key
    WHERE f.order_status = 'Delivered'
),
customer_summary AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        ROUND(SUM(net_revenue), 2) AS lifetime_value,
        ROUND(AVG(net_revenue), 2) AS avg_order_value,
        ROUND(AVG(EXTRACT(EPOCH FROM (order_timestamp - prev_order_timestamp)) / 86400)::numeric, 1) AS avg_days_between_purchases
    FROM customer_order_history
    GROUP BY customer_id
)
SELECT 
    customer_id,
    total_orders,
    lifetime_value,
    avg_order_value,
    COALESCE(avg_days_between_purchases, 0) AS avg_repurchase_interval_days,
    NTILE(5) OVER (ORDER BY lifetime_value DESC) AS ltv_quintile
FROM customer_summary
ORDER BY lifetime_value DESC;

-- ====================================================================
-- ANALYTICAL QUERY 2: Monthly Retention Cohort Matrix
-- Calculates initial cohort activity and month-by-month retention rates
-- ====================================================================
WITH first_purchase AS (
    SELECT 
        c.customer_id,
        DATE_TRUNC('month', MIN(f.order_timestamp)) AS cohort_month
    FROM fact_orders f
    JOIN dim_customers c ON f.customer_key = c.customer_key
    WHERE f.order_status = 'Delivered'
    GROUP BY c.customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        c.customer_id,
        DATE_TRUNC('month', f.order_timestamp) AS activity_month
    FROM fact_orders f
    JOIN dim_customers c ON f.customer_key = c.customer_key
    WHERE f.order_status = 'Delivered'
),
cohort_size AS (
    SELECT cohort_month, COUNT(customer_id) AS total_customers
    FROM first_purchase
    GROUP BY cohort_month
),
retention_data AS (
    SELECT 
        fp.cohort_month,
        ma.activity_month,
        (EXTRACT(YEAR FROM ma.activity_month) - EXTRACT(YEAR FROM fp.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM ma.activity_month) - EXTRACT(MONTH FROM fp.cohort_month)) AS period_month,
        COUNT(DISTINCT fp.customer_id) AS active_customers
    FROM first_purchase fp
    JOIN monthly_activity ma ON fp.customer_id = ma.customer_id
    GROUP BY fp.cohort_month, ma.activity_month
)
SELECT 
    TO_CHAR(r.cohort_month, 'YYYY-MM') AS cohort,
    cs.total_customers AS cohort_size,
    r.period_month,
    r.active_customers,
    ROUND((r.active_customers::numeric / cs.total_customers::numeric) * 100, 2) AS retention_rate_pct
FROM retention_data r
JOIN cohort_size cs ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month ASC, r.period_month ASC;
