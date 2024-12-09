CREATE TABLE "coreRetailerTaxonomies"
(
    id                   serial
        PRIMARY KEY,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL,
    load_id              integer
);

ALTER TABLE "coreRetailerTaxonomies"
    OWNER TO postgres;

CREATE INDEX "idxcoreRetailerTaxonomiescoreRetailerIdretailerTaxonomyId"
    ON "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId");

CREATE UNIQUE INDEX coreretailertaxonomies_coreretailerid_retailertaxonomyid_uq
    ON "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

GRANT SELECT ON "coreRetailerTaxonomies" TO bn_ro;

GRANT SELECT ON "coreRetailerTaxonomies" TO bn_ro_role;

GRANT SELECT ON "coreRetailerTaxonomies" TO bn_ro_user1;

GRANT SELECT ON "coreRetailerTaxonomies" TO dejan_user;

