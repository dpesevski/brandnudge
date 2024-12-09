CREATE TABLE staging.product_status_history
(
    "retailerId"    integer NOT NULL,
    "coreProductId" integer NOT NULL,
    date            date    NOT NULL,
    "productId"     integer
        CONSTRAINT product_status_history_productid_uindex
            UNIQUE,
    status          text,
    CONSTRAINT product_status_history_pk
        PRIMARY KEY ("retailerId", "coreProductId", date)
);

ALTER TABLE staging.product_status_history
    OWNER TO postgres;

GRANT SELECT ON staging.product_status_history TO bn_ro;

GRANT SELECT ON staging.product_status_history TO dejan_user;

