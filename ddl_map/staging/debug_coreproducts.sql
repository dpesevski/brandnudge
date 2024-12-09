CREATE TABLE staging.debug_coreproducts
(
    id                integer                  NOT NULL,
    ean               varchar(255),
    title             text,
    image             text,
    "secondaryImages" boolean,
    description       text,
    features          text,
    ingredients       text,
    "brandId"         integer,
    "categoryId"      integer,
    "productGroupId"  integer,
    "createdAt"       timestamp with time zone NOT NULL,
    "updatedAt"       timestamp with time zone NOT NULL,
    bundled           boolean,
    disabled          boolean                  NOT NULL,
    "eanIssues"       boolean                  NOT NULL,
    specification     text,
    size              varchar(255),
    reviewed          boolean                  NOT NULL,
    "productOptions"  boolean                  NOT NULL,
    attributes        json,
    load_id           integer
);

ALTER TABLE staging.debug_coreproducts
    OWNER TO postgres;

GRANT SELECT ON staging.debug_coreproducts TO bn_ro;

GRANT SELECT ON staging.debug_coreproducts TO dejan_user;

