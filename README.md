# Olist E-Commerce — Advanced SQL Business Case Study

A business case study built on the Olist Brazilian E-Commerce
dataset — 8 relational tables, 100K+ orders, real data with
real messiness. Each query answers a specific business question:
seller concentration risk, cohort retention, revenue trajectory,
delivery SLA impact on reviews.

The dataset has embedded newlines in review text, Portuguese
category names requiring translation joins, and NULL delivery
timestamps for cancelled orders — the kind of data quality
issues that don't exist in tutorial datasets but show up in
every production database.

**Stack:** MySQL 8.0 · Python (pandas, SQLAlchemy)

---

## What I built

13 advanced SQL analyses across three business domains:

**Seller Performance**

- Top 3 sellers by revenue per product category — and what the
  revenue gap between rank 1 and rank 3 tells you about category
  concentration risk
- Sellers outperforming their state's average rating
- Seller scorecard (capstone) — multi-dimensional ranking combining
  revenue, late delivery rate, and average review score

**Customer Behaviour**

- Monthly cohort retention in pure SQL — no Python, no pivoting outside the DB
- Customers with the longest consecutive ordering streaks (gaps & islands)
- City and state-level order volume distribution

**Revenue & Operations**

- Cumulative GMV + rolling 7-day revenue trend
- Month-over-month revenue growth using LAG()
- Month-over-month order count growth per category
- Running total of orders per category using PARTITION BY
- Late delivery rate and its measurable impact on review scores
- Payment method and installment behaviour by region
- Order value percentiles and revenue concentration by decile

---

## SQL techniques demonstrated

| Technique | Where it's used |
|-----------|----------------|
| `ROW_NUMBER()` with `PARTITION BY` | Top-N sellers per category; top cities per state |
| `LAG()` with `PARTITION BY` | MoM revenue growth; MoM order growth per category |
| `ROWS BETWEEN` window frames | Cumulative GMV; 7-day moving average |
| 5-stage CTE cohort logic | Monthly retention pivot — cohort → offset → active count → % |
| Gaps & Islands | Row_number subtraction to detect consecutive ordering streaks |
| `AVG() OVER PARTITION BY` | State-level seller benchmark comparisons |
| `NTILE(100)` and `NTILE(10)` | Order value percentiles and decile revenue share |
| Conditional aggregation pivot | Payment method mix across 17 states |
| Multi-CTE + `RANK()` + `CASE WHEN` | Capstone scorecard — 3 dimensions ranked simultaneously |
| `DATEDIFF` + NULL handling | Delivery SLA compliance — late vs on-time classification |

---

## The dataset

