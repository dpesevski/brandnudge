CREATE TABLE DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_PRODUCTSDATA
(
    ID               integer,
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

ALTER TABLE DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_PRODUCTSDATA
    OWNER TO POSTGRES;

GRANT SELECT ON DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_PRODUCTSDATA TO BN_RO;

GRANT SELECT ON DATA_CORR.MS2_DATA_CORR_STATUS_DELETED_PRODUCTSDATA TO DEJAN_USER;

