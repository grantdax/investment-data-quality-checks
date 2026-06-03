/* ============================================================
   checks.sql  —  Investment Data-Quality Checks
   ------------------------------------------------------------
   Run this AFTER setup.sql, against InvestmentsDQ.

   How to read the output: each check returns ONLY the rows that
   FAIL it. An empty result set means that check passed. Run the
   whole file (F5) to get all six result grids at once, or
   highlight one check and run just that.

   Each check mirrors a piece of the real "reconciliation before
   attribution" grind: clean holdings + returns are a prerequisite
   before any performance or attribution math can be trusted.
   ============================================================ */

USE InvestmentsDQ;
GO

/* ------------------------------------------------------------
   CHECK 1  —  Portfolio weights must sum to ~100% (1.0)
   Why: allocation, exposure, and attribution math all assume the
   weights add to 1. If they don't, the portfolio is unusable
   until reconciled. Tolerance of 0.001 allows normal rounding.
   ------------------------------------------------------------ */
SELECT
    portfolio_id,
    SUM(weight)        AS total_weight,
    SUM(weight) - 1.0  AS difference_from_100pct
FROM dbo.portfolio_holdings
GROUP BY portfolio_id
HAVING ABS(SUM(weight) - 1.0) > 0.001;
GO

/* ------------------------------------------------------------
   CHECK 2  —  Critical holding fields must not be NULL
   Why: a missing weight, sector, or name silently breaks
   grouping and reporting downstream (e.g., a NULL sector drops
   out of a sector attribution).
   ------------------------------------------------------------ */
SELECT
    portfolio_id, security_id, security_name, sector, weight,
    CASE WHEN security_name IS NULL THEN 'security_name ' ELSE '' END +
    CASE WHEN sector        IS NULL THEN 'sector '        ELSE '' END +
    CASE WHEN weight        IS NULL THEN 'weight '        ELSE '' END AS missing_fields
FROM dbo.portfolio_holdings
WHERE security_name IS NULL
   OR sector        IS NULL
   OR weight        IS NULL;
GO

/* ------------------------------------------------------------
   CHECK 3  —  Returns must be PRESENT and within a plausible range
   Why: a 400% one-period return is almost always a feed error
   (a raw multiple stored as a percent, a bad source). A NULL
   return means the security can't be performance-attributed.
   Flag anything missing or outside -100%..+100% for a human.
   ------------------------------------------------------------ */
SELECT
    security_id, as_of_date, return_pct
FROM dbo.security_returns
WHERE return_pct IS NULL
   OR return_pct > 1.0
   OR return_pct < -1.0;
GO

/* ------------------------------------------------------------
   CHECK 4  —  Weights and market values must be non-negative
   Why: a long-only holdings file shouldn't contain negative
   weights or values — usually a sign / data-entry error.
   ------------------------------------------------------------ */
SELECT
    portfolio_id, security_id, weight, market_value
FROM dbo.portfolio_holdings
WHERE weight < 0
   OR market_value < 0;
GO

/* ------------------------------------------------------------
   CHECK 5  —  No duplicate holdings
   Why: the same position listed twice double-counts exposure and
   inflates the portfolio's weight sum. A holding should be unique
   per portfolio + security + date.
   ------------------------------------------------------------ */
SELECT
    portfolio_id, security_id, as_of_date,
    COUNT(*) AS row_count
FROM dbo.portfolio_holdings
GROUP BY portfolio_id, security_id, as_of_date
HAVING COUNT(*) > 1;
GO

/* ------------------------------------------------------------
   CHECK 6 (stretch)  —  Every holding must have a return
   Why: a holding with no matching return row can't be attributed
   and silently disappears from performance math. The LEFT JOIN
   keeps all holdings; rows with no return come back NULL on the
   returns side, which is what we filter for.
   ------------------------------------------------------------ */
SELECT DISTINCT
    h.portfolio_id, h.security_id, h.as_of_date
FROM dbo.portfolio_holdings AS h
LEFT JOIN dbo.security_returns AS r
       ON h.security_id = r.security_id
      AND h.as_of_date  = r.as_of_date
WHERE r.security_id IS NULL;
GO
