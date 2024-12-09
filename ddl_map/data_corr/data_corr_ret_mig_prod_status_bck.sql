CREATE TABLE data_corr.data_corr_ret_mig_prod_status_bck
(
    id          integer,
    "productId" integer,
    status      text,
    screenshot  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    load_id     integer
);

ALTER TABLE data_corr.data_corr_ret_mig_prod_status_bck
    OWNER TO postgres;

