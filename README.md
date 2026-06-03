# Investment Data-Quality Checks

A small SQL harness that validates portfolio **holdings** and **security returns** before the
data is used for performance or attribution analysis. It runs six data-quality checks against a
sample dataset and returns every record that fails, "reconciliation before
attribution" work that has to happen before anyone trusts the numbers in a weekly investment packet.

## Why it matters

Attribution and risk figures are only as good as the data feeding them. A single missing weight,
a duplicated holding, or a return entered as a raw multiple instead of a percent will quietly
corrupt every downstream calculation. Catching those issues early with repeatable SQL — rather
than manual eyeballing — is the foundation the rest of the analytics depends on.

## The data

Two tables, built and loaded by `setup.sql`:

- **`portfolio_holdings`** — `portfolio_id, as_of_date, security_id, security_name, sector, weight, market_value, quantity` (19 rows across 3 portfolios)
- **`security_returns`** — `security_id, as_of_date, return_pct` (17 rows)

The dataset is **synthetic**, modeled on the shape of real portfolio data, with errors planted on
purpose so each check has a known target. No proprietary or licensed data is used.

## The checks (`checks.sql`)

| # | Check | What it catches | SQL pattern |
|---|-------|-----------------|-------------|
| 1 | Weights sum to ~100% per portfolio | under- / over-allocated portfolios | `GROUP BY` / `HAVING` |
| 2 | No NULLs in critical fields | missing sector, weight, or name | `WHERE ... IS NULL` |
| 3 | Returns present and within ±100% | missing or implausible returns | `WHERE` |
| 4 | Weights and market values non-negative | sign / data-entry errors | `WHERE` |
| 5 | No duplicate holdings | double-counted positions | `GROUP BY` / `HAVING COUNT(*)` |
| 6 | Every holding has a matching return | orphaned holdings | `LEFT JOIN` |

Each query returns only the failing rows — an empty result means the check passed.

## What it found

Run against the sample data, the checks surfaced nine planted issues:

- **PORT_B** weights summed to 96% — traced to a missing weight on `BRK.B`.
- **PORT_C** weights summed to 117% — traced to a duplicated `Visa` holding and a negative `Disney` weight.
- A missing sector (`TSLA`) and a missing return (`DIS`).
- A 400% return on `MA` — a raw multiple stored as a percent.
- An orphaned holding (`ORCL`) with no return record, which would otherwise drop silently out of performance math.

The point isn't only flagging the headline number — it's tracing a 117% weight sum *down to* the
duplicate row and negative weight that caused it. That root-cause loop is the actual work.

## Tech

- SQL Server 2025 (T-SQL)
- Authored and run in VS Code with the SQL Server (mssql) extension

## How to run it

1. Create a database (e.g., `InvestmentsDQ`) and connect to it.
2. Run `setup.sql` to build the tables and load the sample data.
3. Run `checks.sql` — each of the six checks returns its failing rows.
4. See [`answer_key.md`](answer_key.md) for the full list of planted errors and expected results.
