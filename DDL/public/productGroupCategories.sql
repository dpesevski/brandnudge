CREATE TABLE "productGroupCategories"
(
    ID               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "categoryId"     integer
        REFERENCES CATEGORIES,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupCategories"
    OWNER TO POSTGRES;

CREATE UNIQUE INDEX "productGroupId_categoryId_unique"
    ON "productGroupCategories" ("productGroupId", "categoryId");

GRANT SELECT ON "productGroupCategories" TO BN_RO;

GRANT SELECT ON "productGroupCategories" TO BN_RO_ROLE;

GRANT SELECT ON "productGroupCategories" TO BN_RO_USER1;

GRANT SELECT ON "productGroupCategories" TO DEJAN_USER;

