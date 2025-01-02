CREATE TABLE STAGING.DEBUG_PRODUCTSDATA
(
    ID               integer NOT NULL,
    "productId"      integer,
    CATEGORY         varchar(255),
    "categoryType"   varchar(255),
    "parentCategory" varchar(255),
    "productRank"    integer,
    "pageNumber"     varchar(255),
    SCREENSHOT       varchar(255),
    FEATURED         boolean,
    "featuredRank"   integer,
    "taxonomyId"     integer,
    LOAD_ID          integer
);

ALTER TABLE STAGING.DEBUG_PRODUCTSDATA
    OWNER TO POSTGRES;

GRANT SELECT ON STAGING.DEBUG_PRODUCTSDATA TO BN_RO;

GRANT SELECT ON STAGING.DEBUG_PRODUCTSDATA TO DEJAN_USER;

