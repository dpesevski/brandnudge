CREATE FOREIGN TABLE PROD_FDW."userSummaryPerformances"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId'),
        METRICS JSONB OPTIONS (column_name 'metrics'),
        "order" JSONB OPTIONS (column_name 'order'),
        RETAILERS JSONB OPTIONS (column_name 'retailers'),
        GOALS JSONB OPTIONS (column_name 'goals'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userSummaryPerformances');

ALTER FOREIGN TABLE PROD_FDW."userSummaryPerformances"
    OWNER TO POSTGRES;

