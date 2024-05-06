DROP TYPE IF EXISTS staging.t_promotion_mb CASCADE;
CREATE TYPE staging.t_promotion_mb AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    description           text,
    mechanic              text,
    "multibuyPrice"       float
);

DROP TABLE IF EXISTS staging.debug_test_run;
CREATE TABLE IF NOT EXISTS staging.debug_test_run
(
    id                    serial,
    data                  json,
    flag                  text,
    run_at                timestamp DEFAULT NOW(),
    dd_date               date,
    dd_retailer           retailers,
    dd_date_id            integer,
    dd_source_type        text,
    dd_sourceCategoryType text
);

DROP TABLE IF EXISTS staging.debug_tmp_product_pp;
CREATE TABLE staging.debug_tmp_product_pp
(
    test_run_id            integer,
    id                     integer,
    "sourceType"           varchar(255),
    ean                    text,
    "promotionDescription" text,
    features               text,
    date                   date,
    "sourceId"             text,
    "productBrand"         text,
    "productTitle"         text,
    "productImage"         text,
    "secondaryImages"      boolean,
    "productDescription"   text,
    "productInfo"          text,
    "promotedPrice"        double precision,
    "productInStock"       boolean,
    "productInListing"     boolean,
    "reviewsCount"         integer,
    "reviewsStars"         double precision,
    "eposId"               text,
    multibuy               boolean,
    "coreProductId"        integer,
    "retailerId"           integer,
    "createdAt"            timestamp WITH TIME ZONE,
    "updatedAt"            timestamp WITH TIME ZONE,
    "imageId"              text,
    size                   text,
    "pricePerWeight"       text,
    href                   text,
    nutritional            text,
    "basePrice"            double precision,
    "shelfPrice"           double precision,
    "productTitleDetail"   text,
    "sizeUnit"             text,
    "dateId"               integer,
    "countryCode"          text,
    currency               text,
    "cardPrice"            double precision,
    "onPromo"              boolean,
    bundled                boolean,
    "originalPrice"        double precision,
    "productPrice"         double precision,
    status                 text,
    "productOptions"       boolean,
    shop                   text,
    "amazonShop"           text,
    choice                 text,
    "amazonChoice"         text,
    "lowStock"             boolean,
    "sellParty"            text,
    "amazonSellParty"      text,
    sell                   text,
    "fulfilParty"          text,
    "amazonFulfilParty"    text,
    "amazonSell"           text,
    "eanIssues"            boolean,
    screenshot             text,
    "brandId"              integer,
    dd_ranking             "productsData",
    "EANs"                 text[],
    promotions             staging.t_promotion_mb[]
);

DROP TABLE IF EXISTS staging.debug_amazonProducts;
CREATE TABLE IF NOT EXISTS staging.debug_amazonProducts
(
    test_run_id   integer,
    id            integer,
    "productId"   integer,
    shop          varchar(255)             NOT NULL,
    choice        varchar(255),
    "lowStock"    boolean DEFAULT FALSE,
    "sellParty"   varchar(255),
    sell          varchar(255),
    "fulfilParty" varchar(255),
    "createdAt"   timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"   timestamp WITH TIME ZONE NOT NULL
);

DROP TABLE IF EXISTS staging.debug_coreRetailers;
CREATE TABLE IF NOT EXISTS staging.debug_coreRetailers
(
    test_run_id     integer,
    id              integer,
    "coreProductId" integer,
    "retailerId"    integer,
    "productId"     varchar(255),
    "createdAt"     timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"     timestamp WITH TIME ZONE NOT NULL
);


DROP TABLE IF EXISTS staging.debug_productStatuses;
CREATE TABLE IF NOT EXISTS staging.debug_productStatuses
(
    test_run_id integer,
    id          integer,
    "productId" integer,
    status      varchar(255),
    screenshot  varchar(255),
    "createdAt" timestamp WITH TIME ZONE NOT NULL,
    "updatedAt" timestamp WITH TIME ZONE NOT NULL
);

DROP TABLE IF EXISTS staging.debug_promotions;
CREATE TABLE IF NOT EXISTS staging.debug_promotions
(
    test_run_id           integer,
    id                    integer,
    "retailerPromotionId" integer,
    "productId"           integer,
    description           text DEFAULT ''::text    NOT NULL,
    "startDate"           varchar(255),
    "endDate"             varchar(255),
    "createdAt"           timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"           timestamp WITH TIME ZONE NOT NULL,
    "promoId"             varchar(255)
);

DROP TABLE IF EXISTS staging.debug_aggregatedProducts;
CREATE TABLE IF NOT EXISTS staging.debug_aggregatedProducts
(
    test_run_id   integer,
    id            integer,
    "titleMatch"  varchar(255),
    "productId"   integer,
    "createdAt"   timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"   timestamp WITH TIME ZONE NOT NULL,
    features      varchar(255),
    specification varchar(255) DEFAULT '0'::character varying,
    size          varchar(255) DEFAULT '0'::character varying,
    description   varchar(255) DEFAULT '0'::character varying,
    ingredients   varchar(255) DEFAULT '0'::character varying,
    "imageMatch"  varchar(255) DEFAULT '0'::character varying
);

DROP TABLE IF EXISTS staging.debug_coreRetailerDates;
CREATE TABLE IF NOT EXISTS staging.debug_coreRetailerDates
(
    test_run_id      integer,
    id               integer,
    "coreRetailerId" integer,
    "dateId"         integer,
    "createdAt"      timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"      timestamp WITH TIME ZONE NOT NULL
);


