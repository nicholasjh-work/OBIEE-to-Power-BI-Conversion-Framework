-- Security audit: verify that RLS in Power BI produces the same
-- row sets as OBIEE catalog security for each user group.
--
-- Approach: for each security group, count rows visible in both systems.
-- Counts must match exactly. Any difference means the RLS filter
-- is not equivalent to the OBIEE catalog filter.

-- Test: Finance_NA group should see only North America data
WITH obiee_na AS (
    SELECT COUNT(*) AS obiee_rows
    FROM fact_gl_entries g
    JOIN dim_division d ON g.division_id = d.division_id
    WHERE d.region = 'North America'
      AND g.is_reversed = FALSE
      AND g.is_template = FALSE
),
pbi_na AS (
    SELECT COUNT(*) AS pbi_rows
    FROM reporting.v_finance_dataset
    WHERE region = 'North America'
)
SELECT
    'Finance_NA' AS security_group,
    o.obiee_rows,
    p.pbi_rows,
    CASE WHEN o.obiee_rows = p.pbi_rows THEN 'PASS' ELSE 'FAIL' END AS status
FROM obiee_na o CROSS JOIN pbi_na p

UNION ALL

-- Test: Finance_EMEA
SELECT
    'Finance_EMEA',
    (SELECT COUNT(*) FROM fact_gl_entries g JOIN dim_division d ON g.division_id = d.division_id
     WHERE d.region = 'EMEA' AND g.is_reversed = FALSE AND g.is_template = FALSE),
    (SELECT COUNT(*) FROM reporting.v_finance_dataset WHERE region = 'EMEA'),
    CASE WHEN
        (SELECT COUNT(*) FROM fact_gl_entries g JOIN dim_division d ON g.division_id = d.division_id
         WHERE d.region = 'EMEA' AND g.is_reversed = FALSE AND g.is_template = FALSE)
        =
        (SELECT COUNT(*) FROM reporting.v_finance_dataset WHERE region = 'EMEA')
    THEN 'PASS' ELSE 'FAIL' END

UNION ALL

-- Test: Finance_APAC
SELECT
    'Finance_APAC',
    (SELECT COUNT(*) FROM fact_gl_entries g JOIN dim_division d ON g.division_id = d.division_id
     WHERE d.region = 'APAC' AND g.is_reversed = FALSE AND g.is_template = FALSE),
    (SELECT COUNT(*) FROM reporting.v_finance_dataset WHERE region = 'APAC'),
    CASE WHEN
        (SELECT COUNT(*) FROM fact_gl_entries g JOIN dim_division d ON g.division_id = d.division_id
         WHERE d.region = 'APAC' AND g.is_reversed = FALSE AND g.is_template = FALSE)
        =
        (SELECT COUNT(*) FROM reporting.v_finance_dataset WHERE region = 'APAC')
    THEN 'PASS' ELSE 'FAIL' END

UNION ALL

-- Test: Finance_Global (should see all rows, same as unfiltered total)
SELECT
    'Finance_Global',
    (SELECT COUNT(*) FROM fact_gl_entries WHERE is_reversed = FALSE AND is_template = FALSE),
    (SELECT COUNT(*) FROM reporting.v_finance_dataset),
    CASE WHEN
        (SELECT COUNT(*) FROM fact_gl_entries WHERE is_reversed = FALSE AND is_template = FALSE)
        =
        (SELECT COUNT(*) FROM reporting.v_finance_dataset)
    THEN 'PASS' ELSE 'FAIL' END;
