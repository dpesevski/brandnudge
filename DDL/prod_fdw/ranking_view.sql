CREATE FOREIGN TABLE PROD_FDW.RANKING_VIEW
    (
        CATEGORY varchar(255) OPTIONS (column_name 'category'),
        "categoryType" varchar(255) OPTIONS (column_name 'categoryType'),
        "retailerId" integer OPTIONS (column_name 'retailerId'),
        "dateId" integer OPTIONS (column_name 'dateId'),
        "productRankCount" integer OPTIONS (column_name 'productRankCount'),
        "featuredRankCount" integer OPTIONS (column_name 'featuredRankCount')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'ranking_view');

ALTER FOREIGN TABLE PROD_FDW.RANKING_VIEW
    OWNER TO POSTGRES;

