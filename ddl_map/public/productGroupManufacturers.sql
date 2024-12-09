CREATE TABLE "productGroupManufacturers"
(
    id               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "manufacturerId" integer
        REFERENCES manufacturers,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupManufacturers"
    OWNER TO postgres;

CREATE UNIQUE INDEX "productGroupId_manufacturerId_unique"
    ON "productGroupManufacturers" ("productGroupId", "manufacturerId");

GRANT SELECT ON "productGroupManufacturers" TO bn_ro;

GRANT SELECT ON "productGroupManufacturers" TO bn_ro_role;

GRANT SELECT ON "productGroupManufacturers" TO bn_ro_user1;

GRANT SELECT ON "productGroupManufacturers" TO dejan_user;