DROP TABLE IF EXISTS staging.debug_products;
CREATE TABLE IF NOT EXISTS staging.debug_products
(
    test_run_id            integer,
    id                     integer,
    "sourceType"           varchar(255),
    ean                    varchar(255),
    promotions             boolean,
    "promotionDescription" text,
    features               text,
    date                   timestamp WITH TIME ZONE NOT NULL,
    "sourceId"             varchar(255),
    "productBrand"         varchar(255),
    "productTitle"         varchar(255),
    "productImage"         text,
    "secondaryImages"      boolean      DEFAULT FALSE,
    "productDescription"   text,
    "productInfo"          text,
    "promotedPrice"        varchar(255),
    "productInStock"       boolean      DEFAULT TRUE,
    "productInListing"     boolean      DEFAULT FALSE,
    "reviewsCount"         varchar(255),
    "reviewsStars"         varchar(255),
    "eposId"               varchar(255),
    multibuy               boolean      DEFAULT FALSE,
    "coreProductId"        integer                  NOT NULL,
    "retailerId"           integer,
    "createdAt"            timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"            timestamp WITH TIME ZONE NOT NULL,
    "imageId"              integer,
    size                   varchar(255) DEFAULT NULL::character varying,
    "pricePerWeight"       varchar(255) DEFAULT NULL::character varying,
    href                   text,
    nutritional            text         DEFAULT NULL::character varying,
    "basePrice"            varchar(255),
    "shelfPrice"           varchar(255),
    "productTitleDetail"   varchar(255),
    "sizeUnit"             varchar(255),
    "dateId"               integer
);

DROP TABLE IF EXISTS staging.debug_coreProducts;
CREATE TABLE IF NOT EXISTS staging.debug_coreProducts
(
    test_run_id       integer,
    id                integer,

    ean               varchar(255),
    title             varchar(255),
    image             varchar(255),
    "secondaryImages" boolean,
    description       text,
    features          text,
    ingredients       text,
    "brandId"         integer,
    "categoryId"      integer,
    "productGroupId"  integer,
    "createdAt"       timestamp WITH TIME ZONE   NOT NULL,
    "updatedAt"       timestamp WITH TIME ZONE   NOT NULL,
    bundled           boolean      DEFAULT FALSE,
    disabled          boolean      DEFAULT FALSE NOT NULL,
    "eanIssues"       boolean      DEFAULT FALSE NOT NULL,
    specification     text,
    size              varchar(255) DEFAULT '0'::character varying,
    reviewed          boolean      DEFAULT FALSE NOT NULL,
    "productOptions"  boolean      DEFAULT FALSE NOT NULL
);
DROP TABLE IF EXISTS staging.debug_coreProductCountryData;
CREATE TABLE IF NOT EXISTS staging.debug_coreProductCountryData
(
    test_run_id              integer,
    id                       integer,

    "coreProductId"          integer,
    "countryId"              integer,
    title                    varchar(255),
    image                    varchar(255),
    description              text,
    features                 text,
    ingredients              text,
    specification            text,
    "createdAt"              timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"              timestamp WITH TIME ZONE NOT NULL,
    "secondaryImages"        varchar(255),
    bundled                  boolean,
    disabled                 boolean,
    reviewed                 boolean,
    "ownLabelManufacturerId" integer,
    "brandbankManaged"       boolean DEFAULT FALSE
);

DROP TABLE IF EXISTS staging.debug_coreProductBarcodes;
CREATE TABLE IF NOT EXISTS staging.debug_coreProductBarcodes
(
    test_run_id     integer,
    id              integer,
    "coreProductId" integer,
    barcode         varchar(255)
        UNIQUE,
    "createdAt"     timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"     timestamp WITH TIME ZONE NOT NULL
);


/*  non pp debug tables */

DROP TABLE IF EXISTS staging.debug_tmp_daily_data;
CREATE TABLE IF NOT EXISTS staging.debug_tmp_daily_data
(
    test_run_id            integer,
    retailer               retailers,
    ean                    text,
    date                   date,
    href                   text,
    size                   text,
    "eposId"               text,
    status                 text,
    bundled                boolean,
    category               text,
    featured               boolean,
    features               text,
    promotions             staging.t_promotion[],
    multibuy               boolean,
    "sizeUnit"             text,
    "sourceId"             text,
    "inTaxonomy"           boolean,
    "isFeatured"           boolean,
    "pageNumber"           text,
    screenshot             text,
    "sourceType"           text,
    "taxonomyId"           integer,
    nutritional            text,
    "productInfo"          text,
    "productRank"          integer,
    "categoryType"         text,
    "featuredRank"         integer,
    "productBrand"         text,
    "productImage"         text,
    "productPrice"         double precision,
    "productTitle"         text,
    "reviewsCount"         integer,
    "reviewsStars"         double precision,
    "originalPrice"        double precision,
    "pricePerWeight"       text,
    "productInStock"       boolean,
    "secondaryImages"      boolean,
    "productDescription"   text,
    "productTitleDetail"   text,
    "promotionDescription" text,
    "productOptions"       boolean,
    shop                   text,
    "amazonShop"           text,
    choice                 text,
    "amazonChoice"         text,
    "lowStock"             boolean,
    "sellParty"            text,
    "amazonSellParty"      text,
    sell                   text,
    "fulfilParty"          text,
    "amazonFulfilParty"    text,
    "amazonSell"           text
);


DROP TABLE IF EXISTS staging.debug_tmp_product;
CREATE TABLE IF NOT EXISTS staging.debug_tmp_product
(
    test_run_id          integer,
    id                   integer,
    "coreProductId"      integer,
    promotions           staging.t_promotion[],
    "productPrice"       double precision,
    "originalPrice"      double precision,
    "basePrice"          double precision,
    "shelfPrice"         double precision,
    "promotedPrice"      double precision,
    "retailerId"         integer,
    "dateId"             integer,
    featured             boolean,
    bundled              boolean,
    date                 date,
    ean                  text,
    "eposId"             text,
    features             text,
    href                 text,
    "inTaxonomy"         boolean,
    "isFeatured"         boolean,
    multibuy             boolean,
    nutritional          text,
    "pricePerWeight"     text,
    "productBrand"       text,
    "productDescription" text,
    "productImage"       text,
    "productInStock"     boolean,
    "productInfo"        text,
    "productTitle"       text,
    "productTitleDetail" text,
    "reviewsCount"       integer,
    "reviewsStars"       double precision,
    "secondaryImages"    boolean,
    size                 text,
    "sizeUnit"           text,
    "sourceId"           text,
    "sourceType"         text,
    "brandId"            integer,
    "productOptions"     boolean,
    "eanIssues"          boolean,
    shop                 text,
    "amazonShop"         text,
    choice               text,
    "amazonChoice"       text,
    "lowStock"           boolean,
    "sellParty"          text,
    "amazonSellParty"    text,
    "amazonSell"         text,
    sell                 text,
    "fulfilParty"        text,
    "amazonFulfilParty"  text,
    status               text,
    screenshot           text,
    ranking_data         "productsData"[]
);


