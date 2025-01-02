CREATE TABLE DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_AGGREGATEDPRODUCTS
(
    ID            integer,
    "titleMatch"  varchar(255),
    "productId"   integer,
    "createdAt"   timestamp with time zone,
    "updatedAt"   timestamp with time zone,
    FEATURES      varchar(255),
    SPECIFICATION varchar(255),
    SIZE          varchar(255),
    DESCRIPTION   varchar(255),
    INGREDIENTS   varchar(255),
    "imageMatch"  varchar(255),
    LOAD_ID       integer
);

ALTER TABLE DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_AGGREGATEDPRODUCTS
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_AGGREGATEDPRODUCTS TO BN_RO;

GRANT SELECT ON DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_AGGREGATEDPRODUCTS TO DEJAN_USER;

