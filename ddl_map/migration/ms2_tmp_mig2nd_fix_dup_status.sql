CREATE TABLE migration.ms2_tmp_mig2nd_fix_dup_status
(
    "retailerId"    integer,
    "coreProductId" integer,
    date            date,
    "productId"     integer,
    status          text
);

ALTER TABLE migration.ms2_tmp_mig2nd_fix_dup_status
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_tmp_mig2nd_fix_dup_status TO bn_ro;

GRANT SELECT ON migration.ms2_tmp_mig2nd_fix_dup_status TO dejan_user;