DROP TABLE IF EXISTS staging.debug_retailers;

CREATE TABLE IF NOT EXISTS staging.debug_retailers
(
    test_run_id integer,
    id          integer,
    name        varchar(255),
    "createdAt" timestamp WITH TIME ZONE                          NOT NULL,
    "updatedAt" timestamp WITH TIME ZONE                          NOT NULL,
    color       varchar(255) DEFAULT '#ffffff'::character varying NOT NULL,
    logo        varchar(255),
    "countryId" integer
);
DROP TABLE IF EXISTS staging.debug_sourceCategories;
CREATE TABLE IF NOT EXISTS staging.debug_sourceCategories
(
    test_run_id integer,
    id          integer,
    name        varchar(255),
    "createdAt" timestamp WITH TIME ZONE NOT NULL,
    "updatedAt" timestamp WITH TIME ZONE NOT NULL,
    type        varchar(255)             NOT NULL
);

DROP TABLE IF EXISTS staging.debug_productsData;
CREATE TABLE IF NOT EXISTS staging.debug_productsData
(
    test_run_id        integer,
    id                 integer,
    "productId"        integer,
    category           varchar(255),
    "categoryType"     varchar(255),
    "parentCategory"   varchar(255),
    "productRank"      integer,
    "pageNumber"       varchar(255),
    screenshot         varchar(255) DEFAULT ''::character varying,
    "sourceCategoryId" integer,
    featured           boolean      DEFAULT FALSE,
    "featuredRank"     integer,
    "taxonomyId"       integer      DEFAULT 0
);


DROP TABLE IF EXISTS staging.debug_coreRetailerTaxonomies;
CREATE TABLE IF NOT EXISTS staging.debug_coreRetailerTaxonomies
(
    test_run_id          integer,
    id                   integer,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"          timestamp WITH TIME ZONE NOT NULL
);

DROP TABLE IF EXISTS staging.debug_coreProductSourceCategories;
CREATE TABLE IF NOT EXISTS staging.debug_coreProductSourceCategories
(
    test_run_id        integer,
    id                 integer,
    "coreProductId"    integer,
    "sourceCategoryId" integer,
    "createdAt"        timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"        timestamp WITH TIME ZONE NOT NULL
);

