CREATE TABLE migration.ms2_tmp_mig2nd_dup_prod_stat_history
(
    "retailerId"    integer,
    "coreProductId" integer,
    date            date,
    "productId"     integer,
    status          text
);

ALTER TABLE migration.ms2_tmp_mig2nd_dup_prod_stat_history
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_tmp_mig2nd_dup_prod_stat_history TO bn_ro;

GRANT SELECT ON migration.ms2_tmp_mig2nd_dup_prod_stat_history TO dejan_user;

