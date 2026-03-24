# Common Power Query M Patterns

Reusable Power Query transforms used across the migration. These replaced OBIEE RPD logical column calculations and initialization block logic.

## Date key to date conversion

OBIEE used integer date keys (YYYYMMDD). Power Query converts these to proper dates:

```m
= Table.AddColumn(Source, "calendar_date",
    each Date.From(
        Text.From([date_key]),
        "yyyyMMdd"
    ),
    type date
)
```

## Fiscal year calculation

Fiscal year ends June 30. July 2024 is FY2025.

```m
= Table.AddColumn(Source, "fiscal_year",
    each if Date.Month([calendar_date]) >= 7
         then Date.Year([calendar_date]) + 1
         else Date.Year([calendar_date]),
    Int64.Type
)
```

## Null handling for budget joins

Budget rows don't exist for every cost center and month. After the left join, null budget amounts need to be handled explicitly.

```m
= Table.ReplaceValue(Source, null, 0,
    Replacer.ReplaceValue,
    {"budget_amount", "forecast_amount"}
)
```

## Column renaming from OBIEE conventions

OBIEE presentation columns used spaces and special characters. Power BI fields use underscores.

```m
= Table.TransformColumnNames(Source,
    each Text.Replace(
        Text.Replace(
            Text.Lower(_),
            " ", "_"
        ),
        "/", "_"
    )
)
```

## Removing OBIEE-specific columns

Columns that only existed for RPD join purposes (alias keys, opaque view IDs) are dropped.

```m
= Table.RemoveColumns(Source,
    {"rpd_alias_key", "opaque_view_id", "lts_source_id"}
)
```
