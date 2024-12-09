CREATE TABLE "productsData"
(
    id               serial
        PRIMARY KEY,
    "productId"      integer
        REFERENCES products,
    category         varchar(255),
    "categoryType"   varchar(255),
    "parentCategory" varchar(255),
    "productRank"    integer,
    "pageNumber"     varchar(255),
    screenshot       varchar(255) DEFAULT ''::character varying,
    featured         boolean      DEFAULT FALSE,
    "featuredRank"   integer,
    "taxonomyId"     integer      DEFAULT 0,
    load_id          integer
);

ALTER TABLE "productsData"
    OWNER TO postgres;

CREATE INDEX "productsData_category_parentCategory_index"
    ON "productsData" (category, "parentCategory");

CREATE INDEX "productsData_productId_index"
    ON "productsData" ("productId");

CREATE INDEX productsdata_category_categorytype_featuredrank_productrank_ind
    ON "productsData" (category, "categoryType", "featuredRank", "productRank");

GRANT SELECT ON "productsData" TO bn_ro;

GRANT SELECT ON "productsData" TO bn_ro_role;

GRANT SELECT ON "productsData" TO bn_ro_user1;

GRANT SELECT ON "productsData" TO dejan_user;

