CREATE FOREIGN TABLE PROD_FDW."mappingSuggestions"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreProductId" integer OPTIONS (column_name 'coreProductId') NOT NULL,
        "coreProductProduct" integer OPTIONS (column_name 'coreProductProduct') NOT NULL,
        "suggestedProductId" integer OPTIONS (column_name 'suggestedProductId') NOT NULL,
        "suggestedProductProduct" integer OPTIONS (column_name 'suggestedProductProduct') NOT NULL,
        MATCH real OPTIONS (column_name 'match') NOT NULL,
        "matchTitle" real OPTIONS (column_name 'matchTitle') NOT NULL,
        "matchIngredients" real OPTIONS (column_name 'matchIngredients') NOT NULL,
        "matchNutritional" real OPTIONS (column_name 'matchNutritional') NOT NULL,
        "matchImage" real OPTIONS (column_name 'matchImage') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "matchWeight" real OPTIONS (column_name 'matchWeight'),
        "matchPrice" real OPTIONS (column_name 'matchPrice')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'mappingSuggestions');

ALTER FOREIGN TABLE PROD_FDW."mappingSuggestions"
    OWNER TO POSTGRES;

