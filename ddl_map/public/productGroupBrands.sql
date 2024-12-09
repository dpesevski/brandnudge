CREATE TABLE "productGroupBrands"
(
    id               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "brandId"        integer
        REFERENCES brands,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupBrands"
    OWNER TO postgres;

CREATE UNIQUE INDEX "productGroupId_brandId_unique"
    ON "productGroupBrands" ("productGroupId", "brandId");

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "productGroupBrands_brandId_fkey" TO postgres;

GRANT SELECT ON "productGroupBrands_brandId_fkey" TO bn_ro;

GRANT SELECT ON "productGroupBrands_brandId_fkey" TO bn_ro_role;

GRANT SELECT ON "productGroupBrands_brandId_fkey" TO bn_ro_user1;

GRANT SELECT ON "productGroupBrands_brandId_fkey" TO dejan_user;

GRANT SELECT ON "productGroupBrands" TO bn_ro;

GRANT SELECT ON "productGroupBrands" TO bn_ro_role;

GRANT SELECT ON "productGroupBrands" TO bn_ro_user1;

GRANT SELECT ON "productGroupBrands" TO dejan_user;

