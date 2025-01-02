CREATE TABLE DATA_CORR."data_corr_affected_coreRetailerTaxonomies"
(
    ID                   integer,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE DATA_CORR."data_corr_affected_coreRetailerTaxonomies"
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailerTaxonomies" TO BN_RO;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailerTaxonomies" TO DEJAN_USER;

