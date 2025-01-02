CREATE TABLE "coreRetailers"
(
    ID              serial
        PRIMARY KEY,
    "coreProductId" integer,
    "retailerId"    integer,
    "createdAt"     timestamp with time zone NOT NULL,
    "updatedAt"     timestamp with time zone NOT NULL,
    LOAD_ID         integer,
    CONSTRAINT CORERETAILERS_PK
        UNIQUE ("coreProductId", "retailerId"),
    CONSTRAINT CORERETAILERS_PK2
        UNIQUE (ID, "retailerId")
);

ALTER TABLE "coreRetailers"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreRetailers" TO BN_RO;

GRANT SELECT ON "coreRetailers" TO BN_RO_ROLE;

GRANT SELECT ON "coreRetailers" TO BN_RO_USER1;

GRANT SELECT ON "coreRetailers" TO DEJAN_USER;

