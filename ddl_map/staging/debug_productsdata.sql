CREATE TABLE staging.debug_productsdata
(
    id               integer NOT NULL,
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

ALTER TABLE staging.debug_productsdata
    OWNER TO postgres;

GRANT SELECT ON staging.debug_productsdata TO bn_ro;

GRANT SELECT ON staging.debug_productsdata TO dejan_user;

