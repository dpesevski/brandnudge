CREATE FOREIGN TABLE PROD_FDW."productsChangeLog"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "changeType" varchar(255) OPTIONS (column_name 'changeType'),
        "changeFrom" text OPTIONS (column_name 'changeFrom'),
        "changeTo" text OPTIONS (column_name 'changeTo'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        "dateIdFrom" integer OPTIONS (column_name 'dateIdFrom'),
        "dateIdTo" integer OPTIONS (column_name 'dateIdTo')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productsChangeLog');

ALTER FOREIGN TABLE PROD_FDW."productsChangeLog"
    OWNER TO POSTGRES;

