CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_AMAZONPRODUCTS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        SHOP varchar(255) OPTIONS (column_name 'shop') NOT NULL,
        CHOICE varchar(255) OPTIONS (column_name 'choice'),
        "lowStock" boolean OPTIONS (column_name 'lowStock'),
        "sellParty" varchar(255) OPTIONS (column_name 'sellParty'),
        SELL varchar(255) OPTIONS (column_name 'sell'),
        "fulfilParty" varchar(255) OPTIONS (column_name 'fulfilParty'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_amazonproducts');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_AMAZONPRODUCTS
    OWNER TO POSTGRES;

