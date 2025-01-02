CREATE FOREIGN TABLE PROD_FDW.COMPANIES
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "filtersStartDate" timestamp with time zone OPTIONS (column_name 'filtersStartDate'),
        COLOR JSON OPTIONS (column_name 'color'),
        AVATAR varchar(255) OPTIONS (column_name 'avatar'),
        "retailersOrder" JSON OPTIONS (column_name 'retailersOrder') NOT NULL,
        DISABLED boolean OPTIONS (column_name 'disabled') NOT NULL,
        "endTime" timestamp with time zone OPTIONS (column_name 'endTime'),
        MFA boolean OPTIONS (column_name 'mfa') NOT NULL,
        "tokenExpire" integer OPTIONS (column_name 'tokenExpire'),
        TRIAL boolean OPTIONS (column_name 'trial')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'companies');

ALTER FOREIGN TABLE PROD_FDW.COMPANIES
    OWNER TO POSTGRES;

