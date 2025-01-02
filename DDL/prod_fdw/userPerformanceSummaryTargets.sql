CREATE FOREIGN TABLE PROD_FDW."userPerformanceSummaryTargets"
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        "userId" integer OPTIONS (column_name 'userId') NOT NULL,
        METRIC varchar(255) OPTIONS (column_name 'metric') NOT NULL,
        "parentId" integer OPTIONS (column_name 'parentId'),
        MIN integer OPTIONS (column_name 'min'),
        MAX integer OPTIONS (column_name 'max'),
        ADDITIONAL JSONB OPTIONS (column_name 'additional'),
        COMMON boolean OPTIONS (column_name 'common') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'userPerformanceSummaryTargets');

ALTER FOREIGN TABLE PROD_FDW."userPerformanceSummaryTargets"
    OWNER TO POSTGRES;

