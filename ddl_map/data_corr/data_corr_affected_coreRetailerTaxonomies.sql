CREATE TABLE data_corr."data_corr_affected_coreRetailerTaxonomies"
(
    id                   integer,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone,
    "updatedAt"          timestamp with time zone,
    "new_coreRetailerId" integer
);

ALTER TABLE data_corr."data_corr_affected_coreRetailerTaxonomies"
    OWNER TO postgres;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailerTaxonomies" TO bn_ro;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailerTaxonomies" TO dejan_user;