DROP FUNCTION IF EXISTS staging.load_retailer_data_pp(json, text);
CREATE OR REPLACE FUNCTION staging.load_retailer_data_pp(value json, flag text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    dd_date           date;
    dd_date_id        integer;
    dd_retailer       retailers;
    debug_test_run_id integer;
BEGIN

    dd_date := value #> '{products,0,date}';

    SELECT *
    INTO dd_retailer
    FROM JSON_POPULATE_RECORD(NULL::retailers,
                              value #> '{retailer}') AS retailer;


    INSERT INTO dates (date)
    VALUES (dd_date AT TIME ZONE 'UTC')
    ON CONFLICT DO NOTHING
    RETURNING id INTO dd_date_id;

    INSERT INTO staging.debug_test_run(data,
                                       flag,
                                       dd_date,
                                       dd_retailer,
                                       dd_date_id)
    SELECT value,
           flag,
           dd_date,
           dd_retailer,
           dd_date_id
    RETURNING id INTO debug_test_run_id;

    CREATE TEMPORARY TABLE tmp_product_pp ON COMMIT DROP AS
    WITH /*prod_brand AS (SELECT id                        AS "brandId",
                               name,
                               brand_names || name::text AS brand_names
                        FROM brands
                                 CROSS JOIN LATERAL ( SELECT ARRAY_AGG(brand_name) AS brand_names
                                                      FROM JSON_ARRAY_ELEMENTS_TEXT("checkList"::json) AS t(brand_name)) AS elements
                        WHERE id NOT IN (87, 1365)
        /*
                    if brand.checklist is to be used, it should be enforced that the values do not overlap.
                    +-------+-----------------+-------+------------------------------------+
                    |brandId|brand_names      |brandId|brand_names                         |
                    +-------+-----------------+-------+------------------------------------+
                    |87     |{liberty,Liberty}|1365   |{apana liberty,liberty,Apna Liberty}|
                    +-------+-----------------+-------+------------------------------------+
         */
    ),*/
        prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
        tmp_daily_data_pp AS (SELECT product.date,
                                     product."countryCode",
                                     product."currency",
                                     product."sourceId",
                                     product.ean,
                                     product."brand",
                                     product."title",
                                     fn_to_float(product."shelfPrice")                                 AS "shelfPrice",
                                     fn_to_float(product."wasPrice")                                   AS "wasPrice",
                                     fn_to_float(product."cardPrice")                                  AS "cardPrice",
                                     fn_to_boolean(product."inStock")                                  AS "inStock",
                                     fn_to_boolean(product."onPromo")                                  AS "onPromo",
                                     COALESCE(product."promoData", ARRAY []::staging.t_promotion_pp[]) AS "promoData",
                                     COALESCE(product."skuURL", '')                                    AS href,
                                     product."imageURL",
                                     COALESCE(fn_to_boolean(product."bundled"), FALSE)                 AS "bundled",
                                     COALESCE(fn_to_boolean(product."masterSku"), FALSE)               AS "productOptions",
                                     shop,
                                     "amazonShop",
                                     choice,
                                     "amazonChoice",
                                     "lowStock",
                                     "sellParty",
                                     "amazonSellParty",
                                     sell,
                                     "fulfilParty",
                                     "amazonFulfilParty",
                                     "amazonSell",
                                     ROW_NUMBER() OVER (PARTITION BY "sourceId")                       AS rownum -- use only the first sourceId record
                              FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                           value #> '{products}') AS product),
        dd_products AS (SELECT COALESCE("wasPrice", "shelfPrice") AS "originalPrice",
                               "shelfPrice"                       AS "productPrice",
                               "shelfPrice",
                               COALESCE("brand", '')              AS "productBrand",

                               'listing'                          AS status,

                               COALESCE("title", '')              AS "productTitle",
                               COALESCE("imageURL", '')           AS "productImage",
                               COALESCE("inStock", TRUE)          AS "productInStock",

                               date,
                               "countryCode",
                               "currency",
                               ean,
                               "brand",
                               "title",
                               href,

                               "sourceId",
                               "cardPrice",
                               "bundled",
                               "productOptions",
                               "promoData",
                               "onPromo",

                               shop,
                               "amazonShop",
                               choice,
                               "amazonChoice",
                               "lowStock",
                               "sellParty",
                               "amazonSellParty",
                               sell,
                               "fulfilParty",
                               "amazonFulfilParty",
                               "amazonSell",

                               ROW_NUMBER() OVER ()               AS index
                        FROM tmp_daily_data_pp

                        WHERE rownum = 1)

    SELECT NULL::integer                                                       AS id,
           dd_retailer.name                                                    AS "sourceType",
           checkEAN.ean,
           -- COALESCE(ARRAY_LENGTH(trsf_promo.promotions, 1) > 0, FALSE)         AS products_promotions_flag,
           COALESCE(trsf_promo."promotionDescription", '')                     AS "promotionDescription",
           ''                                                                  AS features,
           dd_products.date,
           dd_products."sourceId",
           dd_products."productBrand",
           dd_products."productTitle",
           dd_products."productImage",
           FALSE                                                               AS "secondaryImages",
           ''                                                                  AS "productDescription",
           ''                                                                  AS "productInfo",
           dd_products."originalPrice"                                         AS "promotedPrice",
           dd_products."productInStock",
           TRUE                                                                AS "productInListing",
           NULL::integer                                                       AS "reviewsCount",
           NULL::float                                                         AS "reviewsStars",
           NULL                                                                AS "eposId",
           COALESCE(trsf_promo.is_multibuy, FALSE)                             AS multibuy,
           NULL::integer                                                       AS "coreProductId",
           dd_retailer.id                                                      AS "retailerId",
           NOW()                                                               AS "createdAt",
           NOW()                                                               AS "updatedAt",
           NULL                                                                AS "imageId",
           ''                                                                     size,
           NULL                                                                AS "pricePerWeight",
           dd_products.href,
           ''                                                                  AS nutritional,
           dd_products."originalPrice"                                         AS "basePrice",
           dd_products."originalPrice"                                         AS "shelfPrice",
           dd_products."productTitle"                                          AS "productTitleDetail",
           NULL                                                                AS "sizeUnit",
           dd_date_id                                                          AS "dateId",

           dd_products."countryCode",
           dd_products."currency",
           dd_products."cardPrice",
           dd_products."onPromo",
           dd_products."bundled",
           dd_products."originalPrice",
           dd_products."productPrice",
           dd_products.status,
           dd_products."productOptions",

           dd_products.shop,
           dd_products."amazonShop",
           dd_products.choice,
           dd_products."amazonChoice",
           dd_products."lowStock",
           dd_products."sellParty",
           dd_products."amazonSellParty",
           dd_products.sell,
           dd_products."fulfilParty",
           dd_products."amazonFulfilParty",
           dd_products."amazonSell",

           checkEAN."eanIssues",
           dd_ranking.screenshot,
           prod_brand."brandId",
           dd_ranking::"productsData",
           trsf_ean."EANs",
           COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion_mb[]) AS promotions

    FROM dd_products

             CROSS JOIN LATERAL (SELECT NULL              AS id,
                                        NULL              AS "productId",
                                        ''                AS category,
                                        'taxonomy'           "categoryType",
                                        NULL              AS "parentCategory",
                                        dd_products.index AS "productRank",
                                        1                 AS "pageNumber",
                                        ''                AS screenshot,
                                        NULL              AS "sourceCategoryId",

                                        FALSE             AS featured, -- has a featuredRank but  if (!product.featured) product.featured = false;
                                        dd_products.index AS "featuredRank",

                                        NULL              AS "taxonomyId"
        ) AS dd_ranking
             CROSS JOIN LATERAL
        (
        SELECT CASE
                   WHEN
                       dd_products."productOptions"
                       THEN ARRAY [ dd_retailer.name || '_' || dd_products."sourceId"] :: TEXT[]
                   ELSE
                       STRING_TO_ARRAY(dd_products.ean, ',') END AS "EANs"
        ) AS trsf_ean
             CROSS JOIN LATERAL ( SELECT trsf_ean."EANs"[1]                                                 AS ean,
                                         trsf_ean."EANs"[1] !~
                                         '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$' AS "eanIssues"
        ) AS checkEAN
             CROSS JOIN LATERAL ( SELECT ARRAY_AGG(
                                                 (
                                                  CASE WHEN promo_id = '' THEN NULL ELSE promo_id END,-- AS "promoId",
                                                  NULL,--"retailerPromotionId"
                                                  NULL,-- AS "startDate",
                                                  NULL,--AS "endDate"
                                                  promo_description,--AS description,
                                                  promo_type,-- AS mechanic,
                                                  fn_to_float(multibuy_price)-- AS "multibuyPrice"
                                                     )::staging.t_promotion_mb)       AS promotions,
                                         STRING_AGG(promo_description, ';')           AS "promotionDescription",
                                         SUM(fn_to_float(multibuy_price)) IS NOT NULL AS is_multibuy
                                  FROM UNNEST(COALESCE("promoData", ARRAY []::staging.t_promotion_pp[])) AS promo (promo_id,
                                                                                                                   promo_type,
                                                                                                                   promo_description,
                                                                                                                   multibuy_price)
        ) AS trsf_promo
        --   LEFT OUTER JOIN prod_brand ON (ARRAY ["productBrand"] && brand_names);
             LEFT OUTER JOIN prod_brand USING ("productBrand");

    WITH ret_promo AS (SELECT id AS "retailerPromotionId",
                              "retailerId",
                              "promotionMechanicId",
                              regexp,
                              "promotionMechanicName"
                       FROM "retailerPromotions"
                                INNER JOIN (SELECT id   AS "promotionMechanicId",
                                                   name AS "promotionMechanicName"
                                            FROM "promotionMechanics") AS "promotionMechanics"
                                           USING ("promotionMechanicId")),
         product_promo AS (SELECT product."retailerId",
                                  "sourceId",
                                  promo_indx,
                                  lat_dates."startDate",
                                  lat_dates."endDate",

                                  "promotedPrice",
                                  "shelfPrice",
                                  "productPrice",

                                  lat_promo_id."promoId",
                                  promo.description,
                                  promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.
                                  fn_to_float(promo."multibuyPrice")                      AS "multibuyPrice",

                                  COALESCE(ret_promo."retailerPromotionId",
                                           default_ret_promo."retailerPromotionId")       AS "retailerPromotionId",
                                  COALESCE(ret_promo.regexp, default_ret_promo.regexp)    AS regexp,
                                  COALESCE(ret_promo."promotionMechanicId",
                                           default_ret_promo."promotionMechanicId")       AS "promotionMechanicId",
                                  COALESCE(
                                          ret_promo."promotionMechanicName",
                                          default_ret_promo."promotionMechanicName")      AS "promotionMechanicName",
                                  ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx) AS rownum
                           FROM tmp_product_pp AS product
                                    CROSS JOIN LATERAL UNNEST(promotions) WITH ORDINALITY AS promo("promoId",
                                                                                                   "retailerPromotionId",
                                                                                                   "startDate",
                                                                                                   "endDate",
                                                                                                   description,
                                                                                                   mechanic,
                                                                                                   "multibuyPrice",
                                                                                                   promo_indx)
                                    CROSS JOIN LATERAL (SELECT COALESCE(promo."startDate", product.date) AS "startDate",
                                                               COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates
                                    CROSS JOIN LATERAL (SELECT COALESCE(promo."promoId",
                                                                        REPLACE(dd_retailer.id || '_' || "sourceId" ||
                                                                                '_' ||
                                                                                description || '_' ||
                                                                                lat_dates."startDate", ' ',
                                                                                '_')) AS "promoId") AS lat_promo_id
                                    CROSS JOIN LATERAL (
                               SELECT LOWER(multi_replace(promo.description,
                                                          'one', '1', 'two', '2', 'three', '3', 'four', '4', 'five',
                                                          '5',
                                                          'six', '6', 'seven', '7', 'eight', '8', 'nine', '9', 'ten',
                                                          '10',
                                                          ',', '')) AS desc
                               ) AS promo_desc_trsf
                                    LEFT OUTER JOIN ret_promo AS default_ret_promo
                                                    ON (product."retailerId" = default_ret_promo."retailerId" AND
                                                        default_ret_promo."promotionMechanicId" = 3)
                                    LEFT OUTER JOIN ret_promo
                                                    ON (product."retailerId" = ret_promo."retailerId" AND
                                                        CASE
                                                            WHEN ret_promo."promotionMechanicId" IS NULL THEN FALSE
                                                            WHEN LOWER(ret_promo."promotionMechanicName") =
                                                                 COALESCE(promo.mechanic, '') THEN TRUE
                                                            WHEN ret_promo.regexp IS NULL OR LENGTH(ret_promo.regexp) = 0
                                                                THEN FALSE
                                                            WHEN ret_promo."promotionMechanicName" = 'Multibuy' AND
                                                                 promo_desc_trsf.desc ~ '(\d+\/\d+)'
                                                                THEN FALSE
                                                            ELSE
                                                                promo_desc_trsf.desc ~ ret_promo.regexp
                                                            END
                                                        )),
         promo_price_calc AS (SELECT "sourceId",
                                     description,
                                     "multibuyPrice",
                                     "promoId",
                                     "retailerPromotionId",
                                     "startDate",
                                     "endDate",
                                     "promotionMechanicName",
                                     promo_indx,
                                     price_calc."promotedPrice",
                                     price_calc."shelfPrice",
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "sourceId" ORDER BY price_calc."promotedPrice", "multibuyPrice" NULLS LAST ) AS promo_price_order
                              FROM product_promo
                                       CROSS JOIN LATERAL (SELECT CASE
                                                                      WHEN "promotionMechanicName" = 'Multibuy' THEN
                                                                          COALESCE("multibuyPrice",
                                                                                   staging.calculateMultibuyPrice(
                                                                                           description,
                                                                                           "promotedPrice")
                                                                          )
                                                                      ELSE "productPrice"
                                                                      END AS "promotedPrice",
                                                                  CASE
                                                                      WHEN "promotionMechanicName" = 'Multibuy' THEN
                                                                          "shelfPrice"
                                                                      ELSE
                                                                          "productPrice"
                                                                      END AS "shelfPrice") AS price_calc
                              WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
         ),
         upd_product_promo AS (SELECT "sourceId",
                                      MAX("promotedPrice") FILTER (WHERE promo_price_order = 1) AS "promotedPrice",
                                      MAX("shelfPrice") FILTER (WHERE promo_price_order = 1)    AS "shelfPrice",
                                      ARRAY_AGG(("promoId",
                                                 "retailerPromotionId",
                                                 "startDate",
                                                 "endDate",
                                                 description,
                                                 "promotionMechanicName",
                                                 "multibuyPrice")::staging.t_promotion_mb
                                                ORDER BY promo_indx)                            AS promotions
                               FROM promo_price_calc
                               GROUP BY 1)
    UPDATE tmp_product_pp
    SET promotions      = upd_product_promo.promotions,
        "promotedPrice" = upd_product_promo."promotedPrice",
        "shelfPrice"    = upd_product_promo."shelfPrice"
    FROM upd_product_promo
    WHERE tmp_product_pp."sourceId" = upd_product_promo."sourceId";

    /*  createCoreBy    */
    WITH coreProductData AS (SELECT ean,
                                    "productTitle"                    AS title,
                                    "productImage"                    AS image,
                                    "brandId",
                                    bundled,
                                    "secondaryImages",
                                    "productDescription"              AS description,
                                    features,
                                    "productInfo"                     AS ingredients,
                                    size,
                                    nutritional                       AS specification,
                                    COALESCE("productOptions", FALSE) AS "productOptions",
                                    "eanIssues"
                             FROM tmp_product_pp),
         ins_coreProducts AS (
             INSERT
                 INTO "coreProducts" (ean,
                                      title,
                                      image,
                                      "secondaryImages",
                                      description,
                                      features,
                                      ingredients,
                                      "brandId",
                     --"categoryId",
                     --"productGroupId",
                                      "createdAt",
                                      "updatedAt",
                                      bundled,
                                      disabled,
                                      "eanIssues",
                                      specification,
                                      size,
                     --reviewed,
                                      "productOptions")
                     SELECT ean,
                            title,
                            image,
                            "secondaryImages",
                            description,
                            features,
                            ingredients,
                            "brandId",
                            --"categoryId",
                            --"productGroupId",
                            NOW() AS "createdAt",
                            NOW() AS "updatedAt",
                            bundled,
                            FALSE    disabled,
                            "eanIssues",
                            specification,
                            size,
                            --reviewed,
                            "productOptions"
                     FROM coreProductData
                     ON CONFLICT (ean) DO UPDATE
                         SET disabled = FALSE,
                             "productOptions" = excluded."productOptions",
                             "updatedAt" = excluded."updatedAt"
                     RETURNING "coreProducts".*),
         debug_ins_coreProducts AS (
             INSERT INTO staging.debug_coreProducts
                 SELECT debug_test_run_id, * FROM ins_coreProducts),
        /*  createProductCountryData    */
         ins_prod_country_data AS (INSERT INTO "coreProductCountryData" ("coreProductId",
                                                                         "countryId",
                                                                         title,
                                                                         image,
                                                                         description,
                                                                         features,
                                                                         ingredients,
                                                                         specification,
                                                                         "createdAt",
                                                                         "updatedAt",
                                                                         "secondaryImages",
                                                                         bundled,
                                                                         disabled,
                                                                         reviewed)
             SELECT id AS "coreProductId",
                    dd_retailer."countryId",
                    title,
                    image,
                    description,
                    features,
                    ingredients,
                    specification,
                    NOW(),
                    NOW(),
                    "secondaryImages",
                    bundled,
                    disabled,
                    reviewed
             --"ownLabelManufacturerId",
             --"brandbankManaged"
             FROM ins_coreProducts
             --WHERE "updatedAt" != "createdAt"
             WHERE "updatedAt" >= NOW()::date
             ON CONFLICT ("coreProductId", "countryId")
                 WHERE "createdAt" >= '2024-04-17'
                 DO UPDATE
                     SET "updatedAt" = excluded."updatedAt"
             RETURNING "coreProductCountryData".*),
         debug_ins_coreProductCountryData AS (
             INSERT INTO staging.debug_coreProductCountryData
                 SELECT debug_test_run_id, * FROM ins_prod_country_data),
         ins_coreProductBarcodes AS (
             INSERT
                 INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt")
                     SELECT id, ean, NOW(), NOW()
                     FROM ins_coreProducts
                     WHERE "updatedAt" >= NOW()::date
                     ON CONFLICT (barcode)
                         DO UPDATE
                             SET "updatedAt" = excluded."updatedAt"
                     RETURNING "coreProductBarcodes".*),
         debug_ins_coreProductBarcodes AS (
             INSERT INTO staging.debug_coreProductBarcodes
                 SELECT debug_test_run_id, * FROM ins_coreProductBarcodes)
    UPDATE tmp_product_pp
    SET "coreProductId"=ins_coreProducts.id
    FROM ins_coreProducts
    WHERE tmp_product_pp.ean = ins_coreProducts.ean;


    /*  createProductBy    */
    WITH ins_products AS (
        INSERT INTO products ("sourceType",
                              ean,
                              promotions,
                              "promotionDescription",
                              features,
                              date,
                              "sourceId",
                              "productBrand",
                              "productTitle",
                              "productImage",
                              "secondaryImages",
                              "productDescription",
                              "productInfo",
                              "promotedPrice",
                              "productInStock",
                              "reviewsCount",
                              "reviewsStars",
                              "eposId",
                              multibuy,
                              "coreProductId",
                              "retailerId",
                              "createdAt",
                              "updatedAt",
                              size,
                              "pricePerWeight",
                              href,
                              nutritional,
                              "basePrice",
                              "shelfPrice",
                              "productTitleDetail",
                              "sizeUnit",
                              "dateId")
            SELECT "sourceType",
                   ean,
                   COALESCE(ARRAY_LENGTH(promotions, 1) > 0, FALSE) AS promotions,
                   "promotionDescription",
                   features,
                   date,
                   "sourceId",
                   "productBrand",
                   "productTitle",
                   new_img."productImage",
                   "secondaryImages",
                   "productDescription",
                   "productInfo",
                   "promotedPrice",
                   "productInStock",
                   --  "productInListing",
                   "reviewsCount",
                   "reviewsStars",
                   "eposId",
                   multibuy,
                   "coreProductId",
                   "retailerId",
                   NOW()                                            AS "createdAt",
                   NOW()                                            AS "updatedAt",
                   -- "imageId",
                   size,
                   "pricePerWeight",
                   href,
                   nutritional,
                   "basePrice",
                   "shelfPrice",
                   "productTitleDetail",
                   "sizeUnit",
                   "dateId"
            FROM tmp_product_pp
                     CROSS JOIN LATERAL (SELECT CASE
                                                    WHEN "sourceType" = 'sainsburys' THEN
                                                        REPLACE(
                                                                REPLACE(
                                                                        'https://www.sainsburys.co.uk' ||
                                                                        "productImage",
                                                                        'https://www.sainsburys.co.ukhttps://www.sainsburys.co.uk',
                                                                        'https://www.sainsburys.co.uk'),
                                                                'https://www.sainsburys.co.ukhttps://assets.sainsburys-groceries.co.uk',
                                                                'https://assets.sainsburys-groceries.co.uk')
                                                    WHEN "sourceType" = 'ocado' THEN REPLACE(
                                                            'https://www.ocado.com' || "productImage",
                                                            'https://www.ocado.comhttps://ocado.com',
                                                            'https://www.ocado.com')
                                                    WHEN "sourceType" = 'morrisons' THEN
                                                        'https://groceries.morrisons.com' || "productImage"
                                                    END AS "productImage"

                ) AS new_img
            ON CONFLICT ("sourceId", "retailerId", "dateId")
                WHERE "createdAt" >= '2024-04-17'
                DO UPDATE
                    SET "updatedAt" = excluded."updatedAt"
            RETURNING products.*),
         debug_ins_products AS (
             INSERT INTO staging.debug_products
                 SELECT debug_test_run_id, * FROM ins_products)
    UPDATE tmp_product_pp
    SET id=ins_products.id
    FROM ins_products
    WHERE tmp_product_pp."sourceId" = ins_products."sourceId"
      AND tmp_product_pp."retailerId" = ins_products."retailerId"
      AND tmp_product_pp."dateId" = ins_products."dateId";

    INSERT INTO staging.debug_tmp_product_pp
    SELECT debug_test_run_id, *
    FROM tmp_product_pp;

    /*  createAmazonProduct */
    /*
       TO DO: set UQ constrain in amazonProducts on productId?.
     */
    WITH debug_ins_amz AS (INSERT INTO "amazonProducts" ("productId",
                                                         shop,
                                                         choice,
                                                         "lowStock",
                                                         "sellParty",
                                                         sell,
                                                         "fulfilParty",
                                                         "createdAt",
                                                         "updatedAt")
        SELECT id                                                                         AS "productId",
               COALESCE(COALESCE(product."amazonShop", product.shop), '')                 AS shop,
               COALESCE(COALESCE(product."amazonChoice", product.choice), '')             AS choice,
               COALESCE(product."lowStock", FALSE)                                        AS "lowStock",
               COALESCE(COALESCE(product."amazonSellParty", product."sellParty"), '')     AS "sellParty",
               COALESCE(COALESCE(product."amazonSell", product."sell"), '')               AS "sell",
               COALESCE(COALESCE(product."amazonFulfilParty", product."fulfilParty"), '') AS "fulfilParty",
               NOW(),
               NOW()
        FROM tmp_product_pp AS product
        WHERE LOWER("sourceType") LIKE '%amazon%'
        RETURNING "amazonProducts".*)
    INSERT
    INTO staging.debug_amazonproducts
    SELECT debug_test_run_id, *
    FROM debug_ins_amz;


    /*  setCoreRetailer */
    CREATE TEMPORARY TABLE tmp_coreRetailer ON COMMIT DROP AS
    WITH ins_coreRetailers AS (
        INSERT INTO "coreRetailers" ("coreProductId",
                                     "retailerId",
                                     "productId",
                                     "createdAt",
                                     "updatedAt")
            SELECT product."coreProductId",
                   dd_retailer.id,
                   product.id AS "productId",
                   NOW()      AS "createdAt",
                   NOW()      AS "updatedAt"
            FROM tmp_product_pp AS product
            ON CONFLICT ("coreProductId",
                "retailerId",
                "productId") DO UPDATE SET "updatedAt" = excluded."updatedAt"
            RETURNING "coreRetailers".*)
    SELECT id,
           "coreProductId",
           "retailerId",
           "productId"::integer,
           "createdAt",
           "updatedAt"
    FROM ins_coreRetailers;

    INSERT
    INTO staging.debug_coreRetailers
    SELECT debug_test_run_id, *
    FROM tmp_coreRetailer;

    /*  saveProductStatus   */
    WITH debug_productStatuses AS ( INSERT INTO "productStatuses" ("productId",
                                                                   status,
                                                                   screenshot,
                                                                   "createdAt",
                                                                   "updatedAt")
        SELECT id AS "productId",
               status,
               screenshot,
               NOW(),
               NOW()
        FROM tmp_product_pp
        ON CONFLICT ("productId")
            DO NOTHING
        RETURNING "productStatuses".*)
    INSERT
    INTO staging.debug_productStatuses
    SELECT debug_test_run_id, *
    FROM debug_productStatuses;

    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  PromotionService.processProductPromotions, part 2 insert promotions  */
    WITH debug_ins_promotions AS (
        INSERT INTO promotions ("retailerPromotionId",
                                "productId",
                                description,
                                "startDate",
                                "endDate",
                                "createdAt",
                                "updatedAt",
                                "promoId")
            SELECT "retailerPromotionId",
                   id    AS "productId",
                   description,
                   "startDate",
                   "endDate",
                   NOW() AS "createdAt",
                   NOW() AS "updatedAt",
                   "promoId"
            FROM tmp_product_pp
                     CROSS JOIN LATERAL UNNEST(promotions) AS promo
            ON CONFLICT ("productId", "promoId")
                WHERE "createdAt" >= '2024-04-17'
                DO
                    UPDATE
                    SET "startDate" = LEAST(promotions."startDate", excluded."startDate"),
                        "endDate" = GREATEST(promotions."endDate", excluded."endDate"),
                        "updatedAt" = excluded."updatedAt"
            RETURNING promotions.*)
    INSERT
    INTO staging.debug_promotions
    SELECT debug_test_run_id, *
    FROM debug_ins_promotions;

    /*  aggregatedProducts  */
    WITH debug_ins_aggregatedProducts AS (
        INSERT INTO "aggregatedProducts" ("titleMatch",
                                          "productId",
                                          "createdAt",
                                          "updatedAt"
            /*
            TO DO:
            Handle the rest of the "match" scores:
                features,
                specification,
                size,
                description,
                ingredients,
                "imageMatch"
             */
            )
            SELECT staging.compareTwoStrings("titleParent", "productTitle") AS "titleMatch",
                   id                                                       AS "productId",
                   NOW()                                                    AS "createdAt",
                   NOW()                                                       "updatedAt"
            FROM tmp_product_pp
                     INNER JOIN (SELECT "coreProductId", title AS "titleParent"
                                 FROM "coreProductCountryData"
                                 WHERE "countryId" = dd_retailer."countryId") AS parentProdCountryData
                                USING ("coreProductId")
            ON CONFLICT ("productId")
                WHERE "createdAt" >= '2024-04-17'
                DO NOTHING
            RETURNING "aggregatedProducts".*)
    INSERT
    INTO staging.debug_aggregatedProducts
    SELECT debug_test_run_id, *
    FROM debug_ins_aggregatedProducts;

    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  coreRetailerDates */
    WITH debug_coreRetailerDates AS ( INSERT INTO "coreRetailerDates" ("coreRetailerId",
                                                                       "dateId",
                                                                       "createdAt",
                                                                       "updatedAt")
        SELECT tmp_coreRetailer.id AS "coreRetailerId",
               dd_date_id          AS "dateId",
               NOW(),
               NOW()
        FROM tmp_coreRetailer
        ON CONFLICT ("coreRetailerId",
            "dateId")
            DO NOTHING
        RETURNING "coreRetailerDates".*)
    INSERT
    INTO staging.debug_coreRetailerDates
    SELECT debug_test_run_id, *
    FROM debug_coreRetailerDates;


    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    RETURN;
