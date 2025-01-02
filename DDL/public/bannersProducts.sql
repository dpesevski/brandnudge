CREATE TABLE "bannersProducts"
(
    ID               integer DEFAULT NEXTVAL('"bannersProducts_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    "productId"      integer,
    "bannerId"       integer,
    "createdAt"      timestamp with time zone                                      NOT NULL,
    "updatedAt"      timestamp with time zone                                      NOT NULL,
    "coreRetailerId" integer
        REFERENCES "coreRetailers"
            DEFERRABLE
);

ALTER TABLE "bannersProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON "bannersProducts" TO BN_RO;

GRANT SELECT ON "bannersProducts" TO BN_RO_ROLE;

GRANT SELECT ON "bannersProducts" TO BN_RO_USER1;

GRANT SELECT ON "bannersProducts" TO DEJAN_USER;

