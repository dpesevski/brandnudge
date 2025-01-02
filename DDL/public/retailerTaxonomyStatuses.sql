CREATE TABLE "retailerTaxonomyStatuses"
(
    ID                   serial
        PRIMARY KEY,
    "retailerTaxonomyId" integer,
    BANNERS              boolean,
    PRODUCTS             boolean,
    SUBSCRIPTION         boolean,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL
);

ALTER TABLE "retailerTaxonomyStatuses"
    OWNER TO POSTGRES;

GRANT SELECT ON "retailerTaxonomyStatuses" TO BN_RO;

GRANT SELECT ON "retailerTaxonomyStatuses" TO BN_RO_ROLE;

GRANT SELECT ON "retailerTaxonomyStatuses" TO BN_RO_USER1;

GRANT SELECT ON "retailerTaxonomyStatuses" TO DEJAN_USER;

