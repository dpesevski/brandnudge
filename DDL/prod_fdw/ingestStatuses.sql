CREATE FOREIGN TABLE PROD_FDW."ingestStatuses"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        ENDPOINT varchar(255) OPTIONS (column_name 'endpoint'),
        STATUS varchar(255) OPTIONS (column_name 'status') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        RETAILER varchar(255) OPTIONS (column_name 'retailer')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'ingestStatuses');

ALTER FOREIGN TABLE PROD_FDW."ingestStatuses"
    OWNER TO POSTGRES;

