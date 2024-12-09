CREATE TABLE "retailerTaxonomies"
(
    id             serial
        PRIMARY KEY,
    "retailerId"   integer                                                                                        NOT NULL,
    "parentId"     integer,
    category       varchar(255)                                                                                   NOT NULL,
    "categoryType" "enum_retailerTaxonomies_categoryType" DEFAULT 'aisle'::"enum_retailerTaxonomies_categoryType" NOT NULL,
    url            text                                                                                           NOT NULL,
    level          integer                                DEFAULT 1                                               NOT NULL,
    position       integer                                DEFAULT 1                                               NOT NULL,
    archived       boolean                                DEFAULT FALSE                                           NOT NULL,
    "createdAt"    timestamp with time zone                                                                       NOT NULL,
    "updatedAt"    timestamp with time zone                                                                       NOT NULL
);

ALTER TABLE "retailerTaxonomies"
    OWNER TO postgres;

