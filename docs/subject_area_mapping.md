# Subject Area Mapping

How the 10 OBIEE subject areas map to 6 Power BI datasets after consolidation.

## Consolidation summary

| OBIEE Subject Area | Power BI Dataset | Notes |
|---|---|---|
| Finance - GL | Finance | Combined into one dataset. Shared dim_account, dim_cost_center, dim_division. |
| Finance - AP | Finance | AP-specific columns added as flags on fact_gl_entries. |
| Finance - AR | Finance | AR aging logic moved to a DAX measure instead of a separate subject area. |
| Finance - Budget | Finance | Budget joined as a left join on account + cost center + month. |
| Risk - Credit | Risk | Combined. Shared fact_risk_events with category filter. |
| Risk - Operational | Risk | Same table, different risk_category values. |
| Operations - Inventory | Operations | Combined. operation_type column distinguishes inventory, shipping, production, quality. |
| Operations - Shipping | Operations | Same. |
| Operations - Production | Operations | Same. |
| Operations - Quality | Operations | Same. |

## Why 10 became 6

Four of the OBIEE subject areas (Finance - AP, Finance - AR, Operations - Shipping, Operations - Quality) existed because the RPD could not expose the same physical table through different join paths in a single subject area without creating alias tables. This was an RPD limitation, not a business requirement. The underlying data was already in the same tables.

Power BI doesn't have this limitation. One dataset can serve multiple report pages with different filters.

## Column mapping notes

Finance - AP had 12 columns that were just aliases for GL columns with "AP_" prefixes. These are mapped back to the original GL column names in the Power BI dataset. A mapping table is in `data/sample/sample_obiee_metadata.csv`.

Finance - AR had a calculated "aging bucket" column that was computed in the RPD logical layer. This is now a DAX measure in Power BI:

```dax
AR Aging Bucket =
SWITCH(
    TRUE(),
    [days_outstanding] <= 30, "Current",
    [days_outstanding] <= 60, "31-60",
    [days_outstanding] <= 90, "61-90",
    "90+"
)
```

Operations - Quality had a "quality score" column that was a weighted average computed in an RPD derived logical column. This is now a Snowflake view column calculated with a window function (see `sql/powerbi_target/dataset_views.sql`, the `quality_score_3m_avg` column).
