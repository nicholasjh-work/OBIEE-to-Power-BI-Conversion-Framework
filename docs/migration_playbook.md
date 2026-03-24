# Migration Playbook

Step-by-step process used to migrate 240 reports from OBIEE to Power BI.

## Pre-migration

1. Pull full RPD metadata using `sql/obiee_source/extract_rpd_metadata.sql`. Store in a tracking spreadsheet.
2. Pull catalog security rules using `sql/obiee_source/extract_catalog_security.sql`.
3. Run `sql/obiee_source/subject_area_inventory.sql` to get the full subject area and column inventory.
4. Build the migration inventory in `config/migration_inventory.yaml`. Assign target datasets, owners, and priorities.
5. Identify consolidation opportunities. Document in `docs/subject_area_mapping.md`.

## Per-report migration

For each report in the inventory:

1. Open the OBIEE report in Answers. Note the columns, filters, prompts, and sort order.
2. Map each OBIEE column to the Power BI dataset column using the data dictionary.
3. If the column is a derived RPD calculation, write the DAX equivalent. Document in `docs/data_dictionary.md`.
4. Build the Power BI report page. Match the layout and formatting as closely as practical.
5. Run validation checks from `sql/validation/`. Record results.
6. If validation passes (within 1% on counts and aggregates), mark as migrated in the inventory.
7. If validation fails, investigate using the data integrity framework. Document the root cause and resolution.

## Security migration

1. For each OBIEE security group, create a Power BI RLS role with the equivalent DAX filter.
2. Test each role using "View as Role" in Power BI Desktop.
3. Run `sql/validation/security_audit.sql` to confirm row counts match.
4. Assign users to roles in Power BI Service.

## Post-migration

1. Run the full validation suite one final time using `scripts/run_validation.py`.
2. Generate the migration status report using `scripts/generate_mapping_report.py`.
3. Publish the Power BI datasets and reports to Power BI Service.
4. Set up scheduled refresh (daily, matching the Snowflake refresh schedule).
5. Notify users of the cutover date. Provide a mapping of old OBIEE report names to new Power BI report names.
6. Keep OBIEE running in read-only mode for 30 days as a fallback.
7. After 30 days with no issues, decommission OBIEE.

## Rollback plan

If a critical issue is found after cutover:
- OBIEE remains available in read-only mode for 30 days
- Users revert to OBIEE for the affected reports only
- The migration team fixes the issue in Power BI and re-validates
- No data is lost because both systems read from the same Snowflake warehouse
