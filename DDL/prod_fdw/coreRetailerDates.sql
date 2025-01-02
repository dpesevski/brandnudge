CREATE FOREIGN TABLE PROD_FDW."coreRetailerDates"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId'),
        "dateId" integer OPTIONS (column_name 'dateId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreRetailerDates');

ALTER FOREIGN TABLE PROD_FDW."coreRetailerDates"
    OWNER TO POSTGRES;

