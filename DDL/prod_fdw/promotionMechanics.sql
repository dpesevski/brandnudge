CREATE FOREIGN TABLE PROD_FDW."promotionMechanics"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'promotionMechanics');

ALTER FOREIGN TABLE PROD_FDW."promotionMechanics"
    OWNER TO POSTGRES;

