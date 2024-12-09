CREATE TABLE staging.debug_coreretailerdates
(
    id               integer                  NOT NULL,
    "coreRetailerId" integer,
    "dateId"         integer,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL,
    load_id          integer
);

ALTER TABLE staging.debug_coreretailerdates
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreretailerdates TO bn_ro;

GRANT SELECT ON staging.debug_coreretailerdates TO dejan_user;

