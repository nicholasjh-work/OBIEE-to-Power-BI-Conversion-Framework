# OBIEE to Power BI Migration Framework

**[Live Demo](https://nicholasjh-work.github.io/OBIEE-to-Power-BI-Conversion-Framework/)**

Migrated 240 legacy reports across finance, risk, and operations from OBIEE to Power BI. Consolidated 10 OBIEE subject areas into 6 Power BI datasets. Replicated row-level security from OBIEE catalog permissions. Every report validated within 1% variance on record counts and aggregates.

## What this project did

The org had been running OBIEE for 8 years. 240 reports, 10 subject areas, 500+ users. The RPD semantic layer had accumulated years of workarounds, duplicate logical columns, and undocumented security rules. Upgrading OBIEE was more expensive than migrating, and the team already knew Power BI.

The migration was not a rebuild. It was a conversion. Same business logic, same numbers, same security. The goal was zero surprises for the end users: they open the new report and the numbers match what they had yesterday.

This repo contains the framework used to execute that migration: the mapping documents, conversion patterns, validation SQL, and the data dictionary that kept everything straight.

## Repo structure

```
obiee-to-pbi/
  sql/
    obiee_source/
      extract_rpd_metadata.sql      Pull table, column, and join metadata from OBIEE RPD
      extract_catalog_security.sql   Pull row-level security rules from OBIEE catalog
      subject_area_inventory.sql     Inventory of all subject areas, tables, columns
    powerbi_target/
      dataflow_definitions.sql       Power BI dataflow SQL (replaces RPD semantic layer)
      dataset_views.sql              Snowflake views feeding each Power BI dataset
      rls_implementation.sql         Row-level security translated to Power BI roles
    validation/
      record_count_comparison.sql    Row counts: OBIEE source vs Power BI dataset
      aggregate_comparison.sql       Sum/avg/min/max on key measures, both sides
      dimension_value_check.sql      Distinct value comparison on all dimension columns
      security_audit.sql             Verify RLS produces same row sets per user
  powerquery/
    common_transforms.md             Reusable Power Query M patterns from the migration
  docs/
    migration_playbook.md            Step-by-step migration process
    subject_area_mapping.md          OBIEE subject areas mapped to Power BI datasets
    rpd_to_dataflow_patterns.md      How RPD constructs translate to Power BI
    rls_mapping.md                   OBIEE catalog security to Power BI RLS mapping
    data_dictionary.md               Live reference document maintained during migration
    validation_report.md             Summary of validation results across all 240 reports
  scripts/
    run_validation.py                Automated validation runner
    generate_mapping_report.py       Generates migration status report from config
  tests/
    test_validation.py               Pytest for validation logic
  config/
    migration_inventory.yaml         All 240 reports with status, owner, priority
    validation_thresholds.yaml       Acceptable variance thresholds per report type
  data/
    sample/
      sample_obiee_metadata.csv      Example RPD metadata extract
      sample_report_inventory.csv    Example report inventory
  .env.example
  .gitignore
  requirements.txt
  README.md
```

## Migration approach

### Phase 1: Inventory and mapping

Pulled the full inventory from the OBIEE RPD and catalog. Every subject area, every table, every column, every join, every security rule. Stored in `config/migration_inventory.yaml` with status tracking per report.

Mapped the 10 OBIEE subject areas to 6 Power BI datasets. The consolidation eliminated 4 redundant subject areas that had been created as workarounds for RPD limitations. Mapping is in `docs/subject_area_mapping.md`.

### Phase 2: Semantic layer conversion

The OBIEE RPD is a three-layer semantic model (physical, business model, presentation). Power BI doesn't have an equivalent. The conversion approach:

- Physical layer joins became Snowflake views (`sql/powerbi_target/dataset_views.sql`)
- Business model aggregation rules became DAX measures
- Presentation layer column aliases became Power BI field names
- RPD initialization blocks became Power Query parameters
- RPD session variables for security became Power BI RLS roles

Patterns are documented in `docs/rpd_to_dataflow_patterns.md`.

### Phase 3: Security replication

OBIEE catalog security controlled which rows each user could see, based on their group membership and data-level filters on the RPD. Translating this to Power BI RLS required:

1. Extracting every security rule from the OBIEE catalog
2. Mapping OBIEE groups to Power BI roles
3. Writing DAX filter expressions that replicate the OBIEE row filters
4. Testing each role against the OBIEE output to confirm identical row sets

The mapping and test results are in `docs/rls_mapping.md`.

### Phase 4: Validation

Every one of the 240 reports was validated before going live. The validation checked:

- Record counts (must match within 1%)
- Aggregate totals on all numeric measures (must match within 1%)
- Distinct dimension values (must be identical)
- Row-level security (same user must see same rows in both systems)

SQL for each check is in `sql/validation/`. The Python runner in `scripts/run_validation.py` automates the full suite and generates the report in `docs/validation_report.md`.

### Phase 5: Data dictionary

Maintained a live data dictionary throughout migration as the single reference point. Every column mapping, every business rule translation, every known discrepancy. The dictionary is in `docs/data_dictionary.md`.

## Tech stack

- OBIEE 12c (source system)
- Power BI Desktop and Power BI Service (target)
- Power Query M (data transformation)
- DAX (measures and RLS)
- Snowflake (data warehouse, reporting views)
- SQL (validation, metadata extraction)
- Python (automated validation runner)

## Getting started

```bash
git clone https://github.com/nicholasjh-work/OBIEE-to-Power-BI-Conversion-Framework.git
cd OBIEE-to-Power-BI-Conversion-Framework
pip install -r requirements.txt
cp .env.example .env

# Run validation suite
python scripts/run_validation.py

# Generate migration status report
python scripts/generate_mapping_report.py
```

## Disclaimer

The conversion framework and validation patterns in this repository reflect a production migration executed for an enterprise finance organization. The actual report definitions, RPD metadata, and proprietary business rules from that engagement remain confidential. Sample data and configurations included here are illustrative.
