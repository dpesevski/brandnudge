CREATE TABLE STAGING.DEBUG_RETAILERS
(
    ID          integer                  NOT NULL,
    NAME        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    COLOR       varchar(255)             NOT NULL,
    LOGO        varchar(255),
    "countryId" integer,
    LOAD_ID     integer
);

ALTER TABLE STAGING.DEBUG_RETAILERS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_RETAILERS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_RETAILERS TO DEJAN_USER;

