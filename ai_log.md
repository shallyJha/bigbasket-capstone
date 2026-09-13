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

## Prompt 2: Scoping the IQR outlier fence and clip to Delivered orders only

**Role:** You are an experienced Python/Pandas developer helping me review outlier-handling code.

**Context:** I have a pandas DataFrame of orders with a status column and an amount_inr column. I only want to treat Delivered orders as the basis for outlier detection, since Cancelled and Pending orders should not affect the fence. My current code computes q1, q3, and upper_fence using orders['amount_inr'].quantile(0.25) and .quantile(0.75) without filtering by status first, then applies orders['amount_inr'] = orders['amount_inr'].clip(upper=upper_fence) to the whole column.

**Task:** Tell me what is wrong with computing the fence and applying the clip this way, and give me the corrected pandas code scoped to Delivered orders only.

**Constraints:** Keep using .quantile() and .clip(), do not drop any rows, and Cancelled/Pending amount_inr values must be left untouched.

**Format:** A short explanation followed by the corrected code.

**Tool used:** opencode CLI, run live with `opencode run "<prompt above>"`.

**AI's response:**

What's wrong

1. Fence is wrong: `orders['amount_inr'].quantile(0.25/0.75)` includes Cancelled/Pending amounts, so q1 and q3 are biased. The upper fence doesn't represent the Delivered distribution.
2. Clip is wrong: `orders['amount_inr'].clip(upper=upper_fence)` clips every row, including Cancelled/Pending orders that should be left untouched.

Corrected code

```python
delivered = orders['status'] == 'Delivered'

q1 = orders.loc[delivered, 'amount_inr'].quantile(0.25)
q3 = orders.loc[delivered, 'amount_inr'].quantile(0.75)
iqr = q3 - q1
upper_fence = q3 + 1.5 * iqr

orders.loc[delivered, 'amount_inr'] = orders.loc[delivered, 'amount_inr'].clip(upper=upper_fence)
```

- Quantiles are computed from Delivered rows only (`orders.loc[delivered, 'amount_inr']`).
- `.clip()` is applied only to Delivered rows via the same boolean mask, leaving Cancelled/Pending untouched.

**Verification performed:** Re-ran the AI-suggested code against a fresh load of orders_raw.csv (after dedup and casing cleanup, before capping), which reproduced Q1 = 90.0, Q3 = 275.0, upper_fence = 552.5, matching analysis.ipynb. Before capping, order_ids 79, 121, and 131 (all Delivered) held amount_inr values of 600, 580, and 580, all above the fence. After running the AI-suggested clip line, those same three rows read exactly 552.5, the upper fence value, confirming the clip worked correctly. Separately, order_ids 77, 152, and 173 (Pending, Cancelled, Pending) held amount_inr values of 650, 720, and 4800, also above the fence, and remained unchanged after the clip, confirming non-Delivered rows are correctly left untouched. A final check that no Delivered row still exceeds the fence also passed.