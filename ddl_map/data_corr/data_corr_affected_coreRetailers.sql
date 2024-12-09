CREATE TABLE data_corr."data_corr_affected_coreRetailers"
(
    id              integer,
    "coreProductId" integer,
    "retailerId"    integer,
    "productId"     varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone
);

ALTER TABLE data_corr."data_corr_affected_coreRetailers"
    OWNER TO postgres;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailers" TO bn_ro;

GRANT SELECT ON data_corr."data_corr_affected_coreRetailers" TO dejan_user;

