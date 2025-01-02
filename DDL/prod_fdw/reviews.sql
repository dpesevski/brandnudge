CREATE FOREIGN TABLE PROD_FDW.REVIEWS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "coreRetailerId" integer OPTIONS (column_name 'coreRetailerId') NOT NULL,
        "reviewId" text OPTIONS (column_name 'reviewId'),
        TITLE text OPTIONS (column_name 'title'),
        COMMENT text OPTIONS (column_name 'comment'),
        RATING integer OPTIONS (column_name 'rating'),
        DATE timestamp with time zone OPTIONS (column_name 'date'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'reviews');

ALTER FOREIGN TABLE PROD_FDW.REVIEWS
    OWNER TO POSTGRES;

