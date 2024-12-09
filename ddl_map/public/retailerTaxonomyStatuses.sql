CREATE TABLE "retailerTaxonomyStatuses"
(
    id                   serial
        PRIMARY KEY,
    "retailerTaxonomyId" integer,
    banners              boolean,
    products             boolean,
    subscription         boolean,
    "createdAt"          timestamp with time zone NOT NULL,
    "updatedAt"          timestamp with time zone NOT NULL
);

ALTER TABLE "retailerTaxonomyStatuses"
    OWNER TO postgres;

GRANT SELECT ON "retailerTaxonomyStatuses" TO bn_ro;

GRANT SELECT ON "retailerTaxonomyStatuses" TO bn_ro_role;

GRANT SELECT ON "retailerTaxonomyStatuses" TO bn_ro_user1;

GRANT SELECT ON "retailerTaxonomyStatuses" TO dejan_user;

