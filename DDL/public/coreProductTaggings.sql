CREATE TABLE "coreProductTaggings"
(
    ID              integer DEFAULT NEXTVAL('"coreProductTaggings_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    "coreProductId" integer,
    "coreTaggingId" integer,
    "createdAt"     timestamp with time zone                                          NOT NULL,
    "updatedAt"     timestamp with time zone                                          NOT NULL
);

ALTER TABLE "coreProductTaggings"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreProductTaggings" TO BN_RO;

GRANT SELECT ON "coreProductTaggings" TO BN_RO_ROLE;

GRANT SELECT ON "coreProductTaggings" TO BN_RO_USER1;

GRANT SELECT ON "coreProductTaggings" TO DEJAN_USER;

