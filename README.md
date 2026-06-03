# Investment Data-Quality Checks

## What this is

I am learning SQL and starting to work with investment data, so I built this small project to
practice. It is a set of SQL checks that look at portfolio data and flag any records that do not
look right, before that data gets used for performance or attribution analysis.

On a real investment team, someone has to make sure the data is clean (weights add up, returns are
sensible, nothing is missing or duplicated) before the analysis built on top of it can be trusted.
This project is my practice version of that job.

## What I was practicing

Building this helped me learn a few core SQL patterns:

- Filtering rows with `WHERE` to find bad values like nulls, negatives, and out-of-range numbers.
- Grouping and totaling with `GROUP BY` and `HAVING` to check sums per portfolio.
- Joining two tables with a `LEFT JOIN` to find records that are missing a match.

I also practiced setting up a SQL Server database on my own machine, loading data into it, and
checking my results against a list of errors I knew were there.

## The data

Two tables, created and loaded by `setup.sql`:

- `portfolio_holdings`: what each portfolio owns (portfolio, security, sector, weight, market value, quantity). 19 rows across 3 portfolios.
- `security_returns`: one period return per security. 17 rows.

Important: the data is synthetic. I made it up for this project, and it is not real market data.
The company names and tickers are real public companies (Apple, Microsoft, and so on), but every
number (weights, values, returns) is invented. I planted mistakes in the data on purpose so that
each check has a known error to find. No real, licensed, or proprietary data is used.

## The checks (`checks.sql`)

Each check returns only the rows that fail it. If a check returns nothing, the data passed it.

1. **Weights add up to about 100%.** Every portfolio's weights should sum to 1.0. This uses `GROUP BY` and `HAVING` to find any portfolio that is off by more than a small rounding amount.
2. **No missing values in important fields.** A holding with no sector, weight, or name causes problems later, so this uses `WHERE ... IS NULL` to find them.
3. **Returns are present and realistic.** A 400% return in one period is almost always a data error. This flags any return that is missing or outside the range of -100% to +100%.
4. **No negative weights or market values.** In a normal long-only holdings file, a negative weight is usually a typo. This finds them with a simple `WHERE`.
5. **No duplicate holdings.** The same position listed twice gets double counted. This uses `GROUP BY` and `HAVING COUNT(*)` to find rows that appear more than once.
6. **Every holding has a matching return.** A holding with no return cannot be measured and quietly drops out of the analysis. This uses a `LEFT JOIN` to find holdings with no matching return row.

## What the checks find in the sample data

Running the checks surfaces the mistakes I planted. For example, one portfolio's weights only add
to 96% because a weight is missing, another adds to 117% because of a duplicated row and a negative
weight, one return is 400%, and one holding has no return at all. The file `answer_key.md` lists
every planted error and what each check should return, so the results can be checked.

## How to run it

1. Create a database (for example `InvestmentsDQ`) and connect to it.
2. Run `setup.sql` to build the tables and load the sample data.
3. Run `checks.sql`. Each check returns its failing rows.
4. Compare the results against `answer_key.md`.

## Where the idea came from

The idea came from a data-quality section of an investment analytics primer I am using as a study
reference. It explained how teams reconcile and sanity-check portfolio data before running
attribution, and gave a small example of a SQL check that confirms a portfolio's weights sum to
100%. I used that example as my starting point and built the other checks around it.

## Learning resources I used

- SQLBolt (https://sqlbolt.com): interactive lessons on `SELECT`, `WHERE`, `JOIN`, `NULL`s, and aggregates. This covered most of what these checks needed.
- Cometly (https://www.cometly.com/post/multi-touch-attribution-sql): Multi Touch Attribution SQL
- Microsoft Learn, Transact-SQL reference (https://learn.microsoft.com/en-us/sql/t-sql): the official docs for SQL Server, which is what I ran this on.

## Notes

This is a learning project. I built it with help from an AI assistant (Claude) and a mentor. I set
up the database, ran every check, and verified the results against the errors I planted, and I am
using the project to understand both the SQL and the data-quality reasoning behind it. The sample
dataset was generated with AI assistance and is synthetic, not real data.

Tech: SQL Server 2025 (T-SQL), written and run in VS Code with the SQL Server (mssql) extension.