END ;
$$;

SELECT created_at
FROM staging.retailer_daily_data
WHERE flag = 'create-products-pp';


SELECT staging.load_retailer_data_pp(fetched_data, flag)
FROM staging.retailer_daily_data
WHERE flag = 'create-products-pp'
  AND created_at = '2024-04-16 08:00:00.878527+00';
--  AND created_at = '2024-04-16 07:15:28.068484 +00:00';

SELECT COUNT(*)
FROM staging.debug_products;
SELECT COUNT(*)
FROM staging.debug_tmp_product_pp
WHERE id IS NOT NULL;



SELECT *
FROM staging.debug_tmp_product_pp
WHERE ean = 'B&M_250845';


SELECT *
FROM staging.debug_products
WHERE ean = 'B&M_250845';


SELECT *
FROM staging.debug_aggregatedproducts
WHERE "productId" = 196470916;


SELECT *
FROM staging.debug_amazonproducts
WHERE "productId" = 196470916;

SELECT *
FROM staging.debug_promotions
WHERE "productId" = 196470916;

SELECT *
FROM staging.debug_coreretailers
WHERE "productId" = 196470916::text;
SELECT *
FROM staging.debug_productstatuses
WHERE "productId" = 196470916;


SELECT *
FROM staging.debug_coreretailerdates
WHERE "coreRetailerId" = 917623;

