CREATE TABLE "productsData"
(
    ID               serial
        PRIMARY KEY,
    "productId"      integer
        REFERENCES PRODUCTS,
    CATEGORY         varchar(255),
    "categoryType"   varchar(255),
    "parentCategory" varchar(255),
    "productRank"    integer,
    "pageNumber"     varchar(255),
    SCREENSHOT       varchar(255) DEFAULT ''::character varying,
    FEATURED         boolean      DEFAULT FALSE,
    "featuredRank"   integer,
    "taxonomyId"     integer      DEFAULT 0,
    LOAD_ID          integer
);

ALTER TABLE "productsData"
    OWNER TO POSTGRES;

CREATE INDEX "productsData_category_parentCategory_index"
    ON "productsData" (CATEGORY, "parentCategory");

CREATE INDEX "productsData_productId_index"
    ON "productsData" ("productId");

CREATE INDEX PRODUCTSDATA_CATEGORY_CATEGORYTYPE_FEATUREDRANK_PRODUCTRANK_IND
    ON "productsData" (CATEGORY, "categoryType", "featuredRank", "productRank");

GRANT SELECT ON "productsData" TO BN_RO;

GRANT SELECT ON "productsData" TO BN_RO_ROLE;

GRANT SELECT ON "productsData" TO BN_RO_USER1;

GRANT SELECT ON "productsData" TO DEJAN_USER;

