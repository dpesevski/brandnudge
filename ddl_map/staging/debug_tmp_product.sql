CREATE TABLE staging.debug_tmp_product
(
    load_id                 integer,
    id                      integer,
    "coreProductId"         integer,
    promotions              staging.t_promotion[],
    "productPrice"          double precision,
    "originalPrice"         double precision,
    "basePrice"             double precision,
    "shelfPrice"            double precision,
    "promotedPrice"         double precision,
    "retailerId"            integer,
    "dateId"                integer,
    featured                boolean,
    bundled                 boolean,
    date                    date,
    ean                     text,
    "eposId"                text,
    features                text,
    href                    text,
    "inTaxonomy"            boolean,
    "isFeatured"            boolean,
    multibuy                boolean,
    nutritional             text,
    "pricePerWeight"        text,
    "productBrand"          text,
    "productDescription"    text,
    "productImage"          text,
    "newCoreImage"          text,
    "productInStock"        boolean,
    "productInfo"           text,
    "productTitle"          text,
    "productTitleDetail"    text,
    "reviewsCount"          integer,
    "reviewsStars"          double precision,
    "secondaryImages"       boolean,
    size                    text,
    "sizeUnit"              text,
    "sourceId"              text,
    "sourceType"            text,
    "brandId"               integer,
    "productOptions"        boolean,
    "eanIssues"             boolean,
    shop                    text,
    "amazonShop"            text,
    choice                  text,
    "amazonChoice"          text,
    "lowStock"              boolean,
    "sellParty"             text,
    "amazonSellParty"       text,
    "amazonSell"            text,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean,
    sell                    text,
    "fulfilParty"           text,
    "amazonFulfilParty"     text,
    status                  text,
    screenshot              text,
    ranking_data            "productsData"[]
);

ALTER TABLE staging.debug_tmp_product
    OWNER TO postgres;

GRANT SELECT ON staging.debug_tmp_product TO bn_ro;

GRANT SELECT ON staging.debug_tmp_product TO dejan_user;

