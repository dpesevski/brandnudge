CREATE TABLE staging.debug_aggregatedproducts
(
    id            integer                  NOT NULL,
    "titleMatch"  varchar(255),
    "productId"   integer,
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    features      varchar(255),
    specification varchar(255),
    size          varchar(255),
    description   varchar(255),
    ingredients   varchar(255),
    "imageMatch"  varchar(255),
    load_id       integer
);

ALTER TABLE staging.debug_aggregatedproducts
    OWNER TO postgres;

GRANT SELECT ON staging.debug_aggregatedproducts TO bn_ro;

GRANT SELECT ON staging.debug_aggregatedproducts TO dejan_user;

