CREATE TABLE data_corr.data_corr_records_to_update
(
    "retailerId"         integer,
    "coreProductId"      integer,
    "coreRetailerId"     integer,
    "new_coreRetailerId" integer,
    CONSTRAINT records_to_update_uq
        UNIQUE ("retailerId", "coreRetailerId")
);

ALTER TABLE data_corr.data_corr_records_to_update
    OWNER TO postgres;

GRANT SELECT ON data_corr.data_corr_records_to_update TO bn_ro;

GRANT SELECT ON data_corr.data_corr_records_to_update TO dejan_user;

