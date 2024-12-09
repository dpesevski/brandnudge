CREATE TABLE data_corr.fix_product_status_history_coreproducts
(
    "productId"          integer,
    date                 timestamp with time zone,
    "dateId"             integer,
    load_id              integer,
    latest_coreproductid integer
);

ALTER TABLE data_corr.fix_product_status_history_coreproducts
    OWNER TO postgres;

GRANT SELECT ON data_corr.fix_product_status_history_coreproducts TO bn_ro;

GRANT SELECT ON data_corr.fix_product_status_history_coreproducts TO dejan_user;

