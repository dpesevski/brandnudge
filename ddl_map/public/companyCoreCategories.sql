CREATE TABLE "companyCoreCategories"
(
    id           serial
        PRIMARY KEY,
    "companyId"  integer,
    "categoryId" integer,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "companyCoreCategories"
    OWNER TO postgres;

GRANT SELECT ON "companyCoreCategories" TO bn_ro;

GRANT SELECT ON "companyCoreCategories" TO bn_ro_role;

GRANT SELECT ON "companyCoreCategories" TO bn_ro_user1;

GRANT SELECT ON "companyCoreCategories" TO dejan_user;

