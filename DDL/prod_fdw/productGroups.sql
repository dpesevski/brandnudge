CREATE FOREIGN TABLE PROD_FDW."productGroups"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        "companyId" integer OPTIONS (column_name 'companyId'),
        COLOR varchar(255) OPTIONS (column_name 'color') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productGroups');

ALTER FOREIGN TABLE PROD_FDW."productGroups"
    OWNER TO POSTGRES;

