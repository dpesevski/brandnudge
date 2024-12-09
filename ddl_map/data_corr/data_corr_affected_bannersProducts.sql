CREATE TABLE data_corr."data_corr_affected_bannersProducts"
(
    id               integer,
    "productId"      integer,
    "bannerId"       integer,
    "createdAt"      timestamp with time zone,
    "updatedAt"      timestamp with time zone,
    "coreRetailerId" integer
);

ALTER TABLE data_corr."data_corr_affected_bannersProducts"
    OWNER TO postgres;

GRANT SELECT ON data_corr."data_corr_affected_bannersProducts" TO bn_ro;

GRANT SELECT ON data_corr."data_corr_affected_bannersProducts" TO dejan_user;

