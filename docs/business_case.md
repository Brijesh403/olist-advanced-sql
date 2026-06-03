# Business Case — Olist Advanced SQL Analysis
### Brijesh Vaghela

This document is my running analysis log — what I found, 
what it means, and what question it raises next. It grows 
with each lesson.

---

## Lesson 1 — Which sellers dominate each product category?

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

I used ROW_NUMBER() not RANK() because the business question 
asks for exactly 3 sellers per category. RANK() would return 
more than 3 rows if there's a revenue tie at position 3 — 
which is a different answer to a different question.

**What I found (top 5 categories by total revenue):**

| Category | #1 Revenue | #3 Revenue | Reading |
|----------|-----------|-----------|---------|
| watches_gifts | R$201,071 | R$169,768 | Tight — healthy competition |
| health_beauty | R$79,284 | R$65,817 | Tight — healthy competition |
| bed_bath_table | R$165,219 | R$54,552 | Steep drop — concentrated |
| computers_accessories | R$53,257 | R$47,214 | Tight — healthy competition |
| sports_leisure | R$54,056 | R$42,094 | Moderate gap |

**What this means for the business:**
`bed_bath_table` is the flag. Two sellers contribute nearly 3x 
the revenue of rank 3. If either of those sellers moves to a 
competing platform, category revenue takes a serious hit. 
A category manager seeing this would prioritise retention 
incentives for those two sellers — better terms, faster payouts, 
co-marketing budget.

`watches_gifts` is the opposite story. Three sellers within 
~18% of each other means the category is competitive and 
healthy — no single seller has leverage to demand special terms.

**Data issue caught:**
Category names loaded with trailing \r characters from Windows 
line endings in the CSV. Fixed before analysis with a targeted 
UPDATE. The kind of thing that silently breaks JOINs if you 
run queries without checking your lookup table first.

---

## Lesson 2 — What does Olist's revenue trajectory look like?

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

The date filter lives in the outer query, not the CTE — which 
means the running total reflects true cumulative GMV from the 
first order ever, not an artificially restarted count.

**What I found:**

| Milestone | Date | Running Total |
|-----------|------|---------------|
| First order ever | 2016-09-04 | R$72.89 |
| Revenue switches on | 2016-10-04 | R$10,221 cumulative |
| End of dataset | 2018-09-03 | R$13,496,408 total GMV |

**What this means for the business:**
Olist went from a single R$72 order in September 2016 to 
R$13.5M in cumulative GMV by mid-2018 — roughly 24 months 
of operation. The October 2016 jump (441 to 9,571 in one day) 
marks the likely inflection point where the platform opened 
meaningfully to sellers or ran its first acquisition push. 
That single week in October 2016 added more revenue than the 
entire previous month.

The 7-day moving average on the final days drops from 18K to 
5.5K — not a business declining, but the dataset ending. 
A real dashboard would flag this as a data-completeness issue 
rather than a trend signal.

**SQL concept that made this possible:**
ROWS BETWEEN defines a sliding frame relative to each row. 
UNBOUNDED PRECEDING means "from the very first row" — giving 
the running total. 6 PRECEDING means "this row plus the 6 
before it" — giving the 7-day window. Without ORDER BY inside 
OVER(), the frame has no sequence and MySQL returns the grand 
total for every single row instead. ORDER BY inside OVER() is 
what makes the calculation sequential.