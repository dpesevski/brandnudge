CREATE TABLE staging.debug_coreretailertaxonomies
(
    id                   integer                  NOT NULL,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL,
    load_id              integer
);

ALTER TABLE staging.debug_coreretailertaxonomies
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreretailertaxonomies TO bn_ro;

GRANT SELECT ON staging.debug_coreretailertaxonomies TO dejan_user;

