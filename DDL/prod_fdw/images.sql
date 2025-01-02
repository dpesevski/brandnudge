CREATE FOREIGN TABLE PROD_FDW.IMAGES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        SCORE varchar(255) OPTIONS (column_name 'score'),
        "ressemblePath" text OPTIONS (column_name 'ressemblePath'),
        "originalPath" text OPTIONS (column_name 'originalPath'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "modifiedPath" text OPTIONS (column_name 'modifiedPath'),
        "diffImage" text OPTIONS (column_name 'diffImage')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'images');

ALTER FOREIGN TABLE PROD_FDW.IMAGES
    OWNER TO POSTGRES;

