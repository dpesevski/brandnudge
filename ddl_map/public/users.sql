CREATE TABLE users
(
    id                integer           DEFAULT NEXTVAL('users_id_seq'::regclass)                                                  NOT NULL
        PRIMARY KEY,
    first_name        varchar(255)                                                                                                 NOT NULL,
    last_name         varchar(255)                                                                                                 NOT NULL,
    email             varchar(255)                                                                                                 NOT NULL
        UNIQUE,
    status            enum_users_status DEFAULT 'active'::enum_users_status                                                        NOT NULL,
    password          varchar(255)                                                                                                 NOT NULL,
    is_stuff          boolean           DEFAULT FALSE,
    "companyId"       integer                                                                                                      NOT NULL
        REFERENCES companies,
    "createdAt"       timestamp with time zone                                                                                     NOT NULL,
    "updatedAt"       timestamp with time zone                                                                                     NOT NULL,
    "loginAttempts"   integer           DEFAULT 0,
    "lastFilter"      json,
    avatar            varchar(255),
    "jobTitle"        varchar(255),
    phone             varchar(255),
    retailers         json,
    "rankingOrder"    json,
    "retailersOrder"  json,
    watchlist         boolean           DEFAULT FALSE                                                                              NOT NULL,
    "watchlistFilter" jsonb             DEFAULT '{"category": [], "sourceType": [], "manufacture": [], "productBrand": []}'::jsonb NOT NULL,
    "colorTheme"      json,
    "roleId"          integer
        REFERENCES roles,
    "countryId"       integer           DEFAULT 1                                                                                  NOT NULL
        REFERENCES countries
);

ALTER TABLE users
    OWNER TO postgres;

GRANT SELECT ON users TO bn_ro;

GRANT SELECT ON users TO bn_ro_role;

GRANT SELECT ON users TO bn_ro_user1;

GRANT SELECT ON users TO dejan_user;

