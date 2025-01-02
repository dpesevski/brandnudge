CREATE FOREIGN TABLE PROD_FDW."retailerTaxonomies"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "retailerId" integer OPTIONS (column_name 'retailerId') NOT NULL,
        "parentId" integer OPTIONS (column_name 'parentId'),
        CATEGORY varchar(255) OPTIONS (column_name 'category') NOT NULL,
        "categoryType" "enum_retailerTaxonomies_categoryType" OPTIONS (column_name 'categoryType') NOT NULL,
        URL text OPTIONS (column_name 'url') NOT NULL,
        LEVEL integer OPTIONS (column_name 'level') NOT NULL,
        POSITION integer OPTIONS (column_name 'position') NOT NULL,
        ARCHIVED boolean OPTIONS (column_name 'archived') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'retailerTaxonomies');

ALTER FOREIGN TABLE PROD_FDW."retailerTaxonomies"
    OWNER TO POSTGRES;

