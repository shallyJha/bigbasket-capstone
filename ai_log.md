# AI Assistance Log

## Prompt 1: Fixing integer division in the percentage_variance formula

**Role:** You are an experienced SQLite developer helping me debug a reporting query.

**Context:** I have a query that joins orders to products to category_targets, sums total_revenue per category with SUM(o.amount_inr), and needs to compute percentage_variance as the percent difference between total_revenue and target_revenue_inr. Both columns are stored as INTEGER in SQLite. My first attempt was `(SUM(o.amount_inr) - target_revenue_inr) * 100 / target_revenue_inr`, and every row came back as a truncated whole number with no decimal places, for example -14 instead of the real value.

**Task:** Explain why the decimal portion is being truncated and give me a corrected expression for percentage_variance.

**Constraints:** Keep the fix to the arithmetic expression itself, do not change the GROUP BY or the join structure, and the result should be a real decimal percentage, not truncated to a whole number.

**Format:** A short explanation of the root cause, followed by the corrected SQL expression.

**Tool used:** opencode CLI, run live with `opencode run "<prompt above>"`.

**AI's response:**

Root Cause

SQLite performs integer arithmetic when all operands are integers. In `(SUM(o.amount_inr) - target_revenue_inr) * 100 / target_revenue_inr`, every value is an INTEGER, so SQLite truncates the division result to an integer before returning it.

Fix

Force floating-point division by multiplying by a float literal:

```sql
(SUM(o.amount_inr) - target_revenue_inr) * 100.0 / target_revenue_inr
```

The `100.0` (real) promotes the entire expression to real-number arithmetic, preserving the decimal portion.

**Verification performed:** Ran both versions side by side against bigbasket_capstone.db with sqlite3, joining orders to products to category_targets on Delivered orders only. The original `* 100 / target_revenue_inr` expression returned whole numbers with the decimal portion dropped for every one of the 6 categories, for example Dairy & Eggs came back as -14 and Fruits & Vegetables came back as -18. The corrected `* 100.0 / target_revenue_inr` expression returned the real decimal values for the same rows, Dairy & Eggs as -14.6060606060606 and Fruits & Vegetables as -18.4166666666667, which were checked by hand against the underlying total_revenue and target_revenue_inr figures for those two categories and confirmed correct. The corrected expression is the one used in 03_reporting.sql.