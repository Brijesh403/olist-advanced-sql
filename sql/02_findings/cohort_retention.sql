-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Finding: Monthly Cohort Retention
-- Business Question: What percentage of customers return to
--                    order again after their first purchase?
--
-- Why this matters: Retention is the single most important
-- metric for any marketplace. Acquiring customers costs money —
-- if they buy once and never return, that cost is never
-- recovered. This is the table product and growth teams
-- review weekly.
--
-- Critical data note: customer_unique_id (not customer_id) is
-- the true person identifier in Olist. Using customer_id makes
-- every order look like a new customer — a data trap that
-- produces completely wrong retention numbers.
--
-- Concepts: Multi-stage CTE, PERIOD_DIFF, cohort logic, retention %
-- Author: Brijesh Vaghela
-- ============================================================
USE olist;

WITH first_order AS (
    -- Stage 1: each customer's first order date = their cohort
    SELECT
        c.customer_unique_id,
        MIN(DATE(o.order_purchase_timestamp))                  AS first_order_date,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m')  AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status != 'canceled'
    GROUP BY c.customer_unique_id
),
order_activity AS (
    -- Stage 2: for every order, calculate months since first order
    SELECT
        c.customer_unique_id,
        f.cohort_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),
            DATE_FORMAT(f.first_order_date, '%Y%m')
        ) AS month_number
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN first_order f ON c.customer_unique_id = f.customer_unique_id
    WHERE o.order_status != 'canceled'
),
cohort_size AS (
    -- Stage 3: how many customers in each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_customers
    FROM first_order
    GROUP BY cohort_month
),
monthly_retention AS (
    -- Stage 4: how many from each cohort were active at each month offset
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM order_activity
    GROUP BY cohort_month, month_number
)
-- Stage 5: retention rate
SELECT
    mr.cohort_month,
    mr.month_number,
    cs.cohort_customers,
    mr.active_customers,
    ROUND(mr.active_customers / cs.cohort_customers * 100, 1) AS retention_pct
FROM monthly_retention mr
JOIN cohort_size cs ON cs.cohort_month = mr.cohort_month
WHERE mr.month_number BETWEEN 0 AND 12
ORDER BY mr.cohort_month, mr.month_number;