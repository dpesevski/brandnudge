CREATE TABLE STAGING.DEBUG_AGGREGATEDPRODUCTS
(
    ID            integer                  NOT NULL,
    "titleMatch"  varchar(255),
    "productId"   integer,
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    FEATURES      varchar(255),
    SPECIFICATION varchar(255),
    SIZE          varchar(255),
    DESCRIPTION   varchar(255),
    INGREDIENTS   varchar(255),
    "imageMatch"  varchar(255),
    LOAD_ID       integer
);

ALTER TABLE STAGING.DEBUG_AGGREGATEDPRODUCTS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_AGGREGATEDPRODUCTS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_AGGREGATEDPRODUCTS TO DEJAN_USER;

