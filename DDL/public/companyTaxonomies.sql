CREATE TABLE "companyTaxonomies"
(
    ID                   serial
        PRIMARY KEY,
    "companyId"          integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL
);

ALTER TABLE "companyTaxonomies"
    OWNER TO POSTGRES;

GRANT SELECT ON "companyTaxonomies" TO BN_RO;

GRANT SELECT ON "companyTaxonomies" TO BN_RO_ROLE;

GRANT SELECT ON "companyTaxonomies" TO BN_RO_USER1;

GRANT SELECT ON "companyTaxonomies" TO DEJAN_USER;

