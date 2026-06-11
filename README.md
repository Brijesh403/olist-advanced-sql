# Olist Marketplace Analytics

**End-to-end analysis of Brazil's largest e-commerce marketplace — advanced SQL → Portuguese sentiment NLP → executive Power BI dashboard.**

![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python&logoColor=white)
![NLP](https://img.shields.io/badge/NLP-pysentimiento%20PT-8A2BE2)
![Power BI](https://img.shields.io/badge/Power%20BI-Executive%20Dashboard-F2C811?logo=powerbi&logoColor=black)
![Dataset](https://img.shields.io/badge/Dataset-Olist%20(Kaggle)-2EA44F)

> One dataset, three layers: deep SQL business analysis on 99,441 orders, a Portuguese NLP sentiment layer on 42,370 free-text reviews, and an executive Power BI dashboard that ties operational quality to the voice of the customer. All revenue figures are in BRL.

---

## 📌 Business Context

Olist is Brazil's largest e-commerce marketplace — a platform connecting 3,095 sellers to customers across 27 states. As a Data Analyst, I used this public dataset to answer the questions a marketplace analytics team deals with every week: which sellers drive the most revenue and carry the most platform risk, whether Olist has a retention problem or an acquisition problem, and how operational quality (delivery SLA) translates into the metric every marketplace ultimately cares about — review scores.

The dataset has embedded newlines in review text, Portuguese category names requiring translation joins, and NULL delivery timestamps for cancelled orders — the kind of data quality issues that don't exist in tutorial datasets but show up in every production database.

---

## ❓ Business Questions Answered

1. Which sellers dominate each product category — and what does the revenue gap between rank 1 and rank 3 signal?
2. Where does demand actually live — which cities and states drive order volume?
3. How did Olist grow from its first order to R$13.5M GMV, and what phases shaped that growth?
4. Is there a meaningful returning customer base, or is Olist structurally dependent on new acquisition?
5. What is the true cost of a late delivery — measured in review stars?
6. How do payment preferences and order values vary across income regions?
7. Where is order value concentrated — what does a typical Olist order actually look like?
8. Which sellers balance revenue, delivery quality, and customer satisfaction simultaneously?
9. **(NLP)** What do customers actually *say* — and where does written sentiment disagree with the star rating?

---

## 🔑 Key Findings (TL;DR)

> Full write-up with query rationale in [`docs/business_case.md`](docs/business_case.md).

- **Olist has a retention problem, not an acquisition problem.** Month-1 retention is below 1% across every cohort — including the Black Friday 2017 cohort of 7,270 new customers (retained just 0.6%). Only 11 of 99,441 customers ordered in 3+ consecutive months.
- **Category concentration risk in `bed_bath_table`.** Top 2 sellers earn nearly 3× what rank 3 earns (R$165K / R$152K vs R$55K), giving those two sellers significant commission negotiation leverage over the platform.
- **Late delivery costs exactly 1.72 stars.** On-time orders average 4.29 ⭐; late orders average 2.57 ⭐. Olist's strategy of under-promising estimates (on-time orders arrive 13.7 days early) is the reason their baseline rating is high.
- **Revenue peaked once and never recovered.** Black Friday 2017 hit R$1,003,862 (+52.1% MoM) — the only month above R$1M. The platform plateaued from April 2018 at R$850K–R$1M with near-zero growth.
- **Top 10% of orders generate 38% of revenue.** Median order is R$104 but the distribution has a R$13,664 tail — making average order value a misleading headline metric.
- **Geographic concentration risk.** 20 of the top 30 revenue sellers are in SP. One BA seller (rank 2) outperforms all SP sellers on quality: R$223K revenue, 4.0% late rate, 4.08 ⭐.
- **The North/Northeast affordability signal.** Boleto (payment for the unbanked) peaks in AP (29%) and RR (29%). PB averages 3.8 installments on R$248 orders vs SP's 2.6 installments on R$137 — higher-value purchases financed in smaller payments.
- **(NLP) Sentiment confirms the delivery story.** 50.4% of text reviews are positive, 19.6% negative. 330 customers gave 5 stars but wrote negatively — a hidden dissatisfaction signal invisible to star-rating dashboards alone.

**Scale:** 8 tables · 99,441 orders · ~530K rows · R$13.5M GMV · Sep 2016 – Sep 2018

---

## 💡 Recommendations

| Recommendation | Based On | Expected Action |
|---|---|---|
| Stop investing in loyalty — maximise first-order margin | Sub-1% m1 retention across all cohorts | Reallocate retention budget to acquisition |
| Diversify `bed_bath_table` seller base | 2 sellers earning 3× rank 3 | Onboard 2–3 new sellers to reduce negotiation risk |
| Fast-track exit for High Revenue Risk sellers | Rank 5: R$188K but 3.35 ⭐ | Protect platform NPS before it shows in aggregate |
| Maintain deliberate delivery under-promise policy | On-time orders arrive 13.7 days early → 4.29 ⭐ | Do not adjust estimates — this is a zero-cost rating driver |

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| MySQL 8.0 | Data storage and all SQL analysis |
| Python — pandas, SQLAlchemy | Data loading (reviews CSV bypass for embedded newlines) |
| Python — pysentimiento, transformers, PyTorch (CPU) | Portuguese sentiment analysis on 42,370 review texts |
| Power BI Desktop | Executive dashboard — star schema, DAX, custom design system |
| Git + GitHub | Version control and portfolio |

---

## 📁 Project Structure

```
olist-marketplace-analytics/
│
├── sql/
│   ├── 01_setup/
│   │   ├── 01_create_tables.sql               ← schema + foreign keys for 8 tables
│   │   └── 02_load_data.sql                   ← bulk load 7 tables + notes on reviews
│   │
│   ├── 02_findings/
│   │   ├── top_sellers_by_category.sql         ← top-N sellers per category
│   │   ├── top_cities_by_state.sql             ← top-3 cities per state
│   │   ├── revenue_running_total.sql           ← rolling GMV + 7-day moving avg
│   │   ├── category_orders_running_total.sql   ← running total of orders per category
│   │   ├── monthly_revenue_growth.sql          ← month-over-month revenue growth (LAG)
│   │   ├── category_mom_order_growth.sql       ← month-over-month order count per category
│   │   ├── cohort_retention.sql                ← monthly cohort retention analysis
│   │   ├── customer_order_streaks.sql          ← longest consecutive ordering streaks
│   │   ├── sellers_above_state_avg_rating.sql  ← sellers outperforming state average
│   │   ├── delivery_sla_review_impact.sql      ← late delivery rate and review score impact
│   │   ├── payment_behaviour_by_state.sql      ← payment method and installment mix by state
│   │   ├── order_value_percentiles.sql         ← order value percentiles and revenue concentration
│   │   └── seller_scorecard.sql                ← capstone — seller revenue, quality and delivery
│   │
│   └── 03_sentiment/
│       └── 01_create_review_sentiment.sql      ← review_sentiment table schema (idempotent)
│
├── python/
│   ├── load_reviews.py                         ← pandas loader for order_reviews CSV
│   ├── sentiment_analysis.py                   ← Portuguese sentiment pipeline (batched, resumable)
│   └── requirements.txt                        ← pinned dependencies
│
├── powerbi/                                    ← 🚧 in progress
│   ├── olist_dashboard.pbix
│   └── screenshots/
│
├── docs/
│   ├── business_case.md                        ← findings + business interpretation
│   └── data_model.svg                          ← star-schema diagram
│
└── data/                                       ← not tracked — download from Kaggle
```

---

## 📊 SQL Techniques Demonstrated

| Technique | Where it's used |
|---|---|
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

## 📈 Dataset

**Source:** [Brazilian E-Commerce Public Dataset — Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle) · **Database:** MySQL 8.0 · **Scale:** 8 relational tables, ~530K rows total

| Table | Rows | What it contains |
|---|---|---|
| orders | 99,441 | The spine — status + 5 timestamps from purchase to delivery |
| order_items | 112,650 | Line items — price, freight, which seller fulfilled it |
| order_payments | 103,886 | Payment type, installments, value |
| order_reviews | 99,224 | 1–5 scores + free-text comments |
| customers | 99,441 | City, state — no PII |
| products | 32,951 | Category, physical dimensions |
| sellers | 3,095 | City, state |
| category_translation | 71 | Portuguese to English category names |

---

## 🔧 Data Quality Notes

**1. The reviews CSV breaks bulk loading.** `LOAD DATA INFILE` fails at row 77,917 because customer review text contains embedded newlines and imperfectly escaped quotes. MySQL's line parser trips on them. The fix is pandas — a proper CSV parser that handles multi-line quoted fields. The other 7 tables load fine via bulk load. See `python/load_reviews.py`.

**2. Category names loaded with trailing carriage return characters.** Windows CRLF line endings in `product_category_name_translation.csv` left carriage returns on every English category name — silently breaking every JOIN on that column with no error, just missing data. A single `UPDATE` with `REPLACE()` cleaned it. Small bug, but the kind that takes hours to track down if you don't know to look for it.

---

## 🔍 Key Findings (detailed)

### Seller concentration by category

| Category | Rank 1 | Rank 2 | Rank 3 | Signal |
|---|---|---|---|---|
| watches_gifts | R$201K | R$192K | R$170K | Healthy — within 16% |
| health_beauty | R$79K | R$72K | R$66K | Healthy |
| bed_bath_table | R$165K | R$152K | R$55K | **Risk — 3× gap to rank 3** |
| computers_accessories | R$53K | R$52K | R$47K | Healthy — very tight |
| sports_leisure | R$54K | R$42K | R$42K | Moderate |

### City concentration by state

| State | City #1 | Orders | City #2 | Orders | City #3 | Orders |
|---|---|---|---|---|---|---|
| SP | São Paulo | 15,540 | Campinas | 1,444 | Guarulhos | 1,189 |
| RJ | Rio de Janeiro | 6,882 | Niterói | 849 | Nova Iguaçu | 442 |
| MG | Belo Horizonte | 2,773 | Juiz de Fora | 427 | Contagem | 426 |
| BA | Salvador | 1,245 | Feira de Santana | 185 | Vitória da Conquista | 92 |
| DF | Brasília | 2,131 | Taguatinga | 4 | Guará | 2 |

### Olist GMV trajectory

| Milestone | Date | Value |
|---|---|---|
| First ever order | 2016-09-04 | R$72.89 |
| Platform inflection (single day) | 2016-10-04 | R$9,571 daily revenue |
| Black Friday peak (monthly) | 2017-11 | R$1,003,862 |
| Total GMV (end of dataset) | 2018-09-03 | R$13,496,408 |

### Revenue growth phases

| Period | Revenue | MoM Growth | Phase |
|---|---|---|---|
| 2017-03 | R$368K | +50.4% | Explosive growth |
| 2017-05 | R$503K | +42.2% | Explosive growth |
| 2017-11 | R$1,003K | +52.1% | Black Friday peak — only month above R$1M |
| 2017-12 | R$742K | −26.1% | Post-holiday unwind |
| 2018-04 | R$993K | +1.3% | Plateau begins |
| 2018-05 | R$992K | −0.1% | Plateau |

### Customer retention — the one-time buyer problem

| Cohort | Acquired (m0) | Returned (m1) | m1 Retention |
|---|---|---|---|
| 2017-01 | 762 | 3 | 0.4% |
| 2017-05 | 3,571 | 17 | 0.5% |
| 2017-08 | 4,162 | 28 | 0.7% |
| 2017-11 (Black Friday) | 7,270 | 40 | 0.6% |
| 2018-01 | 6,992 | 23 | 0.3% |
| 2018-04 | 6,700 | 39 | 0.6% |

### Loyal customers — 0.011% of the base

| Customer (hashed) | Streak | From | To |
|---|---|---|---|
| 8d50f5ea… | 7 months | 2017-05 | 2018-08 |
| 6469f99c… | 5 months | 2017-09 | 2018-06 |
| 1b6c7548… | 4 months | 2017-11 | 2018-02 |
| 8 others | 3 months | various | various |

### Delivery SLA — 1.72 star penalty per late order

| Status | Orders | % of Total | Avg Rating | Avg Days vs Estimate |
|---|---|---|---|---|
| On Time | 88,653 | 92% | 4.29 ⭐ | −13.7 days (early) |
| Late | 7,700 | 8% | 2.57 ⭐ | +8.8 days (late) |

### Payment behaviour — regional affordability signal

| State | Orders | Credit Card | Boleto | Avg Installments | Avg Order Value |
|---|---|---|---|---|---|
| SP | 41,418 | 77.1% | 19.7% | 2.6 | R$137 |
| RJ | 12,766 | 80.1% | 16.8% | 3.0 | R$158 |
| MA | 743 | 71.7% | 27.1% | 3.1 | R$199 |
| PB | 534 | 80.0% | 17.4% | 3.8 | R$248 |
| TO | 279 | 70.3% | 27.2% | 3.0 | R$204 |
| AP | 68 | 69.1% | 29.4% | 2.6 | R$232 |
| RR | 45 | 71.1% | 28.9% | 2.8 | R$221 |

### Order value distribution — median R$104, top 10% drive 38% of revenue

| Percentile | Order Value | Notes |
|---|---|---|
| 25th | R$61 | Bottom quarter |
| 50th (median) | R$104 | Typical order |
| 75th | R$175 | Upper half |
| 90th | R$297 | High-value threshold |
| Top 10% decile | R$307+ | Generates 38.1% of total revenue |
| Top 20% decile | R$243+ | Generates 53%+ of total revenue |
| Maximum | R$13,664 | 130× the median |

### Capstone — Seller scorecard: revenue vs quality vs delivery

| Revenue Rank | State | Revenue | Late % | Avg Rating | Segment |
|---|---|---|---|---|---|
| 1 | SP | R$229K | 11.6% | 4.13 ⭐ | Standard |
| 2 | BA | R$223K | 4.0% | 4.08 ⭐ | **Star Seller ✓** |
| 3 | SP | R$200K | 11.0% | 3.80 ⭐ | Standard |
| 4 | SP | R$193K | 10.2% | 4.34 ⭐ | Standard |
| 5 | SP | R$188K | 9.6% | 3.35 ⭐ | **High Revenue Risk ⚠** |

---

## 🧠 Sentiment Analysis (Portuguese NLP)

The reviews table holds 1–5 star scores **and** free-text comments in Brazilian Portuguese. The star tells you *how many* customers were happy; the text tells you *why* — and sometimes the two disagree.

**Model:** `pysentimiento/bertweet-pt-sentiment` — a RoBERTa trained natively on Brazilian Portuguese. It reads the review text independently of the star score. That independence is what makes the divergence finding meaningful: a star-predicting model would be circular.

**Pipeline** (`python/sentiment_analysis.py`): connects to MySQL via SQLAlchemy, filters to reviews with comment text, scores in batches with a live progress bar, writes to `review_sentiment` via an idempotent UPSERT — fully resumable if interrupted.

**Coverage:** 99,224 total reviews · 42,370 contain comment text (42.7%) · 56,854 score-only (excluded from text sentiment).

**Results:**

| Sentiment | Reviews | Share |
|---|---|---|
| Positive | 21,359 | 50.4% |
| Neutral | 12,723 | 30.0% |
| Negative | 8,288 | 19.6% |

**Divergence — the most interesting stories:**

| Case | Count | Why it matters |
|---|---|---|
| 5★ rating but **negative** text | 330 | Hidden dissatisfaction — customers who rate well but write complaints |
| 1★ rating but **positive** text | 107 | Context reviews — low score due to delivery/seller, praise for product |

**Caveats:** domain shift (model trained on tweets, not reviews); Portuguese sarcasm and negation are edge cases; confidence score stored per review so low-certainty labels can be filtered downstream.

Schema: `sql/03_sentiment/01_create_review_sentiment.sql`

---

## 📊 Executive Power BI Dashboard *(🚧 in progress)*

A 6-page executive report built on a star schema (fact grain = order line items, conformed on `order_id`), Import mode, with a restrained custom design system.

| Page | Headline insight |
|---|---|
| Executive Overview | KPI cards + GMV trajectory with Black Friday peak annotated on-chart |
| Seller Performance & Risk | 4-segment seller scorecard + `bed_bath_table` concentration + state map |
| Customer Retention | Sub-1% cohort retention heatmap |
| Delivery & Operations | 1.72★ late-delivery penalty + 13.7-day under-promise insight |
| Sentiment Analysis | Sentiment vs star-rating divergence + sentiment by delivery status |
| Payments & Regional Affordability | Boleto vs credit-card map + installments by region |

Files: `powerbi/olist_dashboard.pbix` + `powerbi/screenshots/` *(added when built)*.

---

## 🔁 Reproduce From Scratch

```powershell
# 1. Python dependencies
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install -r python/requirements.txt

# 2. Load the 8 Olist tables into MySQL
#    Run sql/01_setup/ in order, then python/load_reviews.py for the reviews table

# 3. Run the sentiment pipeline
$env:OLIST_DB_PASSWORD = "your_password"
python python/sentiment_analysis.py

# 4. Open powerbi/olist_dashboard.pbix and refresh against your local MySQL
```

---

## 🚧 Project Status

| Phase | Status |
|---|---|
| Schema Design & Data Loading | ✅ Complete |
| Data Quality Investigation | ✅ Complete |
| Seller Performance Analysis | ✅ Complete |
| Customer Behaviour & Retention | ✅ Complete |
| Revenue & Operations Analysis | ✅ Complete |
| Capstone Seller Scorecard | ✅ Complete |
| Business Case Documentation | ✅ Complete |
| Portuguese Sentiment Analysis (NLP) | ✅ Complete |
| Executive Power BI Dashboard | 🚧 In Progress |

---

**Brijesh Vaghela** · [LinkedIn](https://www.linkedin.com/in/brijesh-vaghela) · [GitHub](https://github.com/Brijesh403)