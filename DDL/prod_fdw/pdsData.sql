CREATE FOREIGN TABLE PROD_FDW."pdsData"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        SUM numeric(12, 2) OPTIONS (column_name 'sum'),
        UNITS integer OPTIONS (column_name 'units'),
        TYPE varchar(255) OPTIONS (column_name 'type'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "pdsCoreId" integer OPTIONS (column_name 'pdsCoreId') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'pdsData');

ALTER FOREIGN TABLE PROD_FDW."pdsData"
    OWNER TO POSTGRES;

