CREATE TABLE staging.debug_retailers
(
    id          integer                  NOT NULL,
    name        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    color       varchar(255)             NOT NULL,
    logo        varchar(255),
    "countryId" integer,
    load_id     integer
);

ALTER TABLE staging.debug_retailers
    OWNER TO postgres;

GRANT SELECT ON staging.debug_retailers TO bn_ro;

GRANT SELECT ON staging.debug_retailers TO dejan_user;

