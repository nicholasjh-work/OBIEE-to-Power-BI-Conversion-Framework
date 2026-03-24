-- Extract metadata from the OBIEE RPD for migration inventory.
-- Run against the OBIEE repository database (typically Oracle).
-- Pulls physical tables, logical columns, joins, and presentation mappings.

-- 1. Physical layer: all tables and columns in the RPD
SELECT
    p.schema_name,
    p.table_name,
    pc.column_name,
    pc.data_type,
    pc.nullable,
    p.connection_pool
FROM
    obiee_rpd.physical_tables p
JOIN obiee_rpd.physical_columns pc
    ON p.table_id = pc.table_id
ORDER BY p.schema_name, p.table_name, pc.ordinal_position;

-- 2. Business model: logical table sources and join paths
SELECT
    lts.logical_table_name,
    lts.physical_table_name,
    lts.join_type,
    lts.join_expression,
    lts.aggregation_rule
FROM
    obiee_rpd.logical_table_sources lts
ORDER BY lts.logical_table_name;

-- 3. Presentation layer: columns exposed to end users
--    This is what users see in OBIEE Answers. Column names here
--    become field names in Power BI.
SELECT
    ps.subject_area_name,
    pt.presentation_table_name,
    pc.presentation_column_name,
    pc.logical_column_name,
    pc.description
FROM
    obiee_rpd.presentation_columns pc
JOIN obiee_rpd.presentation_tables pt
    ON pc.presentation_table_id = pt.table_id
JOIN obiee_rpd.presentation_subjects ps
    ON pt.subject_id = ps.subject_id
ORDER BY ps.subject_area_name, pt.presentation_table_name, pc.ordinal_position;

-- 4. Join paths between physical tables
SELECT
    j.join_name,
    j.left_table,
    j.right_table,
    j.join_type,
    j.join_expression,
    j.cardinality
FROM
    obiee_rpd.physical_joins j
ORDER BY j.left_table, j.right_table;
