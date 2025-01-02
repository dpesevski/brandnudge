CREATE FOREIGN TABLE PROD_FDW.MAPPINGS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        EAN varchar(255) OPTIONS (column_name 'ean') NOT NULL,
        CODE varchar(255) OPTIONS (column_name 'code'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        RETAILER_ID integer OPTIONS (column_name 'retailer_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'mappings');

ALTER FOREIGN TABLE PROD_FDW.MAPPINGS
    OWNER TO POSTGRES;

