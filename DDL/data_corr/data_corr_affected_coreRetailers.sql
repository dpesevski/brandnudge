CREATE TABLE DATA_CORR."data_corr_affected_coreRetailers"
(
    ID              integer,
    "coreProductId" integer,
    "retailerId"    integer,
    "productId"     varchar(255),
    "createdAt"     timestamp with time zone,
    "updatedAt"     timestamp with time zone
);

ALTER TABLE DATA_CORR."data_corr_affected_coreRetailers"
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailers" TO BN_RO;

GRANT SELECT ON DATA_CORR."data_corr_affected_coreRetailers" TO DEJAN_USER;

