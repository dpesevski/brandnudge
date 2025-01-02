CREATE FOREIGN TABLE PROD_FDW.ALERTS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        NAME varchar(255) OPTIONS (column_name 'name'),
        "userId" integer OPTIONS (column_name 'userId'),
        SCHEDULE JSONB OPTIONS (column_name 'schedule'),
        FILTERS JSONB OPTIONS (column_name 'filters'),
        PRICING JSONB OPTIONS (column_name 'pricing'),
        PROMOTION JSONB OPTIONS (column_name 'promotion'),
        AVAILABILITY JSONB OPTIONS (column_name 'availability'),
        LISTING JSONB OPTIONS (column_name 'listing'),
        SMS boolean OPTIONS (column_name 'sms'),
        "whatsApp" boolean OPTIONS (column_name 'whatsApp'),
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        MESSAGE text OPTIONS (column_name 'message'),
        EMAILS JSONB OPTIONS (column_name 'emails'),
        "isAllowEmpty" boolean OPTIONS (column_name 'isAllowEmpty')
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'alerts');

ALTER FOREIGN TABLE PROD_FDW.ALERTS
    OWNER TO POSTGRES;

