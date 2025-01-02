CREATE FOREIGN TABLE PROD_FDW."userExportsSchedules"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        NAME text OPTIONS (column_name 'name'),
        SCHEDULE JSONB OPTIONS (column_name 'schedule'),
        SECTION text OPTIONS (column_name 'section'),
        DATA JSONB OPTIONS (column_name 'data'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "sectionId" integer OPTIONS (column_name 'sectionId'),
        EMAILS JSONB OPTIONS (column_name 'emails')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userExportsSchedules');

ALTER FOREIGN TABLE PROD_FDW."userExportsSchedules"
    OWNER TO POSTGRES;

