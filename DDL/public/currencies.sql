CREATE TABLE CURRENCIES
(
    ID          serial
        PRIMARY KEY,
    NAME        varchar(255),
    ISO         varchar(255),
    SYMBOL      varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE CURRENCIES
    OWNER TO POSTGRES;

GRANT SELECT ON CURRENCIES TO BN_RO;

GRANT SELECT ON CURRENCIES TO BN_RO_ROLE;

GRANT SELECT ON CURRENCIES TO BN_RO_USER1;

GRANT SELECT ON CURRENCIES TO DEJAN_USER;

