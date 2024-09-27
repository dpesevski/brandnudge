/*WITH RECURSIVE view_deps AS (SELECT DISTINCT dependent_ns.nspname   AS dependent_schema,
                                             dependent_view.relname AS dependent_view,
                                             source_ns.nspname      AS source_schema,
                                             source_table.relname   AS source_table
                             FROM pg_depend
                                      JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.OID
                                      JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.OID
                                      JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.OID
                                      JOIN pg_namespace dependent_ns ON dependent_ns.OID = dependent_view.relnamespace
                                      JOIN pg_namespace source_ns ON source_ns.OID = source_table.relnamespace
                             WHERE NOT (dependent_ns.nspname = source_ns.nspname AND
                                        dependent_view.relname = source_table.relname)
                             UNION
                             SELECT DISTINCT dependent_ns.nspname   AS dependent_schema,
                                             dependent_view.relname AS dependent_view,
                                             source_ns.nspname      AS source_schema,
                                             source_table.relname   AS source_table
                             FROM pg_depend
                                      JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.OID
                                      JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.OID
                                      JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.OID
                                      JOIN pg_namespace dependent_ns ON dependent_ns.OID = dependent_view.relnamespace
                                      JOIN pg_namespace source_ns ON source_ns.OID = source_table.relnamespace
                                      INNER JOIN view_deps vd
                                                 ON vd.dependent_schema = source_ns.nspname
                                                     AND vd.dependent_view = source_table.relname
                                                     AND NOT (dependent_ns.nspname = vd.dependent_schema AND
                                                              dependent_view.relname = vd.dependent_view))

SELECT *
FROM view_deps
ORDER BY source_schema, source_table;
*/


WITH index_def AS (SELECT tnsp.nspname                AS table_schema,
                          tbl.relname                 AS table_name,
                          insp.nspname                AS index_schema,
                          index_name::text,
                          pgi.indisprimary,
                          pgi.indisunique,
                          PG_GET_INDEXDEF(index_name) AS definition
                   FROM pg_index pgi
                            JOIN pg_class idx ON idx.OID = pgi.indexrelid
                            JOIN pg_namespace insp ON insp.OID = idx.relnamespace
                            JOIN pg_class tbl ON tbl.OID = pgi.indrelid
                            JOIN pg_namespace tnsp ON tnsp.OID = tbl.relnamespace
                            CROSS JOIN LATERAL (SELECT (tnsp.nspname || '."' || idx.relname || '"')::regclass AS index_name) AS lat),
     constraint_def AS (SELECT tnsp.nspname                                   AS constraint_schema,
                               tbl.relname                                    AS table_name, --('reviews'::regclass);
                               con.conname                                    AS constraint_name,
                               pg_catalog.pg_get_constraintdef(con.OID, TRUE) AS constraint_definition
                        FROM pg_catalog.pg_constraint con
                                 INNER JOIN pg_namespace tnsp ON (tnsp.OID = con.connamespace)
                                 INNER JOIN pg_class AS tbl ON (conrelid = tbl.OID)),
     all_constraints AS (SELECT table_schema, table_name, index_name AS constraint_name, definition
                         FROM index_def
                         WHERE table_schema = 'public'
                           AND indisunique
                         UNION ALL
                         SELECT constraint_schema, table_name, constraint_name, constraint_definition
                         FROM constraint_def
                         WHERE constraint_schema = 'public')
SELECT table_name, constraint_name, definition
FROM all_constraints
WHERE LOWER(definition) LIKE LOWER('%coreRetailerId%')
ORDER BY table_name;

WITH fk AS (SELECT cl1.relname::text AS table_name, cl2.relname::text AS ref_table, co.conname
            FROM pg_constraint AS co
                     JOIN pg_class AS cl1 ON co.conrelid = cl1.OID
                     JOIN pg_class AS cl2 ON co.confrelid = cl2.OID
            WHERE co.contype = 'f')
SELECT *
FROM fk
WHERE 'coreRetailers' IN (table_name, ref_table)
--AND    ARRAY ['coreRetailers', 'reviews','coreRetailerTaxonomies','bannersProducts','coreRetailerDates','coreRetailerSources'] &&    ARRAY [table_name, ref_table]
ORDER BY ref_table;
