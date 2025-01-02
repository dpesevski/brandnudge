CREATE FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_COREPRODUCTCOUNTRYDATA
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        "countryId" integer OPTIONS (column_name 'countryId'),
        TITLE text OPTIONS (column_name 'title'),
        IMAGE text OPTIONS (column_name 'image'),
        DESCRIPTION text OPTIONS (column_name 'description'),
        FEATURES text OPTIONS (column_name 'features'),
        INGREDIENTS text OPTIONS (column_name 'ingredients'),
        SPECIFICATION text OPTIONS (column_name 'specification'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "secondaryImages" varchar(255) OPTIONS (column_name 'secondaryImages'),
        BUNDLED boolean OPTIONS (column_name 'bundled'),
        DISABLED boolean OPTIONS (column_name 'disabled'),
        REVIEWED boolean OPTIONS (column_name 'reviewed'),
        "ownLabelManufacturerId" integer OPTIONS (column_name 'ownLabelManufacturerId'),
        "brandbankManaged" boolean OPTIONS (column_name 'brandbankManaged'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'staging', table_name 'debug_coreproductcountrydata');

ALTER FOREIGN TABLE PRODDB_STAGING_FDW.DEBUG_COREPRODUCTCOUNTRYDATA
    OWNER TO POSTGRES;

