CREATE TABLE "taxonomyProducts"
(
    ID              integer DEFAULT NEXTVAL('"taxonomyProducts_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    RETAILER        varchar(255),
    "sourceId"      varchar(255),
    "taxonomyId"    integer                                                        NOT NULL
        REFERENCES TAXONOMIES,
    DATE            timestamp with time zone                                       NOT NULL,
    "coreProductId" integer                                                        NOT NULL
        REFERENCES "coreProducts",
    "createdAt"     timestamp with time zone                                       NOT NULL,
    "updatedAt"     timestamp with time zone                                       NOT NULL
);

ALTER TABLE "taxonomyProducts"
    OWNER TO POSTGRES;

GRANT SELECT ON "taxonomyProducts" TO BN_RO;

GRANT SELECT ON "taxonomyProducts" TO BN_RO_ROLE;

GRANT SELECT ON "taxonomyProducts" TO BN_RO_USER1;

GRANT SELECT ON "taxonomyProducts" TO DEJAN_USER;

