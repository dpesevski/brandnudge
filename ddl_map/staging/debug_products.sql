CREATE TABLE staging.debug_products
(
    id                      integer                  NOT NULL,
    "sourceType"            varchar(255),
    ean                     varchar(255),
    promotions              boolean,
    "promotionDescription"  text,
    features                text,
    date                    timestamp with time zone NOT NULL,
    "sourceId"              varchar(255),
    "productBrand"          varchar(255),
    "productTitle"          text,
    "productImage"          text,
    "secondaryImages"       boolean,
    "productDescription"    text,
    "productInfo"           text,
    "promotedPrice"         varchar(255),
    "productInStock"        boolean,
    "productInListing"      boolean,
    "reviewsCount"          varchar(255),
    "reviewsStars"          varchar(255),
    "eposId"                varchar(255),
    multibuy                boolean,
    "coreProductId"         integer                  NOT NULL,
    "retailerId"            integer,
    "createdAt"             timestamp with time zone NOT NULL,
    "updatedAt"             timestamp with time zone NOT NULL,
    "imageId"               integer,
    size                    varchar(255),
    "pricePerWeight"        varchar(255),
    href                    text,
    nutritional             text,
    "basePrice"             varchar(255),
    "shelfPrice"            varchar(255),
    "productTitleDetail"    text,
    "sizeUnit"              varchar(255),
    "dateId"                integer,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean,
    load_id                 integer
);

ALTER TABLE staging.debug_products
    OWNER TO postgres;

GRANT SELECT ON staging.debug_products TO bn_ro;

GRANT SELECT ON staging.debug_products TO dejan_user;

