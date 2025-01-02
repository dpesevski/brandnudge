CREATE TABLE STAGING.DEBUG_CORERETAILERS
(
    "sourceId"      text,
    ID              integer                  NOT NULL,
    "coreProductId" integer,
    "retailerId"    integer,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    LOAD_ID         integer
);

ALTER TABLE STAGING.DEBUG_CORERETAILERS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERS TO DEJAN_USER;