SELECT *
FROM staging.debug_coreproducts
WHERE id = 961206;

SELECT *
FROM staging.debug_coreproductcountrydata
WHERE "coreProductId" = 961206;

SELECT *
FROM staging.debug_coreproductbarcodes
WHERE "coreProductId" = 961206;


SELECT COUNT(*)
FROM products
WHERE id > 196238805;

SELECT *
FROM staging.debug_tmp_product_pp
WHERE ARRAY_LENGTH(promotions, 1) > 1;


SELECT *
FROM products
WHERE id IN (
             196400478,
             196403680
    );


WITH data_comp AS (SELECT id,
                          name
                   FROM "sourceCategories")
SELECT a.name, STRING_AGG(b.name, ',' ORDER BY similarity(a.name, b.name) DESC, b.name) AS similar_names
FROM data_comp a
         INNER JOIN data_comp b
                    ON a.name >
                       b.name
                        --AND a.name % b.name
                        AND a.name LIKE b.name || '%'
GROUP BY a.name;

WITH prod_brand AS (SELECT id                        AS "brandId",
                           brand_names || name::text AS brand_names
                    FROM brands
                             CROSS JOIN LATERAL ( SELECT ARRAY_AGG(LOWER(brand_name)) AS brand_names
                                                  FROM JSON_ARRAY_ELEMENTS_TEXT("checkList"::json) AS t(brand_name)) AS elements)
SELECT *
FROM prod_brand a
         INNER JOIN prod_brand b ON a."brandId" < b."brandId" AND a.brand_names && b.brand_names



SELECT id                        AS "brandId",
       name,
       brand_names || name::text AS brand_names
FROM brands
         CROSS JOIN LATERAL ( SELECT ARRAY_AGG(brand_name) AS brand_names
                              FROM JSON_ARRAY_ELEMENTS_TEXT("checkList"::json) AS t(brand_name)) AS elements