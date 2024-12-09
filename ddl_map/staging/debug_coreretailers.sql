CREATE TABLE staging.debug_coreretailers
(
    "sourceId"      text,
    id              integer                  NOT NULL,
    "coreProductId" integer,
    "retailerId"    integer,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    load_id         integer
);

ALTER TABLE staging.debug_coreretailers
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreretailers TO bn_ro;

GRANT SELECT ON staging.debug_coreretailers TO dejan_user;

