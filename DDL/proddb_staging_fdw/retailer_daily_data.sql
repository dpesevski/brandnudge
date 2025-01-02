CREATE FOREIGN TABLE PRODDB_STAGING_FDW.RETAILER_DAILY_DATA
    (
        LOAD_ID integer OPTIONS (column_name 'load_id') NOT NULL,
        FETCHED_DATA JSON OPTIONS (column_name 'fetched_data'),
        FLAG text OPTIONS (column_name 'flag'),
        CREATED_AT timestamp with time zone OPTIONS (column_name 'created_at')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'retailer_daily_data');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.RETAILER_DAILY_DATA
    OWNER TO POSTGRES;

