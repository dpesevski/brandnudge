CREATE TABLE COUNTRIES
(
    ID           serial
        PRIMARY KEY,
    NAME         varchar(255),
    ISO          varchar(255)
        CONSTRAINT COUNTRY_ISO_UNIQUE_CONSTRAINT
            UNIQUE,
    ISO3         varchar(255),
    "currencyId" integer
        REFERENCES CURRENCIES,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL,
    AVATAR       varchar(255)
);

ALTER TABLE COUNTRIES
    OWNER TO POSTGRES;

GRANT SELECT ON COUNTRIES TO BN_RO;

GRANT SELECT ON COUNTRIES TO BN_RO_ROLE;

GRANT SELECT ON COUNTRIES TO BN_RO_USER1;

GRANT SELECT ON COUNTRIES TO DEJAN_USER;

