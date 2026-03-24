# RPD to Power BI Conversion Patterns

How each OBIEE RPD construct translates to its Power BI equivalent.

## Physical layer

| OBIEE RPD | Power BI Equivalent | Notes |
|---|---|---|
| Physical table | Snowflake view or table | Views preferred. They let you control joins and filters before Power BI sees the data. |
| Physical join | Snowflake view JOIN | Joins happen in the view, not in Power BI. Reduces model complexity. |
| Connection pool | Snowflake connection string | One connection in Power BI Desktop. Credentials managed in Power BI Service. |
| Alias table | Not needed | Power BI can reference the same table through different relationships without aliases. |
| Opaque view | Snowflake view | Replace opaque views with named views in the reporting schema. |

## Business model layer

| OBIEE RPD | Power BI Equivalent | Notes |
|---|---|---|
| Logical table | Power BI table (imported or DirectQuery) | One logical table per Power BI table. |
| Logical column | Power BI column or measure | If it's a stored value, it's a column. If it's calculated, it's a DAX measure. |
| Derived logical column | DAX calculated column or measure | Prefer measures over calculated columns for aggregations. |
| Logical table source | Snowflake view | The LTS join logic moves to the view. |
| Aggregation rule (SUM, AVG, COUNT) | DAX measure | Explicit. Never rely on implicit aggregation. |
| Level-based measure | DAX with CALCULATE + filter | Use CALCULATE to fix the aggregation level. |
| Session variable | Power Query parameter or RLS USERNAME() | Depends on what the variable controlled. |
| Initialization block | Power BI Service connection credentials | If the init block set a user-specific filter, it becomes RLS. |

## Presentation layer

| OBIEE RPD | Power BI Equivalent | Notes |
|---|---|---|
| Subject area | Power BI dataset | One dataset per logical grouping. |
| Presentation table | Power BI table (as shown in Fields pane) | Name matches the user-facing label. |
| Presentation column | Power BI field | Same name as OBIEE unless it was misleading. |
| Column description | Power BI field description | Set in Model view. Visible on hover in report builder. |

## Security

| OBIEE RPD | Power BI Equivalent | Notes |
|---|---|---|
| Catalog group | Power BI workspace role or RLS role | Workspace roles control access to the dashboard. RLS controls which rows are visible. |
| Data-level filter | RLS DAX expression | Applied to the dimension table that the OBIEE filter targeted. |
| Row-level security filter | Power BI RLS role | One role per OBIEE security group. DAX expression replicates the filter. |
| OBIEE group membership | Power BI Service role assignment | Assigned per user or per AAD group in Power BI Service. |

## Common conversion pitfalls

**Double-counting after removing alias tables.** OBIEE alias tables prevented fan traps (one fact joining to two dimensions that share a bridge). Without aliases, Power BI can create ambiguous paths. Fix: use inactive relationships and USERELATIONSHIP() in DAX, or pre-aggregate in the Snowflake view.

**Implicit aggregation mismatch.** OBIEE defaulted to SUM on every measure column. Power BI also defaults to SUM but only if the column is numeric. If a measure was set to AVG or COUNT in the RPD, you need an explicit DAX measure. Do not rely on the default.

**Init block timing.** OBIEE init blocks ran at session start and set variables for the entire session. Power BI RLS evaluates on every query. If the OBIEE init block pulled from a slowly-changing table (like a user-to-region mapping), the Power BI equivalent needs to reference a similar mapping table in the model or use USERPRINCIPALNAME() with a lookup.

**Presentation column names with special characters.** OBIEE allowed characters in presentation names that Power BI doesn't (e.g., forward slashes, parentheses in names). Rename during migration. Track in the data dictionary.
