CREATE TABLE "productGroupManufacturers"
(
    ID               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "manufacturerId" integer
        REFERENCES MANUFACTURERS,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupManufacturers"
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX "productGroupId_manufacturerId_unique"
    ON "productGroupManufacturers" ("productGroupId", "manufacturerId");

GRANT SELECT ON "productGroupManufacturers" TO BN_RO;

GRANT SELECT ON "productGroupManufacturers" TO BN_RO_ROLE;

GRANT SELECT ON "productGroupManufacturers" TO BN_RO_USER1;

GRANT SELECT ON "productGroupManufacturers" TO DEJAN_USER;

