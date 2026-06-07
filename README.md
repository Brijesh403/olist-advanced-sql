# Olist E-Commerce — Advanced SQL Business Case Study

> 12 SQL analyses on a real Brazilian e-commerce dataset — seller concentration risk, cohort retention, revenue trajectory, delivery SLA impact, and more. Every query answers a question a product, growth, or ops team actually asks.

**Stack:** MySQL 8.0 · Python (pandas, SQLAlchemy)  
**Dataset:** [Brazilian E-Commerce Public Dataset — Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle) · 8 tables · ~530K rows

---

## SQL Techniques Demonstrated

| Technique | Applied In |
|-----------|-----------|
| `ROW_NUMBER()` with `PARTITION BY` | Top-N sellers per category, top cities per state |
| `LAG()` with `PARTITION BY` | Month-over-month revenue and category order growth |
| `ROWS BETWEEN` window frames | Running totals, 7-day moving averages |
| 5-stage CTE cohort logic | Monthly cohort retention pivot table |
| Gaps & Islands (row_number subtraction) | Longest consecutive ordering streaks |
| `AVG() OVER PARTITION BY` | State-level benchmark comparisons |
| `NTILE()` for percentile buckets | Order value distribution, decile revenue share |
| Conditional aggregation pivot | Payment method mix by state |
| Multi-CTE + `RANK()` + `CASE WHEN` | Capstone multi-dimensional seller scorecard |
| `DATEDIFF` + NULL handling | Delivery SLA compliance analysis |

---

## The Dataset

8 relational tables, ~530K rows total. Real data — embedded newlines in review text, Portuguese category names requiring translation joins, and NULL delivery timestamps for cancelled orders. The kind of data quality issues that don't exist in tutorial datasets but appear in every production database.

| Table | Rows | What it contains |
|-------|------|-----------------|
| orders | 99,441 | The spine — status + 5 timestamps from purchase to delivery |
| order_items | 112,650 | Line items — price, freight, which seller fulfilled it |
| order_payments | 103,886 | Payment type, installments, value |
| order_reviews | 99,224 | 1–5 scores + free-text comments |
| customers | 99,441 | City, state — no PII |
| products | 32,951 | Category, physical dimensions |
| sellers | 3,095 | City, state |
| category_translation | 71 | Portuguese → English category names |

---

## Analyses

**Seller Performance**
- Top 3 sellers by revenue per product category — revenue gap reveals category concentration risk
- Sellers outperforming their state's average rating — benchmark identification for Top Seller badges
- Seller scorecard (capstone) — multi-dimensional ranking across revenue, delivery, and review score

**Customer Behaviour**
- Monthly cohort retention — in pure SQL, no Python, no pivoting outside the database
- Consecutive ordering streaks — gaps & islands technique to find Olist's most loyal customers
- City and state order volume — where demand actually lives, for logistics and marketing prioritisation

**Revenue & Operations**
- Running GMV + 7-day moving average — cumulative revenue trajectory from the first ever order
- Month-over-month revenue growth — LAG() to calculate MoM % change across 24 months
- Category MoM order growth — isolates volume signal from revenue signal per category
- Category order accumulation — per-category running totals using `PARTITION BY`
- Delivery SLA compliance — late delivery rate and its measurable impact on review scores
- Payment method & installment behaviour by state — regional affordability and payment mix
- Order value percentiles — median, decile distribution, and revenue concentration

---

## Key Findings

**Seller concentration risk**  
`bed_bath_table` top 3 sellers: R$165K / R$152K / R$54K — a steep drop to rank 3. Two sellers dominate and hold significant commission negotiation leverage. `watches_gifts` top 3: R$201K / R$192K / R$169K — healthy competition, no outsized leverage.

**The one-time-buyer problem**  
Month-1 retention is below 1% across every single cohort. The November 2017 Black Friday cohort acquired 7,270 customers — only 40 returned the next month (0.6%). Only 11 customers out of 99,441 ordered in 3+ consecutive months. Olist's revenue depends entirely on continuous new customer acquisition. Loyalty programs and reactivation campaigns would have near-zero ROI at this retention rate.

**GMV trajectory**  
First order: R$72.89 on September 4, 2016. Total GMV: R$13,496,408 by September 2018. The October 2016 inflection — daily revenue jumping from R$441 to R$9,571 — marks when the platform meaningfully opened to sellers.

