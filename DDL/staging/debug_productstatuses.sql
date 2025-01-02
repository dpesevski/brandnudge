CREATE TABLE STAGING.DEBUG_PRODUCTSTATUSES
(
    ID          integer                  NOT NULL,
    "productId" integer,
    STATUS      varchar(255)             NOT NULL,
    SCREENSHOT  varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    LOAD_ID     integer
);

ALTER TABLE STAGING.DEBUG_PRODUCTSTATUSES
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_PRODUCTSTATUSES TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_PRODUCTSTATUSES TO DEJAN_USER;

