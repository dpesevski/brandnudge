CREATE FOREIGN TABLE PROD_FDW."scraperErrors"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        TYPE varchar(255) OPTIONS (column_name 'type') NOT NULL,
        MESSAGE text OPTIONS (column_name 'message') NOT NULL,
        URL text OPTIONS (column_name 'url') NOT NULL,
        RESOLVED boolean OPTIONS (column_name 'resolved'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'scraperErrors');

ALTER FOREIGN TABLE PROD_FDW."scraperErrors"
    OWNER TO POSTGRES;

