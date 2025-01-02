CREATE TABLE "coreProducts"
(
    ID                integer      DEFAULT NEXTVAL('"coreProducts_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    EAN               varchar(255)
        UNIQUE,
    TITLE             text,
    IMAGE             text,
    "secondaryImages" boolean,
    DESCRIPTION       text,
    FEATURES          text,
    INGREDIENTS       text,
    "brandId"         integer
                                                                                      REFERENCES BRANDS
                                                                                          ON DELETE SET NULL,
    "categoryId"      integer
        REFERENCES CATEGORIES,
    "productGroupId"  integer
        REFERENCES "productGroups",
    "createdAt"       timestamp with time zone                                        NOT NULL,
    "updatedAt"       timestamp with time zone                                        NOT NULL,
    BUNDLED           boolean      DEFAULT FALSE,
    DISABLED          boolean      DEFAULT FALSE                                      NOT NULL,
    "eanIssues"       boolean      DEFAULT FALSE                                      NOT NULL,
    SPECIFICATION     text,
    SIZE              varchar(255) DEFAULT '0'::character varying,
    REVIEWED          boolean      DEFAULT FALSE                                      NOT NULL,
    "productOptions"  boolean      DEFAULT FALSE                                      NOT NULL,
    ATTRIBUTES        JSON,
    LOAD_ID           integer
);

ALTER TABLE "coreProducts"
    OWNER TO POSTGRES;

CREATE INDEX "IND_CORE_PRODUCTS_BRAND_ID"
    ON "coreProducts" ("brandId");

CREATE INDEX "IND_CORE_PRODUCTS_CATEGORY_ID"
    ON "coreProducts" ("categoryId");

CREATE INDEX "IND_CORE_PRODUCTS_PRODUCT_GROUP_ID"
    ON "coreProducts" ("productGroupId");

GRANT SELECT ON "coreProducts" TO BN_RO;

GRANT SELECT ON "coreProducts" TO BN_RO_ROLE;

GRANT SELECT ON "coreProducts" TO BN_RO_USER1;

GRANT SELECT ON "coreProducts" TO DEJAN_USER;

