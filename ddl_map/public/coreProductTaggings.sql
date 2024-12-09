CREATE TABLE "coreProductTaggings"
(
    id              integer DEFAULT NEXTVAL('"coreProductTaggings_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    "coreProductId" integer,
    "coreTaggingId" integer,
    "createdAt"     timestamp with time zone                                          NOT NULL,
    "updatedAt"     timestamp with time zone                                          NOT NULL
);

ALTER TABLE "coreProductTaggings"
    OWNER TO postgres;

GRANT SELECT ON "coreProductTaggings" TO bn_ro;

GRANT SELECT ON "coreProductTaggings" TO bn_ro_role;

GRANT SELECT ON "coreProductTaggings" TO bn_ro_user1;

GRANT SELECT ON "coreProductTaggings" TO dejan_user;

