# Olist E-Commerce — Advanced SQL Business Case Study

I built this project because I wanted to move past basic SQL.
GROUP BY and LIMIT will get you through a tutorial — they won't get 
you through a live SQL interview round. This is my attempt to close 
that gap using a real, publicly available dataset that the data 
community actually respects.

The Olist Brazilian E-Commerce dataset has 8 relational tables, 
100K+ orders, real messiness (embedded newlines in review text, 
Portuguese category names, NULL delivery timestamps for cancelled 
orders), and enough business surface area to ask questions that 
actually mean something. That's why I picked it.

Every query in this repo starts from a business question — not 
"demonstrate window functions" but "which sellers should get 
premium placement in each category?" The SQL is the means. 
The decision is the point.

---

## What I built

10 advanced SQL analyses across three business domains:

**Seller Performance**
- Top 3 sellers by revenue per product category — and what the 
  revenue gap between rank 1 and rank 3 tells you about category 
  concentration risk
- Sellers outperforming their state's average rating
- Seller-level delivery SLA compliance

**Customer Behaviour**
- Monthly cohort retention in pure SQL — no Python, no pivoting outside the DB
- Customers with the longest consecutive ordering streaks (gaps & islands)
- City and state-level order volume distribution

**Operational Quality**
- Rolling 7-day revenue trend
- Month-over-month order growth using LAG()
- Late delivery rate and its measurable impact on review scores
- Payment method and installment behaviour by region

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
| category_translation | 71 | Portuguese → English category names |

---

## Honest setup notes

I ran into two real data issues worth documenting:

**1. The reviews CSV breaks bulk loading.**
`LOAD DATA INFILE` fails at row 77,917 because customer review
text contains embedded newlines and imperfectly escaped quotes.
MySQL's line parser trips on them. The fix is pandas — a proper
CSV parser that handles multi-line quoted fields. The other 7
tables load fine via bulk load. See `python/load_reviews.py`.

**2. Category names loaded with trailing `\r` characters.**
Windows CRLF line endings in `product_category_name_translation.csv`
left carriage returns on every English category name. A single
UPDATE with REPLACE() cleaned it. Small bug, but the kind that
silently breaks JOINs if you don't catch it.

---

## Repo structure

---

## Key findings so far

**Finding 1 — Seller concentration by category**
`watches_gifts` top 3 sellers did 201K / 192K / 169K revenue —
tight competition, no single seller has outsized leverage.
`bed_bath_table` top 3 did 165K / 152K / 54K — the drop-off to
rank 3 is steep, meaning two sellers dominate this category and
hold significant commission negotiation power over the platform.

**Finding 1 (geographic) — City concentration by state**
DF (Brasília) shows extreme concentration — 2,131 orders from
the capital vs negligible volumes elsewhere in the state.
SP shows healthier distribution across São Paulo, Campinas,
and Guarulhos — multiple cities absorbing demand.

**Finding 2 — Olist GMV trajectory**
First ever order: R$72.89 on September 4, 2016.
Total GMV across the dataset: R$13,496,408 by September 2018.
The October 2016 inflection — revenue jumping from R$441 to
R$9,571 in a single day — marks when the platform meaningfully
opened to sellers. The 7-day moving average makes this
acceleration visible where raw daily numbers just look like noise.

*More findings added as the analysis progresses.*

---

**Brijesh Vaghela**  
[LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) ·
[GitHub](https://github.com/Brijesh403) ·
Also see: [ShopSense Product Analytics](https://github.com/Brijesh403/shopsense-product-analytics)