CREATE FOREIGN TABLE PRODDB_STAGING_FDW.LOAD
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        DATA JSON OPTIONS (column_name 'data'),
        FLAG text OPTIONS (column_name 'flag'),
        RUN_AT timestamp OPTIONS (column_name 'run_at'),
        DD_DATE date OPTIONS (column_name 'dd_date'),
        DD_RETAILER RETAILERS OPTIONS (column_name 'dd_retailer'),
        DD_DATE_ID integer OPTIONS (column_name 'dd_date_id'),
        DD_SOURCE_TYPE text OPTIONS (column_name 'dd_source_type'),
        EXECUTION_TIME double precision OPTIONS (column_name 'execution_time')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'load');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.LOAD
    OWNER TO POSTGRES;

