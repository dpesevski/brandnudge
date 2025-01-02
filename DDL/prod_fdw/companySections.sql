CREATE FOREIGN TABLE PROD_FDW."companySections"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "companyId" integer OPTIONS (column_name 'companyId'),
        "sectionId" integer OPTIONS (column_name 'sectionId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companySections');

ALTER FOREIGN TABLE PROD_FDW."companySections"
    OWNER TO POSTGRES;

