-- Migration validation queries.
-- Run each query against both OBIEE (via the RPD/physical layer) and
-- Power BI (via the Snowflake reporting views).
-- Compare results. Variance must be within 1% to pass.

-- =====================================================
-- 1. Record count comparison
-- =====================================================
-- Run against OBIEE physical layer
SELECT
    'Finance - GL' AS subject_area,
    COUNT(*) AS row_count
FROM fact_gl_entries
WHERE is_reversed = FALSE AND is_template = FALSE

UNION ALL
SELECT 'Risk', COUNT(*) FROM fact_risk_events

UNION ALL
SELECT 'Operations', COUNT(*) FROM fact_operations;

-- Run against Power BI Snowflake views
SELECT
    'Finance' AS dataset,
    COUNT(*) AS row_count
FROM reporting.v_finance_dataset

UNION ALL
SELECT 'Risk', COUNT(*) FROM reporting.v_risk_dataset

UNION ALL
SELECT 'Operations', COUNT(*) FROM reporting.v_operations_dataset;


-- =====================================================
-- 2. Aggregate comparison on key measures
-- =====================================================
-- Finance: total debits, credits, net by fiscal year
-- OBIEE side
SELECT
    dt.fiscal_year,
    SUM(g.debit_amount) AS total_debit,
    SUM(g.credit_amount) AS total_credit,
    SUM(g.net_amount) AS total_net
FROM fact_gl_entries g
JOIN dim_date dt ON g.date_key = dt.date_key
WHERE g.is_reversed = FALSE AND g.is_template = FALSE
GROUP BY dt.fiscal_year
ORDER BY dt.fiscal_year;

-- Power BI side
SELECT
    fiscal_year,
    SUM(debit_amount) AS total_debit,
    SUM(credit_amount) AS total_credit,
    SUM(net_amount) AS total_net
FROM reporting.v_finance_dataset
GROUP BY fiscal_year
ORDER BY fiscal_year;


-- =====================================================
-- 3. Dimension value check
-- =====================================================
-- Every distinct value in the OBIEE presentation layer should
-- appear in the Power BI dataset. Missing values mean a join
-- dropped rows or a filter excluded data.

-- Divisions: compare distinct values
SELECT DISTINCT division FROM dim_division ORDER BY division;

-- Check for Power BI view having fewer distinct divisions
SELECT division, COUNT(*) AS rows_in_pbi_view
FROM reporting.v_finance_dataset
GROUP BY division
ORDER BY division;

-- Account codes: compare distinct values
SELECT DISTINCT account_code, account_name
FROM dim_account
ORDER BY account_code;

-- Cost centers
SELECT DISTINCT cost_center_name
FROM dim_cost_center
ORDER BY cost_center_name;


-- =====================================================
-- 4. Variance calculation between OBIEE and Power BI
-- =====================================================
-- Joins the two result sets and calculates percentage variance.
-- Any row with variance > 1% needs investigation.
WITH obiee_totals AS (
    SELECT
        dt.fiscal_year,
        d.division,
        SUM(g.net_amount) AS obiee_total
    FROM fact_gl_entries g
    JOIN dim_date dt ON g.date_key = dt.date_key
    JOIN dim_division d ON g.division_id = d.division_id
    WHERE g.is_reversed = FALSE AND g.is_template = FALSE
    GROUP BY dt.fiscal_year, d.division
),
pbi_totals AS (
    SELECT
        fiscal_year,
        division,
        SUM(net_amount) AS pbi_total
    FROM reporting.v_finance_dataset
    GROUP BY fiscal_year, division
)
SELECT
    o.fiscal_year,
    o.division,
    o.obiee_total,
    p.pbi_total,
    o.obiee_total - p.pbi_total AS difference,
    ROUND(ABS(o.obiee_total - p.pbi_total) / NULLIF(o.obiee_total, 0) * 100, 4) AS variance_pct,
    CASE
        WHEN ABS(o.obiee_total - p.pbi_total) / NULLIF(o.obiee_total, 0) > 0.01
        THEN 'FAIL'
        ELSE 'PASS'
    END AS status
FROM obiee_totals o
JOIN pbi_totals p ON o.fiscal_year = p.fiscal_year AND o.division = p.division
ORDER BY variance_pct DESC;
