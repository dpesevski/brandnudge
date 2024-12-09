CREATE TABLE data_corr.ms2_data_corr_status_deleted_aggregatedproducts
(
    id            integer,
    "titleMatch"  varchar(255),
    "productId"   integer,
    "createdAt"   timestamp with time zone,
    "updatedAt"   timestamp with time zone,
    features      varchar(255),
    specification varchar(255),
    size          varchar(255),
    description   varchar(255),
    ingredients   varchar(255),
    "imageMatch"  varchar(255),
    load_id       integer
);

ALTER TABLE data_corr.ms2_data_corr_status_deleted_aggregatedproducts
    OWNER TO postgres;

GRANT SELECT ON data_corr.ms2_data_corr_status_deleted_aggregatedproducts TO bn_ro;

GRANT SELECT ON data_corr.ms2_data_corr_status_deleted_aggregatedproducts TO dejan_user;

