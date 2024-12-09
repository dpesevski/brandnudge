CREATE TABLE "bannersProducts"
(
    id               integer DEFAULT NEXTVAL('"bannersProducts_id_seq"'::regclass) NOT NULL
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
    OWNER TO postgres;

GRANT SELECT ON "bannersProducts" TO bn_ro;

GRANT SELECT ON "bannersProducts" TO bn_ro_role;

GRANT SELECT ON "bannersProducts" TO bn_ro_user1;

GRANT SELECT ON "bannersProducts" TO dejan_user;

