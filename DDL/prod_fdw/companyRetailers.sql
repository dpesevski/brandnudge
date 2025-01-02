CREATE FOREIGN TABLE PROD_FDW."companyRetailers"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "companyId" integer OPTIONS (column_name 'companyId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companyRetailers');

ALTER FOREIGN TABLE PROD_FDW."companyRetailers"
    OWNER TO POSTGRES;

