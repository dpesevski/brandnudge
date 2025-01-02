CREATE FOREIGN TABLE PROD_FDW.MANUFACTURERS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        COLOR varchar(255) OPTIONS (column_name 'color') NOT NULL,
        "isOwnLabelManufacturer" boolean OPTIONS (column_name 'isOwnLabelManufacturer')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'manufacturers');

ALTER FOREIGN TABLE PROD_FDW.MANUFACTURERS
    OWNER TO POSTGRES;

