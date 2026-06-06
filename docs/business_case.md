# Olist Business Case — Analysis & Findings
### Brijesh Vaghela

This is my running analysis document — what I found, what it 
means for the business, and what question each finding raises 
next. Updated after each analysis.

---

## Finding 1 — Which sellers dominate each product category?

**The question a category manager actually asks:**
Before renewing seller contracts or adjusting commission tiers,
you want to know — in each category, is revenue spread across
many sellers, or is one seller so dominant that losing them
hurts the whole category?

**Query approach:**
Three-stage CTE. First aggregate revenue per (category, seller).
Then rank sellers within each category using ROW_NUMBER() —
PARTITION BY restarts the rank counter for every category, like
a separate leaderboard per category. Then filter to rank <= 3
in the outer query. Window functions can't go in WHERE because
they're evaluated after WHERE runs — that's the constraint that
forces the CTE wrapper, and it's the #1 thing candidates get
wrong in live SQL screens.

ROW_NUMBER() not RANK() — because the business question asks
for exactly 3 sellers per category. RANK() would return more
than 3 rows on a revenue tie, which is a different answer to
a different question.

**Results:**

| Category | #1 Revenue | #3 Revenue | Signal |
|----------|-----------|-----------|--------|
| watches_gifts | R$201,071 | R$169,768 | Healthy competition |
| health_beauty | R$79,284 | R$65,817 | Healthy competition |
| bed_bath_table | R$165,219 | R$54,552 | Concentrated — risk |
| computers_accessories | R$53,257 | R$47,214 | Healthy competition |
| sports_leisure | R$54,056 | R$42,094 | Moderate gap |

**Business insight:**
`bed_bath_table` is the flag. Two sellers contribute nearly 3x
the revenue of rank 3, giving them significant negotiating
power over Olist's commission structure. A category manager
seeing this would prioritise retention incentives for those
two sellers before contract renewal.

`watches_gifts` is the opposite — three sellers within ~18%
of each other means healthy competition and no single seller
has platform leverage.

---

## Finding 1 (geographic) — Which cities drive orders per state?

**The question an ops or growth team asks:**
Where should we prioritise delivery infrastructure, regional
marketing spend, and seller acquisition? City-level order
concentration tells you where demand actually lives.

**Query approach:**
Same three-stage CTE pattern. Aggregate order counts per
(state, city), rank cities within each state by count,
filter to top 3. ROW_NUMBER() with a secondary tiebreaker
on city name ASC ensures deterministic results across runs —
without it, tied cities could swap ranks between executions.

**Results (selected states):**

| State | City | Orders | Rank |
|-------|------|--------|------|
| DF | brasilia | 2,131 | 1 |
| DF | (next city) | ~15 | 2 |
| SP | sao paulo | ~15,000+ | 1 |
| BA | salvador | 1,245 | 1 |
| BA | feira de santana | 185 | 2 |

**Business insight:**
DF shows extreme concentration — Brasília dominates its state
completely. A logistics partner in DF only needs to serve one
city to capture almost all demand. SP shows healthier
multi-city distribution, meaning delivery infrastructure needs
to cover a broader geographic spread.

---

## Finding 2 — What does Olist's revenue trajectory look like?

**The question a growth or finance team actually asks:**
Not "how much did we make this month" — but "where are we in
the cumulative story, and is the underlying trend accelerating
or flattening?"

**Query approach:**
Two-stage CTE. First aggregate to one revenue number per day
(joining order_items to orders for the timestamp, excluding
cancelled orders). Then apply two window functions over the
ordered date sequence — a running total with
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW,
and a 7-day moving average with ROWS BETWEEN 6 PRECEDING
AND CURRENT ROW. The frame slides forward one row at a time,
recalculating both metrics at each date.

The date filter lives in the outer query, not the CTE — so
the running total reflects true cumulative GMV from the first
order ever placed, not an artificially restarted count.

**Results:**

| Milestone | Date | Running Total |
|-----------|------|---------------|
| First order ever | 2016-09-04 | R$72.89 |
| Platform inflection | 2016-10-04 | R$10,221 cumulative |
| End of dataset | 2018-09-03 | R$13,496,408 total GMV |

**Business insight:**
Olist went from a single R$72 order in September 2016 to
R$13.5M in cumulative GMV by mid-2018 — roughly 24 months.
The October 2016 jump (R$441 to R$9,571 in one day) marks
the likely inflection point where the platform opened
meaningfully to sellers or ran its first real acquisition push.
That single week added more revenue than the entire previous
month combined.

The 7-day moving average on the final days drops from 18K to
5.5K — not a business in decline, but a dataset ending.
A real dashboard would flag this as a data-completeness issue
rather than a trend signal.

---

## Finding 2 (practice) — How has each category's order volume accumulated?

