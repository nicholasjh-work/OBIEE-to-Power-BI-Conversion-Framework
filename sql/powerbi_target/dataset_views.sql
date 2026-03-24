-- Power BI dataset views in Snowflake.
-- These replace the OBIEE RPD semantic layer.
-- Each view maps to one Power BI dataset.
-- The RPD's three-layer model (physical, business, presentation) is flattened
-- into governed Snowflake views that Power BI imports directly.

-- Dataset 1: Finance
-- Consolidates the old Finance - GL, Finance - AP, Finance - AR, and Finance - Budget
-- subject areas into a single dataset.
-- The four OBIEE subject areas shared most of the same physical tables but had
-- slightly different join paths and column aliases. This view normalizes them.
CREATE OR REPLACE VIEW reporting.v_finance_dataset AS
WITH gl_base AS (
    SELECT
        g.journal_id,
        g.posting_date,
        g.account_code,
        a.account_name,
        a.account_type,
        a.account_group,
        cc.cost_center_name,
        cc.department,
        d.division,
        d.region,
        dt.fiscal_year,
        dt.fiscal_quarter,
        DATE_TRUNC('month', g.posting_date) AS period_month,
        g.debit_amount,
        g.credit_amount,
        g.net_amount,
        g.source_system,
        g.batch_id
    FROM fact_gl_entries g
    JOIN dim_account a        ON g.account_id = a.account_id
    JOIN dim_cost_center cc   ON g.cost_center_id = cc.cost_center_id
    JOIN dim_division d       ON g.division_id = d.division_id
    JOIN dim_date dt          ON g.date_key = dt.date_key
    WHERE g.is_reversed = FALSE
      AND g.is_template = FALSE
),
with_budget AS (
    SELECT
        b.*,
        bgt.budget_amount,
        bgt.forecast_amount,
        bgt.budget_version
    FROM gl_base b
    LEFT JOIN fact_budget bgt
        ON b.account_code = bgt.account_code
        AND b.cost_center_name = bgt.cost_center_name
        AND b.period_month = bgt.budget_month
        AND bgt.budget_version = 'APPROVED'
)
SELECT
    *,
    -- Period-over-period using window functions
    LAG(net_amount, 1) OVER (
        PARTITION BY account_code, cost_center_name
        ORDER BY period_month
    ) AS net_amount_prior_month,
    SUM(net_amount) OVER (
        PARTITION BY account_code, cost_center_name, fiscal_year
        ORDER BY period_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS net_amount_ytd,
    SUM(budget_amount) OVER (
        PARTITION BY account_code, cost_center_name, fiscal_year
        ORDER BY period_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS budget_ytd
FROM with_budget;


-- Dataset 2: Risk
-- Consolidates Risk - Credit and Risk - Operational subject areas.
CREATE OR REPLACE VIEW reporting.v_risk_dataset AS
SELECT
    r.risk_event_id,
    r.event_date,
    r.risk_category,
    r.risk_subcategory,
    r.severity,
    r.probability_score,
    r.impact_amount,
    r.status,
    r.owner,
    d.division,
    d.region,
    dt.fiscal_year,
    dt.fiscal_quarter,
    DATE_TRUNC('month', r.event_date) AS event_month,
    -- Running count of open events
    COUNT(CASE WHEN r.status = 'Open' THEN 1 END) OVER (
        PARTITION BY r.risk_category
        ORDER BY r.event_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_open_events,
    -- Severity ranking within category
    RANK() OVER (
        PARTITION BY r.risk_category, DATE_TRUNC('month', r.event_date)
        ORDER BY r.impact_amount DESC
    ) AS severity_rank
FROM fact_risk_events r
JOIN dim_division d   ON r.division_id = d.division_id
JOIN dim_date dt      ON r.date_key = dt.date_key;


-- Dataset 3: Operations
-- Consolidates Operations - Inventory, Shipping, Production, and Quality.
CREATE OR REPLACE VIEW reporting.v_operations_dataset AS
SELECT
    o.operation_id,
    o.operation_type,
    o.operation_date,
    p.product_name,
    p.product_line,
    f.facility_name,
    f.facility_type,
    d.division,
    dt.fiscal_year,
    DATE_TRUNC('month', o.operation_date) AS operation_month,
    o.quantity,
    o.unit_cost,
    o.total_cost,
    o.status,
    o.quality_score,
    o.defect_count,
    -- Rolling 3-month quality average per facility
    AVG(o.quality_score) OVER (
        PARTITION BY f.facility_name
        ORDER BY DATE_TRUNC('month', o.operation_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS quality_score_3m_avg,
    -- Cumulative defects YTD
    SUM(o.defect_count) OVER (
        PARTITION BY f.facility_name, dt.fiscal_year
        ORDER BY DATE_TRUNC('month', o.operation_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS defects_ytd
FROM fact_operations o
JOIN dim_product p    ON o.product_id = p.product_id
JOIN dim_facility f   ON o.facility_id = f.facility_id
JOIN dim_division d   ON o.division_id = d.division_id
JOIN dim_date dt      ON o.date_key = dt.date_key;
