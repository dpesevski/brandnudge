CREATE TABLE "companyCoreCategories"
(
    ID           serial
        PRIMARY KEY,
    "companyId"  integer,
    "categoryId" integer,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "companyCoreCategories"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyCoreCategories" TO BN_RO;

GRANT SELECT ON "companyCoreCategories" TO BN_RO_ROLE;

GRANT SELECT ON "companyCoreCategories" TO BN_RO_USER1;

GRANT SELECT ON "companyCoreCategories" TO DEJAN_USER;