**The question:**
Which categories show consistent month-on-month growth vs
which had isolated spikes? A running total per category
reveals the accumulation story that monthly snapshots hide.

**Query approach:**
Three-stage CTE. Aggregate order counts per (category, year,
month). Then apply SUM() OVER with PARTITION BY category —
this is the critical detail: the running total restarts
independently for each category, not one global counter.
Filter NULL categories (products with no category assigned)
to keep the analysis clean.

**What to look for in the output:**
A category whose running total climbs steadily every month
is growing organically. A category whose running total jumps
in one month then barely moves has demand concentration in
a single period — worth investigating why.

---

## Finding 3 — Is Olist's revenue growth accelerating or slowing?

**The question a growth team asks every Monday:**
Not "how much did we make" — but "are we growing faster or
slower than last month, and why?"

**Query approach:**
Two-stage CTE. First aggregate revenue per calendar month.
Then use LAG(revenue, 1) OVER (ORDER BY month) to pull the
previous month's revenue onto the same row — no self-join
needed. Growth % is simple arithmetic from there:
(this_month - last_month) / last_month * 100.

The first row returns NULL for previous month — there is no
month before the first. That's correct, not an error.

**Results (key months):**

| Month | Revenue | MoM Growth |
|-------|---------|------------|
| 2017-03 | R$368,341 | +50.4% |
| 2017-05 | R$503,159 | +42.2% |
| 2017-11 | R$1,003,862 | +52.1% — Black Friday Brazil |
| 2017-12 | R$742,183 | -26.1% — post-holiday unwind |
| 2018-04 | R$993,592 | +1.3% |
| 2018-05 | R$992,871 | -0.1% — plateau begins |

**Business insight:**
Three distinct phases are visible. Early 2017 shows explosive
growth (50-100% MoM) as the platform scales from near-zero.
November 2017 is the clear peak — Black Friday Brazil pushed
Olist past R$1M monthly revenue for the first and only time
in the dataset. From April 2018 onward, the business plateaus
around R$850K-R$1M with single-digit growth — a signal that
current market penetration may be saturating.

**Data quality note:**
November 2016 is missing entirely from the data — LAG() treats
December 2016 as "the month after October" which makes the
early growth rates unreliable. Pre-2017 months are best treated
as a beta period and excluded from trend analysis.

---

## Finding 4 — Do Olist customers come back after their first order?

**The question every product team needs answered:**
What percentage of customers acquired in each month return to
place another order? Is the business building a loyal base, or
is every month's revenue dependent on acquiring new buyers?

**Query approach:**
Five-stage CTE — the most complex query in this project.
First identify each customer's cohort (their first order month)
using customer_unique_id, not customer_id — a critical Olist
data trap, since one person can have multiple customer_id values
across orders. Then calculate month offsets using PERIOD_DIFF,
count cohort sizes, count active customers at each offset, and
divide to get retention %.

**Results (selected cohorts):**

**Results (cohort retention pivot — active customers):**

| Cohort | Size | m1 | m2 | m3 | m4 | m5 | m6 |
|--------|------|----|----|----|----|----|-----|
| 2017-01 | 762 | 3 | 2 | 1 | 3 | 1 | 4 |
| 2017-05 | 3,571 | 17 | 18 | 14 | 11 | 12 | 15 |
| 2017-08 | 4,162 | 28 | 14 | 11 | 15 | 22 | 12 |
| 2017-11 | 7,270 | 40 | 28 | 12 | 14 | 13 | 8 |
| 2018-01 | 6,992 | 23 | 26 | 20 | 20 | 11 | 12 |
| 2018-04 | 6,700 | 39 | 21 | 16 | 9 | — | — |

The triangle shape forms naturally — newer cohorts have fewer
months of data. Every cohort shows the same pattern: thousands
acquired at m0, single or double digits by m1. The November
2017 Black Friday cohort acquired 7,270 customers — only 40
returned the following month.

**Business insight:**
Olist's customer base is almost entirely one-time buyers.
Month-1 retention is below 1% across every single cohort —
including the massive November 2017 Black Friday cohort
(7,270 customers acquired, only 40 returned the next month).

This means Olist cannot rely on repeat revenue. Growth depends
entirely on continuously acquiring new customers. Every month's
revenue comes from that month's new buyers, not from a loyal
returning base.

The strategic question this raises: should Olist invest in
reactivation campaigns? At 0.3% retention, the ROI on email
winback or discount offers is likely near zero. The better
play is to accept the one-time buyer model and optimise for
first-order margin and customer acquisition cost.

**Critical data note:**
Using customer_id instead of customer_unique_id would make
every order appear to come from a new customer — producing
near-zero retention that's wrong for the wrong reason.
customer_unique_id is the true person identifier in this
dataset.
*Further findings will appear here as the analysis progresses.*