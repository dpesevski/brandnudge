WITH schema AS (SELECT table_schema,
                       table_name,

                       ordinal_position,
                       column_name,
                       data_type,
                       character_maximum_length,
                       columns.column_default,
                       COALESCE(columns.column_default LIKE 'nextval(%', FALSE) AS is_default_val_from_seq
                FROM information_schema.columns),
     table_agg AS (SELECT table_schema,
                          table_name,
                          STRING_AGG('IN "p_' || column_name || '" ' || data_type || CASE
                                                                                         WHEN data_type = 'character varying'
                                                                                             THEN ' (' || character_maximum_length || ')'
                                                                                         ELSE '' END, ', '
                          ORDER BY ordinal_position) FILTER ( WHERE NOT is_default_val_from_seq ) AS parameter_def,
                          STRING_AGG('"' || column_name || '"', ', ' ORDER BY ordinal_position)   AS column_list,
                          STRING_AGG(CASE
                                         WHEN is_default_val_from_seq THEN 'DEFAULT'
                                         ELSE '"p_' || column_name || '"' END,
                                     ', ' ORDER BY ordinal_position)                              AS value_list


                   FROM schema
                   GROUP BY table_schema, table_name)
SELECT STRING_AGG('CREATE OR REPLACE FUNCTION "ins_' || table_name || '"(' || parameter_def || ', OUT response "' ||
                  table_name || '", OUT sequelize_caught_exception text) RETURNS RECORD AS
      $$
      BEGIN
          INSERT INTO "' || table_name || '" (' || column_list || ')
          VALUES (' || value_list || ')
          RETURNING * INTO response;
      EXCEPTION
          WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
      END
      $$ LANGUAGE plpgsql;', CHR(10) || CHR(10)) AS ins_funtion_sql
FROM table_agg
WHERE table_schema = 'public'
  AND table_name IN ('coreProductBarcodes',
                     'coreProductSourceCategories',
                     'coreRetailerDates',
                     'coreRetailers',
                     'coreRetailerTaxonomies',
                     'promotions',
                     'scraperErrors');