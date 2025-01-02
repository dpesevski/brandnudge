CREATE TABLE "amazonProducts"
(
    ID            serial
        PRIMARY KEY,
    "productId"   integer,
    SHOP          varchar(255)             NOT NULL,
    CHOICE        varchar(255),
    "lowStock"    boolean DEFAULT FALSE,
    "sellParty"   varchar(255),
    SELL          varchar(255),
    "fulfilParty" varchar(255),
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    LOAD_ID       integer
);

ALTER TABLE "amazonProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON "amazonProducts" TO BN_RO;

GRANT SELECT ON "amazonProducts" TO BN_RO_ROLE;

GRANT SELECT ON "amazonProducts" TO BN_RO_USER1;

GRANT SELECT ON "amazonProducts" TO DEJAN_USER;

