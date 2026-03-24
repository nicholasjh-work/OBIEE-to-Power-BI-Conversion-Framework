-- Full inventory of OBIEE subject areas, tables, and columns.
-- Used to build the migration inventory and track progress.

SELECT
    ps.subject_area_name,
    pt.presentation_table_name,
    COUNT(pc.presentation_column_id) AS column_count,
    CASE
        WHEN ps.subject_area_name IN ('Finance - GL', 'Finance - AP', 'Finance - AR', 'Finance - Budget')
        THEN 'Finance'
        WHEN ps.subject_area_name IN ('Risk - Credit', 'Risk - Operational')
        THEN 'Risk'
        WHEN ps.subject_area_name IN ('Operations - Inventory', 'Operations - Shipping',
                                       'Operations - Production', 'Operations - Quality')
        THEN 'Operations'
        ELSE 'Other'
    END AS target_dataset,
    ps.last_modified_date,
    ps.created_by
FROM
    obiee_rpd.presentation_columns pc
JOIN obiee_rpd.presentation_tables pt
    ON pc.presentation_table_id = pt.table_id
JOIN obiee_rpd.presentation_subjects ps
    ON pt.subject_id = ps.subject_id
GROUP BY ps.subject_area_name, pt.presentation_table_name,
         ps.last_modified_date, ps.created_by
ORDER BY target_dataset, ps.subject_area_name, pt.presentation_table_name;
