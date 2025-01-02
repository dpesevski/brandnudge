CREATE TABLE COMPANIES
(
    ID                 integer DEFAULT NEXTVAL('companies_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME               varchar(255)
        CONSTRAINT COMPANIES_UNIQUE
            UNIQUE,
    "createdAt"        timestamp with time zone                              NOT NULL,
    "updatedAt"        timestamp with time zone                              NOT NULL,
    "filtersStartDate" timestamp with time zone,
    COLOR              JSON    DEFAULT '{"primary":"#3b4799","secondary":"#767eb7"}'::JSON,
    AVATAR             varchar(255),
    "retailersOrder"   JSON    DEFAULT '[]'::JSON                            NOT NULL,
    DISABLED           boolean DEFAULT FALSE                                 NOT NULL,
    "endTime"          timestamp with time zone,
    MFA                boolean DEFAULT FALSE                                 NOT NULL,
    "tokenExpire"      integer,
    TRIAL              boolean DEFAULT FALSE
);

ALTER TABLE COMPANIES
    OWNER TO POSTGRES;

GRANT SELECT ON COMPANIES TO BN_RO;

GRANT SELECT ON COMPANIES TO BN_RO_ROLE;

GRANT SELECT ON COMPANIES TO BN_RO_USER1;

GRANT SELECT ON COMPANIES TO DEJAN_USER;

