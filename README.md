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

`watches_gifts` top 3 sellers are within 16% of each other —
tight competition, no single seller has outsized leverage.
`bed_bath_table` tells a different story: the drop-off to rank 3
is steep, meaning two sellers dominate and hold significant
commission negotiation power over the platform.

| Category | Rank 1 | Rank 2 | Rank 3 | Signal |
|----------|--------|--------|--------|--------|
| watches_gifts | R$201K | R$192K | R$170K | Healthy — within 16% |
| health_beauty | R$79K | R$72K | R$66K | Healthy |
| bed_bath_table | R$165K | R$152K | R$55K | Risk — 3× gap to rank 3 |
| computers_accessories | R$53K | R$52K | R$47K | Healthy — very tight |
| sports_leisure | R$54K | R$42K | R$42K | Moderate |

### City concentration by state

DF (Brasília) shows extreme concentration — 2,131 orders from
the capital vs just 4 from the next city. SP shows the healthiest
distribution with three cities each absorbing meaningful volume.

| State | City #1 | Orders | City #2 | Orders | City #3 | Orders |
|-------|---------|--------|---------|--------|---------|--------|
| SP | São Paulo | 15,540 | Campinas | 1,444 | Guarulhos | 1,189 |
| RJ | Rio de Janeiro | 6,882 | Niterói | 849 | Nova Iguaçu | 442 |
| MG | Belo Horizonte | 2,773 | Juiz de Fora | 427 | Contagem | 426 |
| BA | Salvador | 1,245 | Feira de Santana | 185 | Vitória da Conquista | 92 |
| DF | Brasília | 2,131 | Taguatinga | 4 | Guará | 2 |

### Olist GMV trajectory

First ever order: R$72.89 on September 4, 2016.
Total GMV across the dataset: R$13,496,408 by September 2018.

The October 2016 inflection — revenue jumping from R$441 to
R$9,571 in a single day — marks when the platform meaningfully
opened to sellers. The 7-day moving average makes this
acceleration visible where raw daily numbers just look like noise.

| Milestone | Date | Value |
|-----------|------|-------|
| First ever order | 2016-09-04 | R$72.89 |
| Platform inflection (single day) | 2016-10-04 | R$9,571 daily revenue |
| Black Friday peak (monthly) | 2017-11 | R$1,003,862 |
| Total GMV (end of dataset) | 2018-09-03 | R$13,496,408 |

### Revenue growth phases

Three distinct phases visible in the MoM data: explosive early
growth in 2017, a Black Friday spike that was never repeated,
and a plateau that signals market saturation.

| Period | Revenue | MoM Growth | Phase |
|--------|---------|------------|-------|
| 2017-03 | R$368K | +50.4% | Explosive growth |
| 2017-05 | R$503K | +42.2% | Explosive growth |
| 2017-11 | R$1,003K | +52.1% | Black Friday peak — only month above R$1M |
| 2017-12 | R$742K | −26.1% | Post-holiday unwind |
| 2018-04 | R$993K | +1.3% | Plateau begins |
| 2018-05 | R$992K | −0.1% | Plateau |

### Customer retention — the one-time buyer problem

Month-1 retention is below 1% across every single cohort — not
just one bad month, every month in the dataset. Olist's revenue
depends entirely on acquiring new customers every month. There
is no meaningful returning customer base.

| Cohort | Acquired (m0) | Returned (m1) | m1 Retention |
|--------|--------------|--------------|--------------|
| 2017-01 | 762 | 3 | 0.4% |
| 2017-05 | 3,571 | 17 | 0.5% |
| 2017-08 | 4,162 | 28 | 0.7% |
| 2017-11 (Black Friday) | 7,270 | 40 | 0.6% |
| 2018-01 | 6,992 | 23 | 0.3% |
| 2018-04 | 6,700 | 39 | 0.6% |

### Loyal customers — 0.011% of the base

Only 11 customers out of 99,441 ordered in 3 or more consecutive
months. The single most loyal customer maintained a 7-month
streak. Loyalty programs and reactivation campaigns would have
near-zero ROI at this retention level. The correct optimisation
is acquisition efficiency and first-order margin.

