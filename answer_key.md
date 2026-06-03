# Answer Key — Planted Errors

This is the "ground truth" for the messy dataset in `setup.sql`. Every error below was
inserted on purpose so you can prove each check in `checks.sql` catches its target.

**How to use it:** run `setup.sql`, then `checks.sql`, then compare what each check
flagged against the table below. If a check flags exactly the rows listed, it works.

> Keep this file in a `/docs` folder. It's fine to commit publicly — it documents your
> test design and shows you validated your own work (which is itself a selling point).

## The 9 planted issues

| # | Where | What's wrong | Caught by |
|---|-------|--------------|-----------|
| 1 | `PORT_B` | Weights sum to **0.96**, not 1.00 | Check 1 |
| 2 | `PORT_C` | Weights sum to **1.17**, not 1.00 (a symptom of #5 and #8 below) | Check 1 |
| 3 | `PORT_B` / `TSLA` | **sector is NULL** | Check 2 |
| 4 | `PORT_B` / `BRK.B` | **weight is NULL** (this is *why* PORT_B falls short of 100%) | Check 2 |
| 5 | `PORT_C` / `DIS` | **weight is negative** (-0.05); a sign / entry error | Check 4 |
| 6 | `security_returns` / `MA` | **return = 4.00 (400%)** — implausible one-period return | Check 3 |
| 7 | `security_returns` / `DIS` | **return is NULL** — missing value | Check 3 |
| 8 | `PORT_C` / `V` (Visa) | **duplicate row** — listed twice | Check 5 |
| 9 | `PORT_C` / `ORCL` | **holding has no matching return row** (orphan) | Check 6 |

## What each check should return

- **Check 1 (weights ≈ 100%)** → `PORT_B` (0.96) and `PORT_C` (1.17). `PORT_A` passes.
- **Check 2 (no NULL fields)** → `TSLA` (sector) and `BRK.B` (weight).
- **Check 3 (returns present & in range)** → `MA` (4.00) and `DIS` (NULL).
- **Check 4 (non-negative)** → `DIS` (weight -0.05).
- **Check 5 (no duplicates)** → `PORT_C / V` with row_count = 2.
- **Check 6 (every holding has a return)** → `PORT_C / ORCL`.

## The teaching point worth writing up

Notice how errors **corroborate** each other. `PORT_C`'s weight sum is off (Check 1) *because*
of the duplicate Visa row (Check 5) and the negative Disney weight (Check 4). On a real desk
you rarely fix the headline symptom directly — you chase it down to the row that caused it.
That "investigate the anomaly, find the root cause" loop is exactly what the role asks for.

## Optional next error to plant (bonus check)

Add a 7th check for **identifier hygiene**: insert a holding with a trailing space or
lowercase ticker (e.g., `'aapl '`) and write a check that flags
`security_id <> UPPER(LTRIM(RTRIM(security_id)))`. Inconsistent identifiers are one of the
most common real-world causes of failed joins — a great, realistic addition once the core six work.
