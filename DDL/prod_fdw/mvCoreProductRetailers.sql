CREATE FOREIGN TABLE PROD_FDW."mvCoreProductRetailers"
    (
        ID integer OPTIONS (column_name 'id'),
        "coreProductId" integer OPTIONS (column_name 'coreProductId'),
        RETAILERS integer[] OPTIONS (column_name 'retailers')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'mvCoreProductRetailers');

ALTER FOREIGN TABLE PROD_FDW."mvCoreProductRetailers"
    OWNER TO POSTGRES;

