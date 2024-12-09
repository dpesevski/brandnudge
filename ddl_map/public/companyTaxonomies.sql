CREATE TABLE "companyTaxonomies"
(
    id                   serial
        PRIMARY KEY,
    "companyId"          integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL
);

ALTER TABLE "companyTaxonomies"
    OWNER TO postgres;

GRANT SELECT ON "companyTaxonomies" TO bn_ro;

GRANT SELECT ON "companyTaxonomies" TO bn_ro_role;

GRANT SELECT ON "companyTaxonomies" TO bn_ro_user1;

GRANT SELECT ON "companyTaxonomies" TO dejan_user;

