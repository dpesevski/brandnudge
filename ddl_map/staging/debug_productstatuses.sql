CREATE TABLE staging.debug_productstatuses
(
    id          integer                  NOT NULL,
    "productId" integer,
    status      varchar(255)             NOT NULL,
    screenshot  varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    load_id     integer
);

ALTER TABLE staging.debug_productstatuses
    OWNER TO postgres;

GRANT SELECT ON staging.debug_productstatuses TO bn_ro;

GRANT SELECT ON staging.debug_productstatuses TO dejan_user;

