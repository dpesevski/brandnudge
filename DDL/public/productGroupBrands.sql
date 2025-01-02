CREATE TABLE "productGroupBrands"
(
    ID               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "brandId"        integer
        REFERENCES BRANDS,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupBrands"
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX "productGroupId_brandId_unique"
    ON "productGroupBrands" ("productGroupId", "brandId");

GRANT SELECT ON "productGroupBrands" TO BN_RO;

GRANT SELECT ON "productGroupBrands" TO BN_RO_ROLE;

GRANT SELECT ON "productGroupBrands" TO BN_RO_USER1;

GRANT SELECT ON "productGroupBrands" TO DEJAN_USER;

