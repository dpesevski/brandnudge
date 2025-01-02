CREATE TABLE STAGING.DEBUG_AMAZONPRODUCTS
(
    ID            integer                  NOT NULL,
    "productId"   integer,
    SHOP          varchar(255)             NOT NULL,
    CHOICE        varchar(255),
    "lowStock"    boolean,
    "sellParty"   varchar(255),
    SELL          varchar(255),
    "fulfilParty" varchar(255),
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    LOAD_ID       integer
);

ALTER TABLE STAGING.DEBUG_AMAZONPRODUCTS
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_AMAZONPRODUCTS TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_AMAZONPRODUCTS TO DEJAN_USER;

