CREATE TABLE USERS
(
    ID                integer           DEFAULT NEXTVAL('users_id_seq'::REGCLASS)                                                  NOT NULL
        PRIMARY KEY,
    FIRST_NAME        varchar(255)                                                                                                 NOT NULL,
    LAST_NAME         varchar(255)                                                                                                 NOT NULL,
    EMAIL             varchar(255)                                                                                                 NOT NULL
        UNIQUE,
    STATUS            ENUM_USERS_STATUS DEFAULT 'active'::ENUM_USERS_STATUS                                                        NOT NULL,
    PASSWORD          varchar(255)                                                                                                 NOT NULL,
    IS_STUFF          boolean           DEFAULT FALSE,
    "companyId"       integer                                                                                                      NOT NULL
        REFERENCES COMPANIES,
    "createdAt"       timestamp with time zone                                                                                     NOT NULL,
    "updatedAt"       timestamp with time zone                                                                                     NOT NULL,
    "loginAttempts"   integer           DEFAULT 0,
    "lastFilter"      JSON,
    AVATAR            varchar(255),
    "jobTitle"        varchar(255),
    PHONE             varchar(255),
    RETAILERS         JSON,
    "rankingOrder"    JSON,
    "retailersOrder"  JSON,
    WATCHLIST         boolean           DEFAULT FALSE                                                                              NOT NULL,
    "watchlistFilter" JSONB             DEFAULT '{"category": [], "sourceType": [], "manufacture": [], "productBrand": []}'::JSONB NOT NULL,
    "colorTheme"      JSON,
    "roleId"          integer
        REFERENCES ROLES,
    "countryId"       integer           DEFAULT 1                                                                                  NOT NULL
        REFERENCES COUNTRIES
);

ALTER TABLE USERS
    OWNER TO POSTGRES;

GRANT SELECT ON USERS TO BN_RO;

GRANT SELECT ON USERS TO BN_RO_ROLE;

GRANT SELECT ON USERS TO BN_RO_USER1;

GRANT SELECT ON USERS TO DEJAN_USER;

