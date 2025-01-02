CREATE FOREIGN TABLE PROD_FDW."coreProducts"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        EAN varchar(255) OPTIONS (column_name 'ean'),
        TITLE text OPTIONS (column_name 'title'),
        IMAGE text OPTIONS (column_name 'image'),
        "secondaryImages" boolean OPTIONS (column_name 'secondaryImages'),
        DESCRIPTION text OPTIONS (column_name 'description'),
        FEATURES text OPTIONS (column_name 'features'),
        INGREDIENTS text OPTIONS (column_name 'ingredients'),
        "brandId" integer OPTIONS (column_name 'brandId'),
        "categoryId" integer OPTIONS (column_name 'categoryId'),
        "productGroupId" integer OPTIONS (column_name 'productGroupId'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        BUNDLED boolean OPTIONS (column_name 'bundled'),
        DISABLED boolean OPTIONS (column_name 'disabled') NOT NULL,
        "eanIssues" boolean OPTIONS (column_name 'eanIssues') NOT NULL,
        SPECIFICATION text OPTIONS (column_name 'specification'),
        SIZE varchar(255) OPTIONS (column_name 'size'),
        REVIEWED boolean OPTIONS (column_name 'reviewed') NOT NULL,
        "productOptions" boolean OPTIONS (column_name 'productOptions') NOT NULL,
        ATTRIBUTES JSON OPTIONS (column_name 'attributes'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'coreProducts');

ALTER FOREIGN TABLE PROD_FDW."coreProducts"
    OWNER TO POSTGRES;

