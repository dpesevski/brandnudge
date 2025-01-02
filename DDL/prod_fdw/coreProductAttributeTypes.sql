CREATE FOREIGN TABLE PROD_FDW."coreProductAttributeTypes"
    (
        "keyName" varchar(255) OPTIONS (column_name 'keyName') NOT NULL,
        "keyValue" text OPTIONS (column_name 'keyValue'),
        "valueType" "enum_coreProductAttributeTypes_valueType" OPTIONS (column_name 'valueType'),
        "valueOptions" JSON OPTIONS (column_name 'valueOptions'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreProductAttributeTypes');

ALTER FOREIGN TABLE PROD_FDW."coreProductAttributeTypes"
    OWNER TO POSTGRES;

