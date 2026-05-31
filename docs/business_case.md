# Olist Business Case Study — Analysis Document

## Analyst: Brijesh Vaghela
## Dataset: Olist Brazilian E-Commerce (Kaggle)
## Database: MySQL 8.0

---

## Lesson 1 — Top-N Sellers Per Category (Window Functions: Ranking)

### Business Question
Which are the top 3 sellers by revenue in each of Olist's top 5 product categories?

### Why This Matters
A marketplace's category management team uses this to decide:
- Which sellers get **premium placement** in search results
- Which sellers qualify for **reduced commission tiers** as performance rewards
- Which categories are **seller-concentrated** (one dominant seller = supply risk)

### SQL Concepts Used
- `ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC)`
- Three-stage CTE pattern: aggregate → rank → filter
- Why window functions cannot appear in `WHERE` — must filter in an outer query
- Deterministic tiebreaking with a secondary `ORDER BY seller_id ASC`

### Results

| Category | Rank 1 Revenue | Rank 3 Revenue | Concentration Signal |
|----------|---------------|----------------|----------------------|
| watches_gifts | 201,071 | 169,768 | Low — tight competition |
| health_beauty | 79,284 | 65,817 | Low — tight competition |
| bed_bath_table | 165,219 | 54,552 | High — top 2 dominate |
| computers_accessories | 53,257 | 47,214 | Low — tight competition |
| sports_leisure | 54,056 | 42,094 | Medium |

### Business Insight
`watches_gifts` and `health_beauty` show healthy seller competition — 
top 3 revenues are close, meaning no single seller has outsized platform leverage.
`bed_bath_table` shows concentration risk — rank 1 and 2 sellers contribute 
nearly 3x the revenue of rank 3, giving them significant negotiating power 
over Olist's commission structure.

### Data Issue Noted
`category_translation` CSV loaded with trailing `\r` characters on category 
names due to Windows line endings. Fixed with:
```sql
UPDATE category_translation
SET product_category_name_english = TRIM(REPLACE(product_category_name_english, '\r', ''))
WHERE product_category_name_english LIKE '%\r%';
```

---

*Further lessons will be added below as the case study progresses.*