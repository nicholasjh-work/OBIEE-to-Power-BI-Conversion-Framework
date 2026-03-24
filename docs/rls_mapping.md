# RLS Mapping

How OBIEE catalog security translates to Power BI row-level security.

## OBIEE security model

OBIEE used three layers of security:

1. Catalog permissions (who can see which report folders)
2. Data-level filters on the RPD (which rows a user can query)
3. Initialization blocks (session variables set at login that the filters reference)

Power BI replaces all three with RLS roles and workspace permissions.

## Group-to-role mapping

| OBIEE Group | OBIEE Filter | Power BI Role | DAX Expression | Table |
|---|---|---|---|---|
| Finance_NA | NQ_SESSION.REGION = 'North America' | Finance_NA | [region] = "North America" | dim_division |
| Finance_EMEA | NQ_SESSION.REGION = 'EMEA' | Finance_EMEA | [region] = "EMEA" | dim_division |
| Finance_APAC | NQ_SESSION.REGION = 'APAC' | Finance_APAC | [region] = "APAC" | dim_division |
| Finance_Global | No filter | Finance_Global | (no filter) | N/A |
| Risk_ReadOnly | SEVERITY IN ('High','Critical') | Risk_ReadOnly | [severity] = "High" \|\| [severity] = "Critical" | dim_severity |
| Operations_Plant | FACILITY = GET_USER() | Operations_Plant | [facility_email] = USERPRINCIPALNAME() | dim_facility |

## Init block replacement

OBIEE init blocks ran SQL at login to populate session variables. The most common was the region assignment:

```sql
-- OBIEE init block: Set_Region
SELECT region FROM user_region_map WHERE username = ':USER'
```

In Power BI, this is replaced by either:
- A direct DAX filter using USERPRINCIPALNAME() with a lookup table
- A static role assignment (simpler, used when the mapping doesn't change often)

We used static role assignments for region-based security (Finance_NA, Finance_EMEA, Finance_APAC) because the user-to-region mapping changes less than once a quarter. Operations_Plant uses USERPRINCIPALNAME() because plant assignments change more frequently.

## Testing results

Every role was tested by running the same query in both systems and comparing row counts. Results are in `docs/validation_report.md`. All security checks passed with exact row count matches.
