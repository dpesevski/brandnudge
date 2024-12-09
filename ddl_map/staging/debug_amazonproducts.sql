CREATE TABLE staging.debug_amazonproducts
(
    id            integer                  NOT NULL,
    "productId"   integer,
    shop          varchar(255)             NOT NULL,
    choice        varchar(255),
    "lowStock"    boolean,
    "sellParty"   varchar(255),
    sell          varchar(255),
    "fulfilParty" varchar(255),
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    load_id       integer
);

ALTER TABLE staging.debug_amazonproducts
    OWNER TO postgres;

GRANT SELECT ON staging.debug_amazonproducts TO bn_ro;

GRANT SELECT ON staging.debug_amazonproducts TO dejan_user;

