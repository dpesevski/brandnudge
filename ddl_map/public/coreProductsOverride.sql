CREATE TABLE "coreProductsOverride"
(
    id              serial
        PRIMARY KEY,
    "coreProductId" integer
        REFERENCES "coreProducts",
    "retailerId"    integer
        REFERENCES retailers,
    "sourceId"      varchar(255)                           NOT NULL,
    "createdAt"     timestamp with time zone DEFAULT NOW() NOT NULL,
    "updatedAt"     timestamp with time zone DEFAULT NOW() NOT NULL,
    CONSTRAINT "coreProductId_retailerId_sourceId_constraint"
        UNIQUE ("coreProductId", "retailerId", "sourceId")
);

ALTER TABLE "coreProductsOverride"
    OWNER TO postgres;

CREATE INDEX "coreProductsOverride_coreProductId_retailerId_sourceId_index"
    ON "coreProductsOverride" ("coreProductId", "retailerId", "sourceId");

GRANT SELECT ON "coreProductsOverride" TO bn_ro;

GRANT SELECT ON "coreProductsOverride" TO dejan_user;

