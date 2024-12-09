CREATE TABLE "productGroupCategories"
(
    id               serial
        PRIMARY KEY,
    "productGroupId" integer
        REFERENCES "productGroups",
    "categoryId"     integer
        REFERENCES categories,
    "createdAt"      timestamp with time zone NOT NULL,
    "updatedAt"      timestamp with time zone NOT NULL
);

ALTER TABLE "productGroupCategories"
    OWNER TO postgres;

CREATE UNIQUE INDEX "productGroupId_categoryId_unique"
    ON "productGroupCategories" ("productGroupId", "categoryId");

GRANT SELECT ON "productGroupCategories" TO bn_ro;

GRANT SELECT ON "productGroupCategories" TO bn_ro_role;

GRANT SELECT ON "productGroupCategories" TO bn_ro_user1;

GRANT SELECT ON "productGroupCategories" TO dejan_user;

