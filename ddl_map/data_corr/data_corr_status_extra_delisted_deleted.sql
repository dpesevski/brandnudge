CREATE TABLE data_corr.data_corr_status_extra_delisted_deleted
(
    id          integer,
    "productId" integer,
    status      varchar(255),
    screenshot  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    load_id     integer
);

ALTER TABLE data_corr.data_corr_status_extra_delisted_deleted
    OWNER TO postgres;

GRANT SELECT ON data_corr.data_corr_status_extra_delisted_deleted TO bn_ro;

GRANT SELECT ON data_corr.data_corr_status_extra_delisted_deleted TO dejan_user;

