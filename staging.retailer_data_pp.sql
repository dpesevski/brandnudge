DROP TYPE IF EXISTS staging.t_promotion CASCADE;
CREATE TYPE staging.t_promotion AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    description           text,
    mechanic              text
);

DROP TYPE IF EXISTS staging.retailer_data CASCADE;
CREATE TYPE staging.retailer_data AS
(
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
    "productPrice"         text,--double precision,
    "productTitle"         text,
    "reviewsCount"         integer,
    "reviewsStars"         text,--double precision,
    "originalPrice"        text,--double precision,
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



DROP TYPE IF EXISTS staging.t_promotion_pp CASCADE;
CREATE TYPE staging.t_promotion_pp AS
(
    promo_id          text,
    promo_type        text,
    promo_description text,
    multibuy_price    text
);
DROP TYPE IF EXISTS staging.retailer_data_pp;
CREATE TYPE staging.retailer_data_pp AS
(
    DATE          DATE,
    retailer      TEXT,
    "countryCode" TEXT,
    "currency"    TEXT,

    "sourceId"    TEXT,


    ean           TEXT,

    "brand"       TEXT,
    "title"       TEXT,

    "shelfPrice"  TEXT,--double precision,
    "wasPrice"    TEXT,--double precision,
    "cardPrice"   TEXT,--double precision,
    "inStock"     TEXT,--boolean,
    "onPromo"     TEXT,--boolean,

    "promoData"   staging.t_promotion_pp[],

    "skuURL"      TEXT,
    "imageURL"    TEXT,


    "bundled"     TEXT,--boolean,
    "masterSku"   TEXT--boolean
);

SET WORK_MEM = ' 2097151';
SHOW WORK_MEM;

CREATE OR REPLACE FUNCTION fn_to_float(value text) RETURNS double precision
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::float;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

CREATE OR REPLACE FUNCTION fn_to_date(value text) RETURNS date
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;
CREATE OR REPLACE FUNCTION fn_to_boolean(value text) RETURNS boolean
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::boolean;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

DROP TABLE IF EXISTS staging.test_file;
CREATE TABLE staging.test_file AS
SELECT params.retailer,
       JSON_ARRAY_LENGTH(params.products)    AS products_count,
       params.products #>> '{0,date}'        AS date,
       params.retailer || '__' || created_at AS file_src,
       PG_COLUMN_SIZE(fetched_data)          AS size,
       flag,
       fetched_data,
       is_pp,
       products,
       created_at
FROM staging.retailer_daily_data
         CROSS JOIN LATERAL (SELECT CASE
                                        WHEN flag = 'create-products-pp' THEN COALESCE(
                                                fetched_data #>> '{retailer, name}',
                                                fetched_data #>> '{retailer}')
                                        ELSE fetched_data #>> '{0, sourceType}' END AS retailer,
                                    CASE
                                        WHEN flag = 'create-products-pp' THEN fetched_data -> 'products'
                                        ELSE fetched_data END                       AS products,
                                    CASE
                                        WHEN flag = 'create-products-pp'
                                            THEN (fetched_data #> '{products,0}')::jsonb ? 'title'
                                        ELSE FALSE
                                        END                                         AS is_pp
    ) AS params
ORDER BY file_src;


DROP TABLE IF EXISTS staging.tests_daily_data_pp;
CREATE TABLE staging.tests_daily_data_pp AS
SELECT file_src,
       product.date,
       test_file.retailer,
       product."countryCode",
       product."currency",
       product."sourceId",
       product.ean,
       product."brand",
       product."title",
       fn_to_float(product."shelfPrice")  AS "shelfPrice",
       fn_to_float(product."wasPrice")    AS "wasPrice",
       fn_to_float(product."cardPrice")   AS "cardPrice",
       fn_to_boolean(product."inStock")   AS "inStock",
       fn_to_boolean(product."onPromo")   AS "onPromo",
       product."promoData",
       product."skuURL",
       product."imageURL",
       fn_to_boolean(product."bundled")   AS "bundled",
       fn_to_boolean(product."masterSku") AS "masterSku"
FROM staging.test_file
         CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                    products) AS product
WHERE test_file.is_pp;

DROP TABLE IF EXISTS staging.tests_daily_data;
CREATE TABLE staging.tests_daily_data AS
SELECT file_src,
       product.retailer,
       ean,
       product.date,
       href,
       product.size,
       "eposId",
       status,
       bundled,
       category,
       featured,
       features,
       promotions,
       multibuy,
       "sizeUnit",
       "sourceId",
       "inTaxonomy",
       "isFeatured",
       "pageNumber",
       screenshot,
       "sourceType",
       "taxonomyId",
       nutritional,
       "productInfo",
       "productRank",
       "categoryType",
       "featuredRank",
       "productBrand",
       "productImage",
       fn_to_float("productPrice")  AS "productPrice",
       "productTitle",
       "reviewsCount",
       fn_to_float("reviewsStars")  AS "reviewsStars",
       fn_to_float("originalPrice") AS "originalPrice",
       "pricePerWeight",
       "productInStock",
       "secondaryImages",
       "productDescription",
       "productTitleDetail",
       "promotionDescription",
       "productOptions",
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
       "amazonSell"
FROM staging.test_file
         CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data,
                                                    products) AS product
WHERE NOT test_file.is_pp;


SELECT retailer,
       products_count,
       date,
       file_src,
       size,
       flag,
       is_pp,
       created_at
FROM staging.test_file;


SELECT retailer,
       is_pp,
       COUNT(*)
FROM staging.test_file
GROUP BY retailer, is_pp;
