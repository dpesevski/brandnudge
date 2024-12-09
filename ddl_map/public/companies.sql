CREATE TABLE companies
(
    id                 integer DEFAULT NEXTVAL('companies_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name               varchar(255)
        CONSTRAINT companies_unique
            UNIQUE,
    "createdAt"        timestamp with time zone                              NOT NULL,
    "updatedAt"        timestamp with time zone                              NOT NULL,
    "filtersStartDate" timestamp with time zone,
    color              json    DEFAULT '{"primary":"#3b4799","secondary":"#767eb7"}'::json,
    avatar             varchar(255),
    "retailersOrder"   json    DEFAULT '[]'::json                            NOT NULL,
    disabled           boolean DEFAULT FALSE                                 NOT NULL,
    "endTime"          timestamp with time zone,
    mfa                boolean DEFAULT FALSE                                 NOT NULL,
    "tokenExpire"      integer,
    trial              boolean DEFAULT FALSE
);

ALTER TABLE companies
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON companies_unique TO postgres;

GRANT SELECT ON companies_unique TO bn_ro;

GRANT SELECT ON companies_unique TO bn_ro_role;

GRANT SELECT ON companies_unique TO bn_ro_user1;

GRANT SELECT ON companies_unique TO dejan_user;

GRANT SELECT ON companies TO bn_ro;

GRANT SELECT ON companies TO bn_ro_role;

GRANT SELECT ON companies TO bn_ro_user1;

GRANT SELECT ON companies TO dejan_user;

