CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_ERRORS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id'),
        SQL_STATE text OPTIONS (column_name 'sql_state'),
        MESSAGE text OPTIONS (column_name 'message'),
        DETAIL text OPTIONS (column_name 'detail'),
        HINT text OPTIONS (column_name 'hint'),
        CONTEXT text OPTIONS (column_name 'context'),
        FETCHED_DATA JSON OPTIONS (column_name 'fetched_data'),
        FLAG text OPTIONS (column_name 'flag'),
        CREATED_AT timestamp OPTIONS (column_name 'created_at')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_errors');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_ERRORS
    OWNER TO POSTGRES;

