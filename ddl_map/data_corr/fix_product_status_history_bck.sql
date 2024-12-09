CREATE TABLE data_corr.fix_product_status_history_bck
(
    "retailerId"    integer,
    "coreProductId" integer,
    date            date,
    "productId"     integer,
    status          text
);

ALTER TABLE data_corr.fix_product_status_history_bck
    OWNER TO postgres;

GRANT SELECT ON data_corr.fix_product_status_history_bck TO bn_ro;

GRANT SELECT ON data_corr.fix_product_status_history_bck TO dejan_user;

