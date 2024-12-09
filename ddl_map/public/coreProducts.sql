CREATE TABLE "coreProducts"
(
    id                integer      DEFAULT NEXTVAL('"coreProducts_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    ean               varchar(255)
        UNIQUE,
    title             text,
    image             text,
    "secondaryImages" boolean,
    description       text,
    features          text,
    ingredients       text,
    "brandId"         integer
                                                                                      REFERENCES brands
                                                                                          ON DELETE SET NULL,
    "categoryId"      integer
        REFERENCES categories,
    "productGroupId"  integer
        REFERENCES "productGroups",
    "createdAt"       timestamp with time zone                                        NOT NULL,
    "updatedAt"       timestamp with time zone                                        NOT NULL,
    bundled           boolean      DEFAULT FALSE,
    disabled          boolean      DEFAULT FALSE                                      NOT NULL,
    "eanIssues"       boolean      DEFAULT FALSE                                      NOT NULL,
    specification     text,
    size              varchar(255) DEFAULT '0'::character varying,
    reviewed          boolean      DEFAULT FALSE                                      NOT NULL,
    "productOptions"  boolean      DEFAULT FALSE                                      NOT NULL,
    attributes        json,
    load_id           integer
);

ALTER TABLE "coreProducts"
    OWNER TO postgres;

CREATE INDEX "IND_CORE_PRODUCTS_BRAND_ID"
    ON "coreProducts" ("brandId");

CREATE INDEX "IND_CORE_PRODUCTS_CATEGORY_ID"
    ON "coreProducts" ("categoryId");

CREATE INDEX "IND_CORE_PRODUCTS_PRODUCT_GROUP_ID"
    ON "coreProducts" ("productGroupId");

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "coreProducts_pkey" TO postgres;

GRANT SELECT ON "coreProducts_pkey" TO bn_ro;

GRANT SELECT ON "coreProducts_pkey" TO bn_ro_role;

GRANT SELECT ON "coreProducts_pkey" TO bn_ro_user1;

GRANT SELECT ON "coreProducts_pkey" TO dejan_user;

GRANT SELECT ON "coreProducts" TO bn_ro;

GRANT SELECT ON "coreProducts" TO bn_ro_role;

GRANT SELECT ON "coreProducts" TO bn_ro_user1;

GRANT SELECT ON "coreProducts" TO dejan_user;

