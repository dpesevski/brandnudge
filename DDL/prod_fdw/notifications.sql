CREATE FOREIGN TABLE PROD_FDW.NOTIFICATIONS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        MESSAGE text OPTIONS (column_name 'message'),
        STATUS boolean OPTIONS (column_name 'status'),
        "scraperErrorId" integer OPTIONS (column_name 'scraperErrorId'),
        "productErrorId" integer OPTIONS (column_name 'productErrorId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'notifications');

ALTER FOREIGN TABLE PROD_FDW.NOTIFICATIONS
    OWNER TO POSTGRES;

