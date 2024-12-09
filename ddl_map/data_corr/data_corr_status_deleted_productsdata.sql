CREATE TABLE data_corr.data_corr_status_deleted_productsdata
(
    id               integer,
    "productId"      integer,
    category         varchar(255),
    "categoryType"   varchar(255),
    "parentCategory" varchar(255),
    "productRank"    integer,
    "pageNumber"     varchar(255),
    screenshot       varchar(255),
    featured         boolean,
    "featuredRank"   integer,
    "taxonomyId"     integer,
    load_id          integer
);

ALTER TABLE data_corr.data_corr_status_deleted_productsdata
    OWNER TO postgres;

GRANT SELECT ON data_corr.data_corr_status_deleted_productsdata TO bn_ro;

GRANT SELECT ON data_corr.data_corr_status_deleted_productsdata TO dejan_user;

