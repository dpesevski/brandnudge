CREATE TABLE STAGING.DEBUG_CORERETAILERDATES
(
    ID               integer                  NOT NULL,
    "coreRetailerId" integer,
    "dateId"         integer,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL,
    LOAD_ID          integer
);

ALTER TABLE STAGING.DEBUG_CORERETAILERDATES
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERDATES TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERDATES TO DEJAN_USER;

