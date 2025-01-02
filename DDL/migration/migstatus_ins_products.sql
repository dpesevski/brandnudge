CREATE TABLE MIGRATION.MIGSTATUS_INS_PRODUCTS
(
    ID                      bigint,
    "sourceType"            varchar(255),
    EAN                     varchar(255),
    PROMOTIONS              boolean,
    "promotionDescription"  text,
    FEATURES                text,
    DATE                    date,
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
    MULTIBUY                boolean,
    "coreProductId"         integer,
    "retailerId"            integer,
    "createdAt"             timestamp with time zone,
    "updatedAt"             timestamp with time zone,
    "imageId"               integer,
    SIZE                    varchar(255),
    "pricePerWeight"        varchar(255),
    HREF                    text,
    NUTRITIONAL             text,
    "basePrice"             varchar(255),
    "shelfPrice"            varchar(255),
    "productTitleDetail"    text,
    "sizeUnit"              varchar(255),
    "dateId"                integer,
    MARKETPLACE             boolean,
    "marketplaceData"       JSON,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean,
    LOAD_ID                 integer
);

ALTER TABLE MIGRATION.MIGSTATUS_INS_PRODUCTS
    OWNER TO POSTGRES;

GRANT SELECT ON MIGRATION.MIGSTATUS_INS_PRODUCTS TO BN_RO;

GRANT SELECT ON MIGRATION.MIGSTATUS_INS_PRODUCTS TO DEJAN_USER;

