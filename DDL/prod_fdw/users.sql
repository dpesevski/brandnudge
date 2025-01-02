CREATE FOREIGN TABLE PROD_FDW.USERS
    (
        ID integer OPTIONS (column_name 'id') NOT NULL,
        FIRST_NAME varchar(255) OPTIONS (column_name 'first_name') NOT NULL,
        LAST_NAME varchar(255) OPTIONS (column_name 'last_name') NOT NULL,
        EMAIL varchar(255) OPTIONS (column_name 'email') NOT NULL,
        STATUS ENUM_USERS_STATUS OPTIONS (column_name 'status') NOT NULL,
        PASSWORD varchar(255) OPTIONS (column_name 'password') NOT NULL,
        IS_STUFF boolean OPTIONS (column_name 'is_stuff'),
        "companyId" integer OPTIONS (column_name 'companyId') NOT NULL,
        "createdAt" timestamp with time zone OPTIONS (column_name 'createdAt') NOT NULL,
        "updatedAt" timestamp with time zone OPTIONS (column_name 'updatedAt') NOT NULL,
        "loginAttempts" integer OPTIONS (column_name 'loginAttempts'),
        "lastFilter" JSON OPTIONS (column_name 'lastFilter'),
        AVATAR varchar(255) OPTIONS (column_name 'avatar'),
        "jobTitle" varchar(255) OPTIONS (column_name 'jobTitle'),
        PHONE varchar(255) OPTIONS (column_name 'phone'),
        RETAILERS JSON OPTIONS (column_name 'retailers'),
        "rankingOrder" JSON OPTIONS (column_name 'rankingOrder'),
        "retailersOrder" JSON OPTIONS (column_name 'retailersOrder'),
        WATCHLIST boolean OPTIONS (column_name 'watchlist') NOT NULL,
        "watchlistFilter" JSONB OPTIONS (column_name 'watchlistFilter') NOT NULL,
        "colorTheme" JSON OPTIONS (column_name 'colorTheme'),
        "roleId" integer OPTIONS (column_name 'roleId'),
        "countryId" integer OPTIONS (column_name 'countryId') NOT NULL
        )
    SERVER PRODDB_FDW
    OPTIONS (schema_name 'public', table_name 'users');

ALTER FOREIGN TABLE PROD_FDW.USERS
    OWNER TO POSTGRES;