**Revenue growth phases**  
Three distinct phases: explosive early growth in 2017 (50–100% MoM), a Black Friday peak in November 2017 at R$1,003,862 (+52.1% — the only month to cross R$1M), then a plateau from April 2018 with single-digit or negative growth around R$850K–R$1M monthly.

**Delivery SLA — the 1.72-star penalty**  
8% of delivered orders arrived late. On-time orders average 4.29 stars; late orders average 2.57 — a 1.72-star gap. Olist deliberately under-promises: on-time orders arrive an average of 13.7 days *before* the estimated date, driving the high rating on on-time deliveries. The worst late delivery was 188 days overdue.

**Payment behaviour — regional affordability signal**  
Credit card dominates nationally (69–84%) but boleto usage peaks in Brazil's poorest northern states (AP 29%, RR 29%, MA 27%). PB (Paraíba) averages 3.8 installments on R$248 orders vs SP's 2.6 installments on R$137 — higher-value purchases in lower-income regions financed across more monthly payments.

**Order value distribution**  
Median order: R$104. Top 10% of orders (above R$307) generate 38.1% of total revenue; top 20% generate over 53%. Max single order: R$13,664 — nearly 130x the median. Average order value is a misleading metric for this dataset.

**Capstone: the risk hiding in revenue**  
The rank-5 seller by revenue does R$187K but averages just 3.35 stars — high revenue masking a platform trust risk. 23 of the top 30 revenue sellers are in SP, confirming geographic concentration risk. The best overall performer: a BA seller at rank 2, 4% late delivery rate, 4.08 stars.

---

## Data Quality Notes

**Reviews CSV breaks bulk loading.**  
`LOAD DATA INFILE` fails at row 77,917 because customer review text contains embedded newlines and imperfectly escaped quotes. Fix: load via pandas, which handles multi-line quoted fields natively. The other 7 tables bulk-load cleanly. See `python/load_reviews.py`.

**Carriage return characters on category names.**  
Windows CRLF line endings in `product_category_name_translation.csv` left `\r` on every English category name — silently breaking all JOIN matches on that column. Fixed with a single `UPDATE` using `REPLACE(product_category_name_english, '\r', '')`.

---

## Repo Structure

    olist-advanced-sql/
    ├── sql/
    │   ├── 01_setup/
    │   │   ├── 01_create_tables.sql               schema + foreign keys for 8 tables
    │   │   └── 02_load_data.sql                   bulk load 7 tables + reviews workaround note
    │   └── 02_findings/
    │       ├── top_sellers_by_category.sql         top-N sellers per category (ROW_NUMBER)
    │       ├── top_cities_by_state.sql             top-3 cities per state
    │       ├── revenue_running_total.sql           rolling GMV + 7-day moving average
    │       ├── category_orders_running_total.sql   per-category running totals (PARTITION BY)
    │       ├── monthly_revenue_growth.sql          month-over-month revenue growth (LAG)
    │       ├── category_mom_order_growth.sql       MoM order count per category
    │       ├── cohort_retention.sql                monthly cohort retention pivot
    │       ├── customer_order_streaks.sql          longest consecutive ordering streaks
    │       ├── sellers_above_state_avg_rating.sql  benchmark comparison (AVG OVER PARTITION BY)
    │       ├── delivery_sla_review_impact.sql      SLA compliance + review score impact
    │       ├── payment_behaviour_by_state.sql      regional payment mix and installments
    │       ├── order_value_percentiles.sql         NTILE percentiles + decile revenue share
    │       └── seller_scorecard.sql                capstone — multi-dimensional seller ranking
    ├── python/
    │   └── load_reviews.py                        pandas loader for order_reviews CSV
    ├── docs/
    │   └── business_case.md                       full findings + business interpretation
    └── data/                                      not tracked — download from Kaggle

---

## How to Run

1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place all CSVs in `data/`
2. Run `sql/01_setup/01_create_tables.sql` in MySQL Workbench or the CLI
3. Update the file paths in `sql/01_setup/02_load_data.sql` to match your MySQL `secure_file_priv` directory
4. Run `sql/01_setup/02_load_data.sql` to load the 7 bulk-loadable tables
5. Install Python dependencies: `pip install pandas sqlalchemy pymysql`
6. Set your DB credentials as environment variables, then run `python/load_reviews.py` to load order reviews
7. Run any file in `sql/02_findings/` independently — each query is self-contained

---

**Brijesh Vaghela** · [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) · [GitHub](https://github.com/Brijesh403)  
See also: [ShopSense Product Analytics](https://github.com/Brijesh403/shopsense-product-analytics)
