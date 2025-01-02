CREATE TABLE DATA_CORR."data_corr_affected_bannersProducts"
(
    ID               integer,
    "productId"      integer,
    "bannerId"       integer,
    "createdAt"      timestamp with time zone,
    "updatedAt"      timestamp with time zone,
    "coreRetailerId" integer
);

ALTER TABLE DATA_CORR."data_corr_affected_bannersProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR."data_corr_affected_bannersProducts" TO BN_RO;

GRANT SELECT ON DATA_CORR."data_corr_affected_bannersProducts" TO DEJAN_USER;

