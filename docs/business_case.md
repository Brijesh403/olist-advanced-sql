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

*Lesson 2 findings will appear here after the next session.*