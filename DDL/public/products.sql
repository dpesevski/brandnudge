CREATE TABLE PRODUCTS
(
    ID                      integer      DEFAULT NEXTVAL('products_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    "sourceType"            varchar(255),
    EAN                     varchar(255),
    PROMOTIONS              boolean,
    "promotionDescription"  text,
    FEATURES                text,
    DATE                    timestamp with time zone                                  NOT NULL,
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
    MULTIBUY                boolean      DEFAULT FALSE,
    "coreProductId"         integer                                                   NOT NULL
        REFERENCES "coreProducts",
    "retailerId"            integer
        REFERENCES RETAILERS,
    "createdAt"             timestamp with time zone                                  NOT NULL,
    "updatedAt"             timestamp with time zone                                  NOT NULL,
    "imageId"               integer
        CONSTRAINT PRODUCTS_IMAGE_FKEY
            REFERENCES IMAGES,
    SIZE                    varchar(255) DEFAULT NULL::character varying,
    "pricePerWeight"        varchar(255) DEFAULT NULL::character varying,
    HREF                    text,
    NUTRITIONAL             text         DEFAULT NULL::character varying,
    "basePrice"             varchar(255),
    "shelfPrice"            varchar(255),
    "productTitleDetail"    text,
    "sizeUnit"              varchar(255),
    "dateId"                integer
        CONSTRAINT PRODUCTS_DATES_ID_FK
            REFERENCES DATES,
    MARKETPLACE             boolean,
    "marketplaceData"       JSON,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean      DEFAULT FALSE,
    "isNpd"                 boolean      DEFAULT FALSE,
    LOAD_ID                 integer
);

ALTER TABLE PRODUCTS
    OWNER TO POSTGRES;

CREATE INDEX "IND_PRODUCTS_IMAGE_ID"
    ON PRODUCTS ("imageId");

CREATE INDEX PRODUCTS__INDEX_SOURCE_ID
    ON PRODUCTS ("sourceId");

CREATE INDEX PRODUCTS_COREPRODUCTID_INDEX
    ON PRODUCTS ("coreProductId");

CREATE INDEX PRODUCTS_DATEID_COREPRODUCTID_RETAILERID_INDEX
    ON PRODUCTS ("dateId", "coreProductId", "retailerId");

CREATE INDEX PRODUCTS_DATEID_INDEX
    ON PRODUCTS ("dateId");

CREATE INDEX "products_ean_date_sourceType_index"
    ON PRODUCTS (EAN, DATE, "sourceType", "coreProductId");

CREATE UNIQUE INDEX PRODUCTS_SOURCEID_RETAILERID_DATEID_KEY
    ON PRODUCTS ("sourceId", "retailerId", "dateId")
    WHERE ("createdAt" >= '2024-05-31 20:21:46.840963+00'::timestamp with time zone);

CREATE INDEX PRODUCTS_RETAILERID_COREPRODUCTID_DATE_INDEX
    ON PRODUCTS ("retailerId", "coreProductId", DATE);

CREATE INDEX PRODUCTS_RETAILERID_INDEX
    ON PRODUCTS ("retailerId");

GRANT SELECT ON PRODUCTS TO BN_RO;

GRANT SELECT ON PRODUCTS TO BN_RO_ROLE;

GRANT SELECT ON PRODUCTS TO BN_RO_USER1;

GRANT SELECT ON PRODUCTS TO DEJAN_USER;

