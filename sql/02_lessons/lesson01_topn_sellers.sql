-- ============================================================
-- Olist Advanced SQL Business Case Study
-- Lesson 01: Top-N Per Group (Window Functions - Ranking)
-- Business Question: Top 3 sellers by revenue in each
--                    of Olist's top 5 product categories
-- ============================================================
USE olist;

WITH category_seller_rev AS (
    SELECT
        ct.product_category_name_english AS category,
        oi.seller_id,
        SUM(oi.price)                    AS seller_revenue
    FROM order_items oi
    JOIN products p
        ON p.product_id = oi.product_id
    JOIN category_translation ct
        ON ct.product_category_name = p.product_category_name
    GROUP BY ct.product_category_name_english, oi.seller_id
),
ranked AS (
    SELECT
        category,
        seller_id,
        seller_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY seller_revenue DESC, seller_id ASC
        ) AS rev_rank
    FROM category_seller_rev
),
top_categories AS (
    SELECT category
    FROM category_seller_rev
    GROUP BY category
    ORDER BY SUM(seller_revenue) DESC
    LIMIT 5
)
SELECT
    r.category,
    r.seller_id,
    r.seller_revenue,
    r.rev_rank
FROM ranked r
JOIN top_categories tc ON tc.category = r.category
WHERE r.rev_rank <= 3
ORDER BY r.category, r.rev_rank;