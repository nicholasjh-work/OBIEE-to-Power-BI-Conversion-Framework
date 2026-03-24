-- Row-level security implementation for Power BI.
-- Translates OBIEE catalog security rules into Power BI RLS roles.
--
-- In OBIEE, security was enforced through:
--   1. Catalog groups with data-level filters on the RPD
--   2. Initialization blocks that set session variables per user
--   3. Security filters that referenced those session variables
--
-- In Power BI, security is enforced through:
--   1. RLS roles defined in the model
--   2. DAX filter expressions on dimension tables
--   3. Role assignments in Power BI Service

-- OBIEE had these security groups:
-- GROUP: Finance_NA       -> Filter: dim_division[region] = 'North America'
-- GROUP: Finance_EMEA     -> Filter: dim_division[region] = 'EMEA'
-- GROUP: Finance_APAC     -> Filter: dim_division[region] = 'APAC'
-- GROUP: Finance_Global   -> No filter (sees all regions)
-- GROUP: Risk_ReadOnly    -> Filter: fact_risk_events[severity] IN ('High','Critical')
-- GROUP: Operations_Plant -> Filter: dim_facility[facility_name] = USERNAME()

-- Power BI RLS role definitions (create in Power BI Desktop > Modeling > Manage Roles):

-- Role: Finance_NA
-- Table: dim_division
-- DAX: [region] = "North America"

-- Role: Finance_EMEA
-- Table: dim_division
-- DAX: [region] = "EMEA"

-- Role: Finance_APAC
-- Table: dim_division
-- DAX: [region] = "APAC"

-- Role: Finance_Global
-- No filter (full access). Assign to CFO, VP Finance, FP&A.

-- Role: Risk_ReadOnly
-- Table: fact_risk_events (via a bridge to dim_severity if needed)
-- DAX: [severity] = "High" || [severity] = "Critical"

-- Role: Operations_Plant
-- Table: dim_facility
-- DAX: [facility_name] = USERPRINCIPALNAME()
-- Note: USERPRINCIPALNAME() returns the logged-in user's email.
-- The facility_name column must contain the user's email for this to work.
-- If OBIEE used a separate mapping table, create a bridge table in Power BI.

-- Validation: for each OBIEE group, run this query against both systems.
-- The row counts should match exactly.

-- Example: validate Finance_NA sees only North America data
-- OBIEE side:
SELECT COUNT(*) AS obiee_row_count
FROM fact_gl_entries g
JOIN dim_division d ON g.division_id = d.division_id
WHERE d.region = 'North America';

-- Power BI side (run against Snowflake view with same filter):
SELECT COUNT(*) AS pbi_row_count
FROM reporting.v_finance_dataset
WHERE region = 'North America';

-- If counts differ, check:
-- 1. Is the OBIEE filter applied at the physical or logical layer?
-- 2. Does the OBIEE filter exclude reversed or template entries?
-- 3. Are there initialization block conditions the Power BI role doesn't replicate?
