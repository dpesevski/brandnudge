CREATE TABLE data_corr.ms2_data_corr_ret_mig_prod_status_bck
(
    id          integer,
    "productId" integer NOT NULL
        CONSTRAINT data_corr_ret_mig_prod_status_bck_pk
            PRIMARY KEY,
    status      varchar(255),
    screenshot  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    load_id     integer
);

ALTER TABLE data_corr.ms2_data_corr_ret_mig_prod_status_bck
    OWNER TO postgres;

GRANT SELECT ON data_corr.ms2_data_corr_ret_mig_prod_status_bck TO bn_ro;

GRANT SELECT ON data_corr.ms2_data_corr_ret_mig_prod_status_bck TO dejan_user;

