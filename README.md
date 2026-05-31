# Olist Advanced SQL Business Case Study

## Overview
End-to-end advanced SQL analysis on the **Olist Brazilian E-Commerce dataset** — 
a real, publicly available dataset of 100,000 orders across 8 relational tables 
covering customers, sellers, products, payments, and reviews.

This project demonstrates production-grade SQL skills through 10 business-driven 
case study questions — the kind asked in data/product analyst interviews at 
growth-stage companies.

**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle  
**Database:** MySQL 8.0  
**Tools:** MySQL Workbench, Python (pandas, SQLAlchemy)

---

## Business Context
Olist is a Brazilian marketplace platform connecting small/medium sellers to 
customers across Brazil. As a data analyst, the goal is to answer real operational 
and strategic questions across three domains:

- **Seller performance** — who drives revenue, who underperforms, which categories are concentrated
- **Customer behaviour** — retention, repeat purchase, cohort analysis
- **Operational quality** — delivery SLA breaches, late delivery impact on reviews

---

## Database Schema (8 Tables)

customers ──────────────── orders ──────── order_items ──── products
│                  │                │
│            order_payments    category_translation
│
order_reviewssellers ─────────────── order_items

| Table | Rows | Description |
|-------|------|-------------|
| customers | 99,441 | Customer ID, city, state |
| orders | 99,441 | Order status, 5 timestamps (purchase → delivery) |
| order_items | 112,650 | Line items — price, freight, seller, product |
| order_payments | 103,886 | Payment type, installments, value |
| order_reviews | 99,224 | Review score (1–5), comment text, timestamps |
| products | 32,951 | Category, dimensions, weight |
| sellers | 3,095 | Seller city, state |
| category_translation | 71 | Portuguese → English category names |

---

## Case Study Questions & Lessons

| # | Business Question | SQL Concepts |
|---|-------------------|--------------|
| 1 | Top 3 sellers by revenue per product category | `ROW_NUMBER()`, `PARTITION BY`, CTEs |
| 2 | Top 3 cities by order volume per state | Window functions — practice |
| 3 | 7-day rolling revenue trend | `SUM() OVER`, window frames |
| 4 | Month-over-month order growth | `LAG()`, period-over-period |
| 5 | Monthly cohort retention | Cohort logic in pure SQL |
| 6 | Customers with longest order streak | Gaps & islands |
| 7 | Payment method split per state | Conditional aggregation, pivot |
| 8 | Sellers above their state's avg rating | Correlated subqueries |
| 9 | Median order value & SLA breach rate | `NTILE()`, percentiles |
| 10 | Capstone — combined business case | All concepts combined |

---

## Setup — Run This Yourself

### 1. Download the dataset
Download from Kaggle: [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
Unzip the 9 CSVs into the `data/` folder.

### 2. Create the schema
Run `sql/01_setup/01_create_tables.sql` in MySQL Workbench against a `olist` database.

### 3. Load the data
- Run `sql/01_setup/02_load_data.sql` for 7 tables (LOAD DATA INFILE)
- Run `python python/load_reviews.py` for order_reviews (pandas — handles multi-line CSV fields)

### 4. Run the case study queries
Each lesson is a standalone `.sql` file in `sql/02_lessons/`.

---

## Key Findings (updated as lessons complete)
_To be populated as the case study progresses._

---

## Setup Notes
- MySQL 8.0+ required (window functions not available below 8.0)
- `order_reviews` loaded via Python/pandas due to embedded newlines in review text — 
  a real-world CSV parsing edge case documented in `sql/01_setup/02_load_data.sql`
- `secure_file_priv` must point to the Uploads folder for LOAD DATA INFILE

---

*Project by Brijesh Vaghela | [LinkedIn](www.linkedin.com/in/brijesh-vaghela) | [GitHub](https://github.com/Brijesh403)*