| Customer (hashed) | Streak | From | To |
|-------------------|--------|------|----|
| 8d50f5ea... | 7 months | 2017-05 | 2018-08 |
| 6469f99c... | 5 months | 2017-09 | 2018-06 |
| 1b6c7548... | 4 months | 2017-11 | 2018-02 |
| 8 others | 3 months | various | various |

### Delivery SLA — 1.72 star penalty per late order

8% of delivered orders arrived late. Olist deliberately
under-promises on delivery estimates — on-time orders arrive
an average of 13.7 days *before* the estimated date, driving
positive surprise and a strong 4.29 average rating. The worst
late delivery in the dataset was 188 days overdue.

| Status | Orders | % of Total | Avg Rating | Avg Days vs Estimate |
|--------|--------|-----------|------------|---------------------|
| On Time | 88,653 | 92% | 4.29 ⭐ | −13.7 days (early) |
| Late | 7,700 | 8% | 2.57 ⭐ | +8.8 days (late) |

### Payment behaviour — regional affordability signal

Credit card dominates nationally (69–84%) but boleto — the
payment method of the unbanked — peaks in Brazil's poorest
northern states. Installment counts and order values rise
together in the North/Northeast: higher-value purchases in
lower-income regions are financed across more monthly payments
to remain affordable.

| State | Orders | Credit Card | Boleto | Avg Installments | Avg Order Value |
|-------|--------|------------|--------|-----------------|----------------|
| SP | 41,418 | 77.1% | 19.7% | 2.6 | R$137 |
| RJ | 12,766 | 80.1% | 16.8% | 3.0 | R$158 |
| MA | 743 | 71.7% | 27.1% | 3.1 | R$199 |
| PB | 534 | 80.0% | 17.4% | 3.8 | R$248 |
| TO | 279 | 70.3% | 27.2% | 3.0 | R$204 |
| AP | 68 | 69.1% | 29.4% | 2.6 | R$232 |
| RR | 45 | 71.1% | 28.9% | 2.8 | R$221 |

### Order value distribution — median R$104, top 10% drive 38% of revenue

Median order value is R$104 — a mid-range household item.
Classic Pareto concentration at the top. The maximum single
order was R$13,664 — nearly 130× the median — which is exactly
why average order value is a misleading headline metric here.

| Percentile | Order Value | Notes |
|------------|-------------|-------|
| 25th | R$61 | Bottom quarter |
| 50th (median) | R$104 | Typical order |
| 75th | R$175 | Upper half |
| 90th | R$297 | High-value threshold |
| Top 10% decile | R$307+ | Generates 38.1% of total revenue |
| Top 20% decile | R$243+ | Generates 53%+ of total revenue |
| Maximum | R$13,664 | 130× the median |

### Capstone — Seller scorecard: revenue vs quality vs delivery

A multi-dimensional seller ranking combining revenue, late
delivery rate, and avg review score. The headline finding:
rank 5 does R$188K but averages 3.35 stars — high revenue
masking a platform trust risk. 20 of the top 30 revenue
sellers are in SP, confirming Olist's geographic concentration.

Four seller segments: **Star Sellers** (rating ≥ 4.0, late ≤ 10%),
**High Revenue Risk** (revenue > R$50K, rating < 3.5),
**Quality Risk** (rating < 3.0), and **Standard**.

| Revenue Rank | State | Revenue | Late % | Avg Rating | Segment |
|-------------|-------|---------|--------|------------|---------|
| 1 | SP | R$229K | 11.6% | 4.13 ⭐ | Standard |
| 2 | BA | R$223K | 4.0% | 4.08 ⭐ | Star Seller ✓ |
| 3 | SP | R$200K | 11.0% | 3.80 ⭐ | Standard |
| 4 | SP | R$193K | 10.2% | 4.34 ⭐ | Standard |
| 5 | SP | R$188K | 9.6% | 3.35 ⭐ | High Revenue Risk ⚠ |

---

**Brijesh Vaghela**

[LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) ·
[GitHub](https://github.com/Brijesh403) ·
See also: [ShopSense Product Analytics](https://github.com/Brijesh403/shopsense-product-analytics)
