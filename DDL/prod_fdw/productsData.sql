CREATE FOREIGN TABLE PROD_FDW."productsData"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "productId" integer OPTIONS (column_name 'productId'),
        CATEGORY varchar(255) OPTIONS (column_name 'category'),
        "categoryType" varchar(255) OPTIONS (column_name 'categoryType'),
        "parentCategory" varchar(255) OPTIONS (column_name 'parentCategory'),
        "productRank" integer OPTIONS (column_name 'productRank'),
        "pageNumber" varchar(255) OPTIONS (column_name 'pageNumber'),
        SCREENSHOT varchar(255) OPTIONS (column_name 'screenshot'),
        FEATURED boolean OPTIONS (column_name 'featured'),
        "featuredRank" integer OPTIONS (column_name 'featuredRank'),
        "taxonomyId" integer OPTIONS (column_name 'taxonomyId'),
        LOAD_ID integer OPTIONS (column_name 'load_id')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'productsData');

ALTER FOREIGN TABLE PROD_FDW."productsData"
    OWNER TO POSTGRES;

