CREATE TABLE SECTIONS
(
    ID          serial
        PRIMARY KEY,
    NAME        varchar(255)
        UNIQUE,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    TITLE       varchar(255)
);

ALTER TABLE SECTIONS
    OWNER TO POSTGRES;

GRANT SELECT ON SECTIONS TO BN_RO;

GRANT SELECT ON SECTIONS TO BN_RO_ROLE;

GRANT SELECT ON SECTIONS TO BN_RO_USER1;

GRANT SELECT ON SECTIONS TO DEJAN_USER;

