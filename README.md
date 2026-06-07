# Olist E-Commerce — SQL Product Analytics

**12 business questions. 12 SQL analyses. Every answer backed by real data.**

Brazil's largest e-commerce dataset — 8 tables, 530K rows, real messiness. This is not a tutorial project. The data has embedded newlines in review text, Portuguese category names that silently break JOINs, and NULL timestamps across cancelled orders. The queries answer questions a product, growth, or ops team would actually bring to an analyst.

**Stack:** MySQL 8.0 · Python (pandas, SQLAlchemy)  
**Dataset:** [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

---

## What the data revealed

These are not observations. These are findings that would go straight into a product review.

---

### "7,270 customers acquired on Black Friday. 40 came back the next month."

Month-1 retention sits below **1% across every single cohort** in the dataset — not just one bad month, every month. The November 2017 Black Friday cohort is the starkest example: 7,270 new customers, **40 returned** (0.6%). Digging further with a gaps-and-islands streak analysis: **only 11 customers out of 99,441** ever ordered in 3 or more consecutive months. That's 0.011% of the base.

The strategic implication is clear: Olist is structurally a one-time-buyer marketplace. Loyalty programs and reactivation campaigns would have near-zero ROI. The correct optimization is first-order margin and acquisition cost — not retention.

*Techniques: 5-stage CTE cohort retention pivot, PERIOD_DIFF, Gaps & Islands (row_number subtraction)*

---

### "A late delivery costs exactly 1.72 stars."

8% of delivered orders arrived late. On-time orders average **4.29 stars**. Late orders average **2.57 stars** — a gap of **1.72 stars** on a 5-point scale. That is the difference between a platform customers recommend and one they warn people about.

The more interesting finding: on-time orders arrive an average of **13.7 days before** the estimated date. Olist deliberately under-promises on delivery estimates. The strategy works — customers expecting delivery in 2 weeks receive it in under 1 week, and that surprise drives the 4.29 average. The worst late delivery in the dataset was **188 days** overdue.

*Techniques: DATEDIFF, CASE WHEN classification, SUM() OVER () for % share without self-join*

---

### "The rank-5 seller looks like a success story. It isn't."

Revenue rank 5: **R$188K**. Average review score: **3.35 stars**. A single-metric revenue view would flag this seller for a bonus. A multi-dimensional scorecard flags them for a customer trust intervention.

Rank 1 (R$229K, 4.13 stars, 11.6% late) is Standard — high revenue but misses Star Seller on delivery. The genuinely best seller is rank 2: a **BA-based seller** with R$223K revenue, **4.0% late delivery**, and **4.08 stars** — lower volume, higher quality, better platform citizen.

**20 of the top 30 revenue sellers are in SP.** Olist's revenue base is geographically concentrated — a meaningful risk if a competitor targets SP sellers specifically.

*Techniques: 4-stage parallel CTEs, RANK() across 3 dimensions simultaneously, NTILE(4), CASE WHEN segmentation*

---

### "R$13.5M GMV in 24 months — and it plateaued."

First ever order: **R$72.89** on September 4, 2016. By September 2018: **R$13,496,408** in cumulative GMV. Three distinct phases are visible in the month-over-month data:

- **Early 2017:** Explosive growth, 50–100% MoM, platform scaling from near-zero
- **November 2017:** Black Friday pushed Olist past **R$1,003,862** (+52.1%) — the only month in the entire dataset to cross R$1M
- **April 2018 onward:** Plateau. Single-digit and negative MoM growth around R$850K–R$1M. A signal that current market penetration may be saturating.

The October 2016 inflection — daily revenue jumping from R$441 to R$9,571 in a single day — pinpoints when the platform meaningfully opened to sellers.

*Techniques: LAG() for MoM growth, SUM() OVER with ROWS BETWEEN UNBOUNDED PRECEDING for cumulative GMV, 7-day moving average with ROWS BETWEEN 6 PRECEDING*

---

### "The top 10% of orders generate 38% of revenue. The median is R$104."

Half of all Olist orders are below **R$104** — a mid-range household item, not a luxury purchase. The distribution is classic Pareto: top 10% of orders (above R$307) generate **38.1%** of total revenue. Top 20% generate over 53%.

The maximum single order was **R$13,664** — nearly 130× the median. This is exactly why average order value is a misleading headline metric. It hides the mass-market base that actually drives volume.

*Techniques: NTILE(100) for percentile buckets, NTILE(10) for decile revenue share, SUM() OVER () for running revenue %*

---

### "bed_bath_table has a seller concentration problem. watches_gifts doesn't."

In the top 5 revenue categories, two tell very different stories about platform risk:

| Category | Rank 1 | Rank 2 | Rank 3 | Signal |
|----------|--------|--------|--------|--------|
| watches_gifts | R$201K | R$192K | R$170K | Healthy — top 3 within 16% |
| bed_bath_table | R$165K | R$152K | R$55K | Risk — ranks 1 & 2 earn 3× rank 3 |

In `bed_bath_table`, losing either of the top two sellers would devastate category revenue. In `watches_gifts`, no single seller has outsized leverage — healthy competition. A category manager uses this to prioritize retention incentives before contract renewal.

*Techniques: ROW_NUMBER() PARTITION BY, 3-stage CTE pattern, top-N per group*

---

### "Boleto usage in AP is 29.4%. In SP it's 19.7%. That's not a payment preference — it's an affordability signal."

Credit card dominates nationally (69–84%) but boleto — the payment method of the unbanked, payable at any lottery shop — peaks in Brazil's poorest northern states: **AP 29.4%, RR 28.9%, TO 27.2%, MA 27.1%**.

The installment pattern confirms it: PB (Paraíba) averages **3.8 installments on R$248 orders**. SP averages **2.6 installments on R$137 orders**. Higher-value purchases in lower-income regions require more monthly payments to remain affordable. Payment processor negotiations, regional promotions, and pricing strategy all look different when you see this breakdown by state.

*Techniques: Conditional aggregation pivot (SUM CASE WHEN), percentage calculation across 17 states*

---

## SQL Techniques

| Technique | What it achieved |
|-----------|----------------|
| `ROW_NUMBER()` with `PARTITION BY` | Top-N sellers per category; top cities per state — independent leaderboards per group |
| `LAG()` with `PARTITION BY` | MoM revenue growth; category-level order volume trends |
| `ROWS BETWEEN` window frames | Cumulative GMV from first order; 7-day smoothed revenue trend |
| 5-stage CTE cohort logic | Full monthly retention pivot — cohort size → month offset → active count → % |
| Gaps & Islands | Subtracting row_number from month_number to identify consecutive-ordering streaks |
| `AVG() OVER PARTITION BY` | State-level seller benchmark — one pass, no self-join |
| `NTILE(100)` and `NTILE(10)` | Percentile distribution and decile revenue concentration |
| Conditional aggregation pivot | Payment method mix across 17 states in a single query |
| Parallel CTEs + `RANK()` + `CASE WHEN` | Capstone scorecard — revenue, delivery, and quality ranked simultaneously |
| `DATEDIFF` + NULL filtering | Delivery SLA compliance — excluding cancelled and in-transit orders cleanly |

---

## The Dataset

8 relational tables, ~530K rows. This is real production data with real data quality issues.

| Table | Rows | What it contains |
|-------|------|-----------------|
| orders | 99,441 | Order spine — status + 5 timestamps from purchase to delivery |
| order_items | 112,650 | Line items — price, freight, seller |
| order_payments | 103,886 | Payment type, installment count, value |
| order_reviews | 99,224 | 1–5 star scores + free-text comments |
| customers | 99,441 | City, state — no PII |
| products | 32,951 | Category, physical dimensions |
| sellers | 3,095 | City, state |
| category_translation | 71 | Portuguese → English category names |

---

## Data Quality Challenges Encountered

**The reviews CSV breaks bulk loading.**  
`LOAD DATA INFILE` fails at row 77,917. Customer review text contains embedded newlines and improperly escaped quotes — MySQL's line parser can't handle them. Fix: pandas, which parses multi-line quoted fields natively. See `python/load_reviews.py`. This is the kind of issue that stops a junior analyst cold. Knowing *why* it fails and how to route around it is the actual skill.

**Carriage return characters silently breaking every JOIN.**  
Windows CRLF line endings in `product_category_name_translation.csv` left `\r` on the end of every English category name. Every JOIN on that column returned zero matches — no error, just missing data. Fix: `UPDATE ... SET product_category_name_english = REPLACE(product_category_name_english, '\r', '')`. Caught by noticing that category translation joins were returning NULL for every product.

---

## Repo Structure

    olist-advanced-sql/
    ├── sql/
    │   ├── 01_setup/
    │   │   ├── 01_create_tables.sql               schema + foreign keys, 8 tables
    │   │   └── 02_load_data.sql                   bulk load + reviews workaround note
    │   └── 02_findings/
    │       ├── top_sellers_by_category.sql         top-N sellers per category
    │       ├── top_cities_by_state.sql             top-3 cities per state
    │       ├── revenue_running_total.sql           cumulative GMV + 7-day moving avg
    │       ├── category_orders_running_total.sql   per-category running totals
    │       ├── monthly_revenue_growth.sql          MoM revenue growth
    │       ├── category_mom_order_growth.sql       MoM order count per category
    │       ├── cohort_retention.sql                monthly cohort retention pivot
    │       ├── customer_order_streaks.sql          consecutive ordering streaks
    │       ├── sellers_above_state_avg_rating.sql  state-level benchmark comparison
    │       ├── delivery_sla_review_impact.sql      SLA compliance + review impact
    │       ├── payment_behaviour_by_state.sql      payment mix across 17 states
    │       ├── order_value_percentiles.sql         percentile + decile distribution
    │       └── seller_scorecard.sql                capstone — multi-dimensional ranking
    ├── python/
    │   └── load_reviews.py                        pandas loader for order_reviews CSV
    ├── docs/
    │   └── business_case.md                       full findings + SQL approach + business insight
    └── data/                                      not tracked — download from Kaggle

---

**Brijesh Vaghela** · [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) · [GitHub](https://github.com/Brijesh403)  
See also: [ShopSense Product Analytics](https://github.com/Brijesh403/shopsense-product-analytics)
