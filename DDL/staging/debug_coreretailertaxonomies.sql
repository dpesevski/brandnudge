CREATE TABLE STAGING.DEBUG_CORERETAILERTAXONOMIES
(
    ID                   integer                  NOT NULL,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL,
    LOAD_ID              integer
);

ALTER TABLE STAGING.DEBUG_CORERETAILERTAXONOMIES
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERTAXONOMIES TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_CORERETAILERTAXONOMIES TO DEJAN_USER;

