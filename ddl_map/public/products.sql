CREATE TABLE products
(
    id                      integer      DEFAULT NEXTVAL('products_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    "sourceType"            varchar(255),
    ean                     varchar(255),
    promotions              boolean,
    "promotionDescription"  text,
    features                text,
    date                    timestamp with time zone                                  NOT NULL,
    "sourceId"              varchar(255),
    "productBrand"          varchar(255),
    "productTitle"          text,
    "productImage"          text,
    "secondaryImages"       boolean      DEFAULT FALSE,
    "productDescription"    text,
    "productInfo"           text,
    "promotedPrice"         varchar(255),
    "productInStock"        boolean      DEFAULT TRUE,
    "productInListing"      boolean      DEFAULT FALSE,
    "reviewsCount"          varchar(255),
    "reviewsStars"          varchar(255),
    "eposId"                varchar(255),
    multibuy                boolean      DEFAULT FALSE,
    "coreProductId"         integer                                                   NOT NULL
        REFERENCES "coreProducts",
    "retailerId"            integer
        REFERENCES retailers,
    "createdAt"             timestamp with time zone                                  NOT NULL,
    "updatedAt"             timestamp with time zone                                  NOT NULL,
    "imageId"               integer
        CONSTRAINT products_image_fkey
            REFERENCES images,
    size                    varchar(255) DEFAULT NULL::character varying,
    "pricePerWeight"        varchar(255) DEFAULT NULL::character varying,
    href                    text,
    nutritional             text         DEFAULT NULL::character varying,
    "basePrice"             varchar(255),
    "shelfPrice"            varchar(255),
    "productTitleDetail"    text,
    "sizeUnit"              varchar(255),
    "dateId"                integer
        CONSTRAINT products_dates_id_fk
            REFERENCES dates,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean      DEFAULT FALSE,
    "isNpd"                 boolean      DEFAULT FALSE,
    load_id                 integer
);

ALTER TABLE products
    OWNER TO postgres;

CREATE INDEX "IND_PRODUCTS_IMAGE_ID"
    ON products ("imageId");

CREATE INDEX products__index_source_id
    ON products ("sourceId");

CREATE INDEX products_coreproductid_index
    ON products ("coreProductId");

CREATE INDEX products_dateid_coreproductid_retailerid_index
    ON products ("dateId", "coreProductId", "retailerId");

CREATE INDEX products_dateid_index
    ON products ("dateId");

CREATE INDEX "products_ean_date_sourceType_index"
    ON products (ean, date, "sourceType", "coreProductId");

CREATE UNIQUE INDEX products_sourceid_retailerid_dateid_key
    ON products ("sourceId", "retailerId", "dateId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

CREATE INDEX products_retailerid_coreproductid_date_index
    ON products ("retailerId", "coreProductId", date);

CREATE INDEX products_retailerid_index
    ON products ("retailerId");

GRANT SELECT ON products TO bn_ro;

GRANT SELECT ON products TO bn_ro_role;

GRANT SELECT ON products TO bn_ro_user1;

GRANT SELECT ON products TO dejan_user;

