/* ============================================================
   setup.sql  —  Investment Data-Quality Sandbox
   ------------------------------------------------------------
   Run this FIRST, against the InvestmentsDQ database.
   It builds two tables and loads a small, DELIBERATELY messy
   dataset (synthetic data modeled on real holdings/returns).

   The mess is intentional: each planted error has a matching
   check in checks.sql. See answer_key.md for the full list.

   Re-runnable: it drops the tables first, so you can run it
   again any time to reset to a clean starting state.
   ============================================================ */

USE InvestmentsDQ;
GO

/* ---- reset, so the script can be re-run safely ---- */
IF OBJECT_ID('dbo.portfolio_holdings', 'U') IS NOT NULL DROP TABLE dbo.portfolio_holdings;
IF OBJECT_ID('dbo.security_returns',  'U') IS NOT NULL DROP TABLE dbo.security_returns;
GO

/* ---- table 1: what each portfolio holds ---- */
CREATE TABLE dbo.portfolio_holdings (
    portfolio_id   VARCHAR(20)   NOT NULL,
    as_of_date     DATE          NOT NULL,
    security_id    VARCHAR(20)   NOT NULL,
    security_name  VARCHAR(100)  NULL,
    sector         VARCHAR(50)   NULL,
    weight         DECIMAL(9,6)  NULL,   -- stored as a fraction: 0.25 = 25%
    market_value   DECIMAL(18,2) NULL,
    quantity       DECIMAL(18,4) NULL
);
GO

/* ---- table 2: one period return per security ---- */
CREATE TABLE dbo.security_returns (
    security_id    VARCHAR(20)   NOT NULL,
    as_of_date     DATE          NOT NULL,
    return_pct     DECIMAL(9,6)  NULL    -- stored as a fraction: 0.034 = 3.4%
);
GO

/* ============================================================
   LOAD: portfolio_holdings
   ============================================================ */
INSERT INTO dbo.portfolio_holdings
    (portfolio_id, as_of_date, security_id, security_name, sector, weight, market_value, quantity)
VALUES
-- PORT_A  — clean control: weights sum to 1.00, nothing wrong
('PORT_A','2025-12-31','AAPL','Apple Inc','Information Technology',0.25,250000,1000),
('PORT_A','2025-12-31','MSFT','Microsoft Corp','Information Technology',0.20,200000,500),
('PORT_A','2025-12-31','JPM','JPMorgan Chase & Co','Financials',0.15,150000,800),
('PORT_A','2025-12-31','JNJ','Johnson & Johnson','Health Care',0.15,150000,900),
('PORT_A','2025-12-31','XOM','Exxon Mobil Corp','Energy',0.10,100000,950),
('PORT_A','2025-12-31','PG','Procter & Gamble Co','Consumer Staples',0.15,150000,700),

-- PORT_B  — weights sum to only 0.96 (BRK.B weight is missing); TSLA sector is missing
('PORT_B','2025-12-31','NVDA','NVIDIA Corp','Information Technology',0.30,300000,400),
('PORT_B','2025-12-31','AMZN','Amazon.com Inc','Consumer Discretionary',0.24,240000,300),
('PORT_B','2025-12-31','GOOGL','Alphabet Inc','Communication Services',0.20,200000,250),
('PORT_B','2025-12-31','TSLA','Tesla Inc',NULL,0.22,220000,350),                       -- planted: NULL sector
('PORT_B','2025-12-31','BRK.B','Berkshire Hathaway Inc','Financials',NULL,100000,150),  -- planted: NULL weight

-- PORT_C  — duplicate Visa row, a negative weight, and a holding (ORCL) with no return
('PORT_C','2025-12-31','UNH','UnitedHealth Group Inc','Health Care',0.20,200000,350),
('PORT_C','2025-12-31','HD','Home Depot Inc','Consumer Discretionary',0.18,180000,300),
('PORT_C','2025-12-31','V','Visa Inc','Financials',0.17,170000,400),
('PORT_C','2025-12-31','MA','Mastercard Inc','Financials',0.15,150000,200),
('PORT_C','2025-12-31','DIS','Walt Disney Co','Communication Services',-0.05,50000,250),-- planted: negative weight
('PORT_C','2025-12-31','CVX','Chevron Corp','Energy',0.20,200000,500),
('PORT_C','2025-12-31','ORCL','Oracle Corp','Information Technology',0.15,150000,450),   -- planted: no matching return
('PORT_C','2025-12-31','V','Visa Inc','Financials',0.17,170000,400);                    -- planted: duplicate of the Visa row above
GO

/* ============================================================
   LOAD: security_returns
   ============================================================ */
INSERT INTO dbo.security_returns (security_id, as_of_date, return_pct)
VALUES
('AAPL','2025-12-31',0.034),
('MSFT','2025-12-31',0.021),
('JPM','2025-12-31',0.045),
('JNJ','2025-12-31',-0.012),
('XOM','2025-12-31',0.018),
('PG','2025-12-31',0.007),
('NVDA','2025-12-31',0.082),
('AMZN','2025-12-31',0.039),
('GOOGL','2025-12-31',0.027),
('TSLA','2025-12-31',0.061),
('BRK.B','2025-12-31',0.014),
('UNH','2025-12-31',0.015),
('HD','2025-12-31',0.022),
('V','2025-12-31',0.031),
('MA','2025-12-31',4.00),     -- planted: impossible 400% one-period return
('DIS','2025-12-31',NULL),    -- planted: missing return value
('CVX','2025-12-31',0.019);
-- NOTE: ORCL is intentionally absent here -> it becomes an "orphan" holding.
GO

PRINT 'Setup complete. Loaded 19 holdings and 17 security returns into InvestmentsDQ.';
GO
