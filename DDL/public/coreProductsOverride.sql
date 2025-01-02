CREATE TABLE "coreProductsOverride"
(
    ID              serial
        PRIMARY KEY,
    "coreProductId" integer
        REFERENCES "coreProducts",
    "retailerId"    integer
        REFERENCES RETAILERS,
    "sourceId"      varchar(255)                           NOT NULL,
    "createdAt"     timestamp with time zone DEFAULT NOW() NOT NULL,
    "updatedAt"     timestamp with time zone DEFAULT NOW() NOT NULL,
    CONSTRAINT "coreProductId_retailerId_sourceId_constraint"
        UNIQUE ("coreProductId", "retailerId", "sourceId")
);

ALTER TABLE "coreProductsOverride"
    OWNER TO POSTGRES;

CREATE INDEX "coreProductsOverride_coreProductId_retailerId_sourceId_index"
    ON "coreProductsOverride" ("coreProductId", "retailerId", "sourceId");

GRANT SELECT ON "coreProductsOverride" TO BN_RO;

GRANT SELECT ON "coreProductsOverride" TO DEJAN_USER;

