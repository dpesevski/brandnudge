CREATE FOREIGN TABLE PROD_FDW."SequelizeMeta"
    (
        NAME varchar(255) OPTIONS (column_name 'name') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'SequelizeMeta');

ALTER FOREIGN TABLE PROD_FDW."SequelizeMeta"
    OWNER TO POSTGRES;

