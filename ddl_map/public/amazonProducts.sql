CREATE TABLE "amazonProducts"
(
    id            serial
        PRIMARY KEY,
    "productId"   integer,
    shop          varchar(255)             NOT NULL,
    choice        varchar(255),
    "lowStock"    boolean DEFAULT FALSE,
    "sellParty"   varchar(255),
    sell          varchar(255),
    "fulfilParty" varchar(255),
    "createdAt"   timestamp with time zone NOT NULL,
    "updatedAt"   timestamp with time zone NOT NULL,
    load_id       integer
);

ALTER TABLE "amazonProducts"
    OWNER TO postgres;

GRANT SELECT ON "amazonProducts" TO bn_ro;

GRANT SELECT ON "amazonProducts" TO bn_ro_role;

GRANT SELECT ON "amazonProducts" TO bn_ro_user1;

GRANT SELECT ON "amazonProducts" TO dejan_user;

