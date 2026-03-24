-- Extract row-level security rules from the OBIEE catalog.
-- These rules control which rows each user group can see.
-- They need to be translated into Power BI RLS DAX expressions.

-- 1. Catalog groups and their data filters
SELECT
    g.group_name,
    g.group_description,
    sf.subject_area_name,
    sf.filter_table,
    sf.filter_column,
    sf.filter_expression,
    sf.filter_type
FROM
    obiee_catalog.security_filters sf
JOIN obiee_catalog.groups g
    ON sf.group_id = g.group_id
WHERE sf.is_active = 1
ORDER BY g.group_name, sf.subject_area_name;

-- 2. User-to-group assignments
SELECT
    u.username,
    u.display_name,
    g.group_name,
    ug.assigned_date
FROM
    obiee_catalog.user_groups ug
JOIN obiee_catalog.users u ON ug.user_id = u.user_id
JOIN obiee_catalog.groups g ON ug.group_id = g.group_id
WHERE u.is_active = 1
ORDER BY g.group_name, u.username;

-- 3. Initialization blocks (session variables used in security filters)
--    These set user-specific values at login that the security filters reference.
SELECT
    ib.init_block_name,
    ib.sql_query,
    iv.variable_name,
    iv.default_value,
    ib.connection_pool,
    ib.execution_order
FROM
    obiee_rpd.init_blocks ib
JOIN obiee_rpd.init_variables iv
    ON ib.init_block_id = iv.init_block_id
ORDER BY ib.execution_order;
