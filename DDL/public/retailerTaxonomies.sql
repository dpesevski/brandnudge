CREATE TABLE "retailerTaxonomies"
(
    ID             serial
        PRIMARY KEY,
    "retailerId"   integer                                                                                        NOT NULL,
    "parentId"     integer,
    CATEGORY       varchar(255)                                                                                   NOT NULL,
    "categoryType" "enum_retailerTaxonomies_categoryType" DEFAULT 'aisle'::"enum_retailerTaxonomies_categoryType" NOT NULL,
    URL            text                                                                                           NOT NULL,
    LEVEL          integer                                DEFAULT 1                                               NOT NULL,
    POSITION       integer                                DEFAULT 1                                               NOT NULL,
    ARCHIVED       boolean                                DEFAULT FALSE                                           NOT NULL,
    "createdAt"    timestamp with time zone                                                                       NOT NULL,
    "updatedAt"    timestamp with time zone                                                                       NOT NULL
);

ALTER TABLE "retailerTaxonomies"
    OWNER TO POSTGRES;

GRANT SELECT ON "retailerTaxonomies" TO BN_RO;

GRANT SELECT ON "retailerTaxonomies" TO BN_RO_ROLE;

GRANT SELECT ON "retailerTaxonomies" TO BN_RO_USER1;

GRANT SELECT ON "retailerTaxonomies" TO DEJAN_USER;