**Source:** [Brazilian E-Commerce Public Dataset — Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

**Database:** MySQL 8.0

**Scale:** 8 tables, ~530K rows total across all tables

| Table | Rows | What it contains |
|-------|------|-----------------|
| orders | 99,441 | The spine — status + 5 timestamps from purchase to delivery |
| order_items | 112,650 | Line items — price, freight, which seller fulfilled it |
| order_payments | 103,886 | Payment type, installments, value |
| order_reviews | 99,224 | 1–5 scores + free-text comments |
| customers | 99,441 | City, state — no PII |
| products | 32,951 | Category, physical dimensions |
| sellers | 3,095 | City, state |
| category_translation | 71 | Portuguese to English category names |

---

## Setup notes

Two real data quality issues worth documenting:

**1. The reviews CSV breaks bulk loading.**

`LOAD DATA INFILE` fails at row 77,917 because customer review
text contains embedded newlines and imperfectly escaped quotes.
MySQL's line parser trips on them. The fix is pandas — a proper
CSV parser that handles multi-line quoted fields. The other 7
tables load fine via bulk load. See `python/load_reviews.py`.

**2. Category names loaded with trailing carriage return characters.**

Windows CRLF line endings in `product_category_name_translation.csv`
left carriage returns on every English category name — silently
breaking every JOIN on that column with no error, just missing data.
A single UPDATE with REPLACE() cleaned it. Small bug, but the kind
that takes hours to track down if you don't know to look for it.

---

## Repo structure

    olist-advanced-sql/
    ├── sql/
    │   ├── 01_setup/
    │   │   ├── 01_create_tables.sql               schema + foreign keys for 8 tables
    │   │   └── 02_load_data.sql                   bulk load 7 tables + notes on reviews
    │   └── 02_findings/
    │       ├── top_sellers_by_category.sql         top-N sellers per category
    │       ├── top_cities_by_state.sql             top-3 cities per state
    │       ├── revenue_running_total.sql           rolling GMV + 7-day moving avg
    │       ├── category_orders_running_total.sql   running total of orders per category
    │       ├── monthly_revenue_growth.sql          month-over-month revenue growth (LAG)
    │       ├── category_mom_order_growth.sql       month-over-month order count per category
    │       ├── cohort_retention.sql                monthly cohort retention analysis
    │       ├── customer_order_streaks.sql          longest consecutive ordering streaks
    │       ├── sellers_above_state_avg_rating.sql  sellers outperforming state average
    │       ├── delivery_sla_review_impact.sql      late delivery rate and review score impact
    │       ├── payment_behaviour_by_state.sql      payment method and installment mix by state
    │       ├── order_value_percentiles.sql         order value percentiles and revenue concentration
    │       └── seller_scorecard.sql                capstone — seller revenue, quality and delivery
    ├── python/
    │   └── load_reviews.py                        pandas loader for order_reviews CSV
    ├── docs/
    │   └── business_case.md                       findings + business interpretation
    └── data/                                      not tracked — download from Kaggle

---

## Key findings

### Seller concentration by category

`watches_gifts` top 3 sellers: R$201K / R$192K / R$170K —
tight competition, no single seller has outsized leverage.

`bed_bath_table` top 3: R$165K / R$152K / R$55K — the drop-off to
rank 3 is steep, meaning two sellers dominate this category and
hold significant commission negotiation power over the platform.

### City concentration by state

DF (Brasília) shows extreme concentration — 2,131 orders from
the capital vs just 4 from the next city. SP shows healthier
distribution across São Paulo (15,540), Campinas (1,444), and
Guarulhos (1,189) — multiple cities absorbing meaningful demand.

### Olist GMV trajectory

First ever order: R$72.89 on September 4, 2016.
Total GMV across the dataset: R$13,496,408 by September 2018.

The October 2016 inflection — revenue jumping from R$441 to
R$9,571 in a single day — marks when the platform meaningfully
opened to sellers. The 7-day moving average makes this
acceleration visible where raw daily numbers just look like noise.

### Revenue growth phases

Three distinct phases: explosive early growth in 2017 (50–100%
MoM), a Black Friday peak in November 2017 at R$1,003,862
(+52.1% MoM — the only month to cross R$1M), and a plateau
from April 2018 onward with single-digit or negative growth
hovering around R$850K–R$1M monthly.

### Customer retention — the one-time buyer problem

Month-1 retention is below 1% across every cohort. Even
the massive November 2017 Black Friday cohort (7,270 new
customers) retained just 0.6% the next month. Olist's
revenue depends entirely on acquiring new customers every
month — there is no meaningful returning customer base.

### Loyal customers — 0.011% of the base

Only 11 customers out of 99,441 ordered in 3 or more consecutive
months. The single most loyal customer maintained a 7-month
streak. This confirms Olist is structurally a one-time-buyer
marketplace — loyalty programs and reactivation campaigns would
have near-zero ROI. The correct optimisation is acquisition
efficiency and first-order margin.

### Delivery SLA — 1.72 star penalty per late order

8% of delivered orders arrived late. On-time orders average
4.29 stars; late orders average 2.57 — a 1.72 star gap.
Olist deliberately under-promises on delivery estimates:
on-time orders arrive an average of 13.7 days *before* the
estimated date, driving positive surprise. The worst late
delivery was 188 days overdue.

### Payment behaviour — regional affordability signal

Credit card dominates nationally (69–84%) but boleto usage
peaks in Brazil's poorest northern states (AP 29%, RR 29%,
MA 27%). Installment counts and order values rise together
in the North/Northeast — PB averages 3.8 installments on
R$248 orders vs SP's 2.6 installments on R$137. Higher-value
purchases in lower-income regions are financed across more
monthly payments to remain affordable.

### Order value distribution — median R$104, top 10% drive 38% of revenue

Median order value is R$104 — a mid-range household item.
The top 10% of orders (above R$307) generate 38.1% of total
revenue; the top 20% generate over 53%. Classic Pareto
concentration. The maximum single order was R$13,664 —
nearly 130× the median — which is why average order value
is a misleading metric for this dataset.

### Capstone — Seller scorecard: revenue vs quality vs delivery

A multi-dimensional seller ranking combining revenue, late
delivery rate, and avg review score. The headline finding:
the rank 5 seller by revenue does R$188K but averages just
3.35 stars — high revenue masking a platform trust risk.
The best overall performer is rank 2: a BA-based seller with
R$223K revenue, 4.0% late delivery, and 4.08 stars. 20 of
the top 30 revenue sellers are in SP, confirming Olist's
geographic revenue concentration risk.

Four seller segments identified: Star Sellers (rating ≥ 4.0,
late delivery ≤ 10%), High Revenue Risk (revenue > R$50K,
rating < 3.5), Quality Risk (rating < 3.0), and Standard.

---

**Brijesh Vaghela**

[LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) ·
[GitHub](https://github.com/Brijesh403) ·
See also: [ShopSense Product Analytics](https://github.com/Brijesh403/shopsense-product-analytics)
