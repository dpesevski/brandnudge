CREATE TABLE "coreRetailerTaxonomies"
(
    ID                   serial
        PRIMARY KEY,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL,
    LOAD_ID              integer
);

ALTER TABLE "coreRetailerTaxonomies"
    OWNER TO POSTGRES;

CREATE INDEX "idxcoreRetailerTaxonomiescoreRetailerIdretailerTaxonomyId"
    ON "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId");

CREATE UNIQUE INDEX CORERETAILERTAXONOMIES_CORERETAILERID_RETAILERTAXONOMYID_UQ
    ON "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON "coreRetailerTaxonomies" TO BN_RO;

GRANT SELECT ON "coreRetailerTaxonomies" TO BN_RO_ROLE;

GRANT SELECT ON "coreRetailerTaxonomies" TO BN_RO_USER1;

GRANT SELECT ON "coreRetailerTaxonomies" TO DEJAN_USER;

