# Data Dictionary

Single reference document maintained throughout the OBIEE to Power BI migration. Every column mapping, business rule translation, and known discrepancy is recorded here.

## How to use this document

If a number in Power BI doesn't match what OBIEE showed, check here first. The dictionary explains what changed and why. If a mapping is missing, it's a bug in the migration, not a feature.

## Finance dataset column mappings

| OBIEE Column | Power BI Column | Type | Notes |
|---|---|---|---|
| GL.Journal Number | journal_id | VARCHAR | Renamed for consistency. |
| GL.Posting Date | posting_date | DATE | Same. |
| GL.Account Code | account_code | VARCHAR | Same. |
| GL.Account Description | account_name | VARCHAR | Renamed. Source: dim_account. |
| GL.Account Type | account_type | VARCHAR | Revenue, Expense, Asset, Liability. |
| GL.Cost Center | cost_center_name | VARCHAR | Source: dim_cost_center. |
| GL.Division | division | VARCHAR | Source: dim_division. |
| GL.Region | region | VARCHAR | Source: dim_division. |
| GL.Fiscal Year | fiscal_year | INTEGER | Source: dim_date. |
| GL.Debit Amount | debit_amount | DECIMAL(15,2) | Same. |
| GL.Credit Amount | credit_amount | DECIMAL(15,2) | Same. |
| GL.Net Amount | net_amount | DECIMAL(15,2) | Debit minus credit. Same calculation as OBIEE. |
| AP.Invoice Amount | net_amount | DECIMAL(15,2) | AP amounts are now in the same column as GL. Filtered by source_system = 'AP'. |
| AP.Vendor Name | (joined from dim_vendor) | VARCHAR | Requires a separate join. Not in the base finance view. |
| AR.Outstanding Amount | net_amount | DECIMAL(15,2) | AR amounts filtered by account_type = 'Asset' AND account_group = 'Receivables'. |
| AR.Aging Bucket | (DAX measure) | VARCHAR | Was a derived RPD column. Now a DAX SWITCH measure. See subject_area_mapping.md. |
| Budget.Budget Amount | budget_amount | DECIMAL(15,2) | Left joined to GL on account + cost center + month. NULL if no budget row. |
| Budget.Forecast Amount | forecast_amount | DECIMAL(15,2) | Same join as budget. Only populated after mid-year reforecast. |

## Known discrepancies

| Area | Discrepancy | Resolution |
|---|---|---|
| Finance - AR aging | OBIEE calculated aging at login time using SYSDATE. Power BI calculates at query time using TODAY(). | Aging buckets may differ by 1 day depending on when the user runs the report. Accepted as a known difference. |
| Finance - Budget | OBIEE showed the original budget until reforecast was approved, then switched. Power BI shows whichever version has budget_version = 'APPROVED'. | Identical behavior. No discrepancy. |
| Operations - Quality | OBIEE calculated a 3-month rolling average in the RPD derived column. Power BI calculates it in the Snowflake view. | Results match within 0.01 due to rounding differences. Within tolerance. |
| Risk - Severity | OBIEE sorted severity as Critical, High, Medium, Low using a custom sort order in the presentation layer. | Created a sort_order column in dim_severity. Power BI sorts by this column. |

## Business rules translated to DAX

| Rule | OBIEE Implementation | Power BI Implementation |
|---|---|---|
| AR aging buckets | Derived logical column using CASE on SYSDATE - invoice_date | DAX SWITCH on days_outstanding calculated column |
| Fiscal year rollup | RPD aggregation at fiscal_year grain | DATESYTD with "6/30" year-end parameter |
| Budget vs actual variance | RPD calculated as actual - budget in the business model | DAX measure: [OPEX Variance] = [OPEX Actual] - [OPEX Budget] |
| Cost center hierarchy | RPD drill path: function > department > cost center | Power BI hierarchy on dim_cost_center table |
| Regional security filter | RPD init block setting NQ_SESSION.REGION | Power BI RLS role with DAX filter on dim_division[region] |
