CREATE INDEX IF NOT EXISTS products_retailerId_coreProductId_date_index ON products ("retailerId", "coreProductId", "date");

CREATE INDEX IF NOT EXISTS products_retailerId_index ON products ("retailerId");
--[2024-11-28 15:15:32] completed in 6 m 3 s 346 ms


/*  remove sourceCategories and related tables    */
ALTER TABLE "productsData"
    DROP COLUMN "sourceCategoryId";

/*
FK to "sourceCategories"
+---------------------------+
|TABLE_NAME                 |
+---------------------------+
|productsData               |
|companySourceCategories    |
|coreProductSourceCategories|
+---------------------------+
*/

DROP TABLE "companySourceCategories";
DROP TABLE "coreProductSourceCategories";
DROP TABLE "userSourceCategories";
DROP TABLE "sourceCategories";

/*  add load_id to tables in public schema    */
ALTER TABLE public."products"
    ADD IF NOT EXISTS load_id integer;

ALTER TABLE public."productsData"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."productStatuses"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."promotions"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."aggregatedProducts"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."amazonProducts"
    ADD IF NOT EXISTS load_id integer;

ALTER TABLE public."retailers"
    ADD IF NOT EXISTS load_id integer;

ALTER TABLE public."coreProducts"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreProductBarcodes"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreProductCountryData"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreRetailerDates"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreRetailers"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreRetailerSources"
    ADD IF NOT EXISTS load_id integer;
ALTER TABLE public."coreRetailerTaxonomies"
    ADD IF NOT EXISTS load_id integer;

CREATE INDEX products_load_id_index ON products (load_id);

/*
    UQ indexes are deployed in prod
    with temporal condition on "createdAt" >= '2024-05-31 20:21:46.840963+00';
*/

CREATE EXTENSION IF NOT EXISTS plv8;
DROP FUNCTION IF EXISTS compareTwoStrings(text, text);
CREATE OR REPLACE FUNCTION compareTwoStrings(title1 text, title2 text) RETURNS float
    LANGUAGE plv8
AS
$$

    const first = title1 ? title1.replace(/\s+/g, ''):'';
    const second = title2 ? title2.replace(/\s+/g, ''):'';

    if (!first.length && !second.length) return 1;
    if (!first.length || !second.length) return 0;
    if (first === second) return 1;
    if (first.length === 1 && second.length === 1) return 0;
    if (first.length < 2 || second.length < 2) return 0;

    const firstBigrams = new Map();
    for (let i = 0; i < first.length - 1; i += 1) {
      const bigram = first.substr(i, 2);
      const count = firstBigrams.has(bigram) ? firstBigrams.get(bigram) + 1 : 1;

      firstBigrams.set(bigram, count);
    }
    let intersectionSize = 0;
    for (let i = 0; i < second.length - 1; i += 1) {
      const bigram = second.substr(i, 2);
      const count = firstBigrams.has(bigram) ? firstBigrams.get(bigram) : 0;

      if (count > 0) {
        firstBigrams.set(bigram, count - 1);
        intersectionSize += 1;
      }
    }
    return (2.0 * intersectionSize) / (first.length + second.length - 2);
$$;

DROP FUNCTION IF EXISTS calculateMultibuyPrice(text, float);
CREATE OR REPLACE FUNCTION calculateMultibuyPrice(description text, price float) RETURNS float
    LANGUAGE plv8
AS
$$
function textToNumber(str) {
  const numMap = {
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
  };

  return Object.keys(numMap).reduce(
    (res, text) => res.replace(new RegExp(text, 'gi'), numMap[text]),
    str,
  );
}

function numPrice(price) {
  if (!price) return 1;
  if (!isNaN(price)) return price;
  if (price.includes('£')) return parseFloat(price.split('£')[1]).toFixed(2);
  else if (price.includes('p'))
    return parseFloat(price.split('p')[0] / 100).toFixed(2);
  return price;
}
 if (!description || !price) return price;
    let result = price;
    const desc = textToNumber(description.replace(',', '').toLowerCase());

    const isFloat = n => Number(n) === n && n % 1 !== 0;

    const countAndPrice = desc.match(/£?(\d+(.\d{1,2})?|\d+\/\d+)p?/g);
    if (!countAndPrice || !countAndPrice.length) return price;

    const [count, discountPrice = '£1'] = countAndPrice;
    const dp = numPrice(discountPrice);
    let sum = price * count;

    // "3 for 2" match
    const forMatch = desc.match(/(\d+) for (\d+)/i);

    if (forMatch) {
      // eslint-disable-next-line no-unused-vars
      const [match, totalCount, forCount] = forMatch;
      sum = price * forCount;
      result = sum / totalCount;
    } else if (desc.includes('save')) {
      const isPercent = desc.includes('%');
      const halfPrice = desc.includes('half price');
      // eslint-disable-next-line no-nested-ternary
      const discount = isPercent ? (sum / 100) * dp : halfPrice ? sum / 2 : dp;
      result = (sum - discount) / count;
    } else if (desc.includes('price of')) {
      result = (price * dp) / count;
    } else if (desc.includes('free')) {
      const freeCount = dp > count ? 1 : +dp;
      result = sum / (+count + freeCount);
    } else if (desc.includes('half price')) {
      sum += (price / 2) * dp;
      result = sum / (+count + +dp);
    } else {
      result = Math.round((dp * 100.0) / count) / 100;
    }

    result = isFloat(result) ? result.toFixed(2) : result;

    return result.toString();
$$;

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

CREATE OR REPLACE FUNCTION public.fn_to_date(value text) RETURNS date
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


CREATE OR REPLACE FUNCTION public.fn_to_boolean(value text) RETURNS boolean
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


CREATE OR REPLACE FUNCTION multi_replace(value text, VARIADIC arr text[]) RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    e         text;
    find_text text;
BEGIN
    BEGIN
        FOREACH e IN ARRAY arr
            LOOP
                IF find_text IS NULL THEN
                    find_text := e;
                ELSE
                    value := REPLACE(value, find_text, e);
                    find_text := NULL;
                END IF;
            END LOOP;

        RETURN value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;


--ALTER SCHEMA staging RENAME TO staging_bck;

/*
DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;
*/

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

DROP TYPE IF EXISTS staging.retailer_data;
CREATE TYPE staging.retailer_data AS
(
    retailer                retailers,
    ean                     text,
    date                    date,
    href                    text,
    size                    text,
    "eposId"                text,
    status                  text,
    bundled                 boolean,
    category                text,
    featured                boolean,
    features                text,
    promotions              staging.t_promotion[],
    multibuy                boolean,
    "sizeUnit"              text,
    "sourceId"              text,
    "inTaxonomy"            boolean,
    "isFeatured"            boolean,
    "pageNumber"            text,
    screenshot              text,
    "sourceType"            text,
    "taxonomyId"            integer,
    nutritional             text,
    "productInfo"           text,
    "productRank"           integer,
    "categoryType"          text,
    "featuredRank"          integer,
    "productBrand"          text,
    "productImage"          text,
    "newCoreImage"          text,
    "productPrice"          text,--double precision,
    "productTitle"          text,
    "reviewsCount"          integer,
    "reviewsStars"          text,--double precision,
    "originalPrice"         text,--double precision,
    "pricePerWeight"        text,
    "productInStock"        boolean,
    "secondaryImages"       boolean,
    "productDescription"    text,
    "productTitleDetail"    text,
    "promotionDescription"  text,
    "productOptions"        boolean,
    shop                    text,
    "amazonShop"            text,
    choice                  text,
    "amazonChoice"          text,
    "lowStock"              boolean,
    "sellParty"             text,
    "amazonSellParty"       text,
    sell                    text,
    "fulfilParty"           text,
    "amazonFulfilParty"     text,
    "amazonSell"            text,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean
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
    DATE                    DATE,
    retailer                TEXT,
    "countryCode"           TEXT,
    "currency"              TEXT,

    "sourceId"              TEXT,


    ean                     TEXT,

    "brand"                 TEXT,
    "title"                 TEXT,

    "shelfPrice"            TEXT,--double precision,
    "wasPrice"              TEXT,--double precision,
    "cardPrice"             TEXT,--double precision,
    "inStock"               TEXT,--boolean,
    "onPromo"               TEXT,--boolean,

    "promoData"             staging.t_promotion_pp[],

    "skuURL"                TEXT,
    "imageURL"              TEXT,

    "newCoreImage"          text,

    "bundled"               TEXT,--boolean,
    "masterSku"             TEXT,--boolean
    shop                    text,
    "amazonShop"            text,
    choice                  text,
    "amazonChoice"          text,
    "lowStock"              boolean,
    "sellParty"             text,
    "amazonSellParty"       text,
    sell                    text,
    "fulfilParty"           text,
    "amazonFulfilParty"     text,
    "amazonSell"            text,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean,
    size                    text,
    "sizeUnit"              text,
    "pricePerWeight"        text,

    "reviewsCount"          text,
    "reviewsStars"          text
);

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

DROP TABLE IF EXISTS staging.load;
CREATE TABLE IF NOT EXISTS staging.load
(
    id             serial,
    data           json,
    flag           text,
    run_at         timestamp DEFAULT NOW(),
    dd_date        date,
    dd_retailer    retailers,
    dd_date_id     integer,
    dd_source_type text,
    execution_time double precision
);

DROP TABLE IF EXISTS staging.debug_errors;
CREATE TABLE staging.debug_errors
(
    id           SERIAL,
    load_id      integer,
    sql_state    TEXT,
    message      TEXT,
    detail       TEXT,
    hint         TEXT,
    context      TEXT,
    fetched_data json,
    flag         text,
    created_at   timestamp DEFAULT NOW()
);
DROP TABLE IF EXISTS staging.retailer_daily_data;
CREATE TABLE staging.retailer_daily_data
(
    load_id      serial,
    fetched_data json,
    flag         text,
    created_at   timestamp WITH TIME ZONE DEFAULT NOW()
);

DROP TABLE IF EXISTS staging.debug_tmp_daily_data;
CREATE TABLE IF NOT EXISTS staging.debug_tmp_daily_data
(
    load_id                 integer,
    retailer                retailers,
    ean                     text,
    date                    date,
    href                    text,
    size                    text,
    "eposId"                text,
    status                  text,
    bundled                 boolean,
    category                text,
    featured                boolean,
    features                text,
    promotions              staging.t_promotion[],
    multibuy                boolean,
    "sizeUnit"              text,
    "sourceId"              text,
    "inTaxonomy"            boolean,
    "isFeatured"            boolean,
    "pageNumber"            text,
    screenshot              text,
    "sourceType"            text,
    "taxonomyId"            integer,
    nutritional             text,
    "productInfo"           text,
    "productRank"           integer,
    "categoryType"          text,
    "featuredRank"          integer,
    "productBrand"          text,
    "productImage"          text,
    "newCoreImage"          text,
    "productPrice"          double precision,
    "productTitle"          text,
    "reviewsCount"          integer,
    "reviewsStars"          double precision,
    "originalPrice"         double precision,
    "pricePerWeight"        text,
    "productInStock"        boolean,
    "secondaryImages"       boolean,
    "productDescription"    text,
    "productTitleDetail"    text,
    "promotionDescription"  text,
    "productOptions"        boolean,
    shop                    text,
    "amazonShop"            text,
    choice                  text,
    "amazonChoice"          text,
    "lowStock"              boolean,
    "sellParty"             text,
    "amazonSellParty"       text,
    sell                    text,
    "fulfilParty"           text,
    "amazonFulfilParty"     text,
    "amazonSell"            text,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean
);
DROP TABLE IF EXISTS staging.debug_tmp_product;
CREATE TABLE IF NOT EXISTS staging.debug_tmp_product
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
DROP TABLE IF EXISTS staging.debug_tmp_product_pp;
CREATE TABLE staging.debug_tmp_product_pp
(
    load_id                 integer,
    id                      integer,
    "sourceType"            varchar(255),
    ean                     text,
    "promotionDescription"  text,
    features                text,
    date                    date,
    "sourceId"              text,
    "productBrand"          text,
    "productTitle"          text,
    "productImage"          text,
    "newCoreImage"          text,
    "secondaryImages"       boolean,
    "productDescription"    text,
    "productInfo"           text,
    "promotedPrice"         double precision,
    "productInStock"        boolean,
    "productInListing"      boolean,
    "reviewsCount"          integer,
    "reviewsStars"          double precision,
    "eposId"                text,
    multibuy                boolean,
    "coreProductId"         integer,
    "retailerId"            integer,
    "createdAt"             timestamp WITH TIME ZONE,
    "updatedAt"             timestamp WITH TIME ZONE,
    "imageId"               text,
    size                    text,
    "pricePerWeight"        text,
    href                    text,
    nutritional             text,
    "basePrice"             double precision,
    "shelfPrice"            double precision,
    "productTitleDetail"    text,
    "sizeUnit"              text,
    "dateId"                integer,
    "countryCode"           text,
    currency                text,
    "cardPrice"             double precision,
    "onPromo"               boolean,
    bundled                 boolean,
    "originalPrice"         double precision,
    "productPrice"          double precision,
    status                  text,
    "productOptions"        boolean,
    shop                    text,
    "amazonShop"            text,
    choice                  text,
    "amazonChoice"          text,
    "lowStock"              boolean,
    "sellParty"             text,
    "amazonSellParty"       text,
    sell                    text,
    "fulfilParty"           text,
    "amazonFulfilParty"     text,
    "amazonSell"            text,
    marketplace             boolean,
    "marketplaceData"       json,
    "priceMatchDescription" text,
    "priceMatch"            boolean,
    "priceLock"             boolean,
    "isNpd"                 boolean,
    "eanIssues"             boolean,
    screenshot              text,
    "brandId"               integer,
    "EANs"                  text[],
    promotions              staging.t_promotion_mb[]
);

/*  tables tracking changes in public schema*/
DROP TABLE IF EXISTS staging.debug_aggregatedproducts;
CREATE TABLE staging.debug_aggregatedproducts
(
    LIKE "aggregatedProducts"
);
DROP TABLE IF EXISTS staging.debug_amazonproducts;
CREATE TABLE staging.debug_amazonproducts
(
    LIKE "amazonProducts"
);
DROP TABLE IF EXISTS staging.debug_coreproductbarcodes;
CREATE TABLE staging.debug_coreproductbarcodes
(
    LIKE "coreProductBarcodes"
);
DROP TABLE IF EXISTS staging.debug_coreproductcountrydata;
CREATE TABLE staging.debug_coreproductcountrydata
(
    LIKE "coreProductCountryData"
);
DROP TABLE IF EXISTS staging.debug_coreproducts;
CREATE TABLE staging.debug_coreproducts
(
    LIKE "coreProducts"
);
DROP TABLE IF EXISTS staging.debug_coreretailerdates;
CREATE TABLE staging.debug_coreretailerdates
(
    LIKE "coreRetailerDates"
);
DROP TABLE IF EXISTS staging.debug_coreretailers;
CREATE TABLE staging.debug_coreretailers
(
    "sourceId" text,
    LIKE "coreRetailers"
);
DROP TABLE IF EXISTS staging.debug_coreretailertaxonomies;
CREATE TABLE staging.debug_coreretailertaxonomies
(
    LIKE "coreRetailerTaxonomies"
);
DROP TABLE IF EXISTS staging.debug_products;
CREATE TABLE staging.debug_products
(
    LIKE "products"
);
DROP TABLE IF EXISTS staging.debug_productsdata;
CREATE TABLE staging.debug_productsdata
(
    LIKE "productsData"
);
DROP TABLE IF EXISTS staging.debug_productstatuses;
CREATE TABLE staging.debug_productstatuses
(
    LIKE "productStatuses"
);
DROP TABLE IF EXISTS staging.debug_promotions;
CREATE TABLE staging.debug_promotions
(
    LIKE "promotions"
);
DROP TABLE IF EXISTS staging.debug_retailers;
CREATE TABLE staging.debug_retailers
(
    LIKE "retailers"
);

DROP FUNCTION IF EXISTS staging.load_retailer_data(json, text);
CREATE OR REPLACE FUNCTION staging.load_retailer_data(fetched_data json, flag text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    _sql_state TEXT;
    _message   TEXT;
    _detail    TEXT;
    _hint      TEXT;
    _context   TEXT;
    _load_id   integer;
    _start_ts  timestamptz;
BEGIN

    INSERT INTO staging.retailer_daily_data (fetched_data, flag)
    VALUES (fetched_data, flag)
    RETURNING load_id INTO _load_id;

    _start_ts := CLOCK_TIMESTAMP();
    /*IF flag = 'create-products' THEN

        IF JSON_TYPEOF(fetched_data) = 'array' THEN
            RAISE EXCEPTION 'old create-products structure, with no retailer object';
        ELSE
            PERFORM staging.load_retailer_data_base(fetched_data, _load_id);
        END IF;
    ELSEIF flag = 'create-products-pp' THEN*/
    IF flag = 'create-products-pp' THEN
        PERFORM staging.load_retailer_data_pp(fetched_data, _load_id);
    ELSE
        RAISE EXCEPTION 'no valid flag provided';
    END IF;

    UPDATE staging.load
    SET execution_time=ROUND((EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) - EXTRACT(EPOCH FROM _start_ts))::numeric,
                             2) -- in seconds
    WHERE id = _load_id;

    RETURN _load_id;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sql_state := RETURNED_SQLSTATE,
            _message := MESSAGE_TEXT,
            _detail := PG_EXCEPTION_DETAIL,
            _hint := PG_EXCEPTION_HINT,
            _context := PG_EXCEPTION_CONTEXT;

        INSERT INTO staging.debug_errors (load_id, sql_state, message, detail, hint, context, fetched_data,
                                          flag)
        VALUES (_load_id, _sql_state, _message, _detail, _hint, _context, fetched_data, flag);
        RETURN -1 * _load_id;
END
$$;

DROP FUNCTION IF EXISTS staging.load_retailer_data_pp(json, integer);
CREATE OR REPLACE FUNCTION staging.load_retailer_data_pp(value json, load_id integer DEFAULT NULL) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    dd_date        date;
    dd_date_id     integer;
    dd_retailer    retailers;
    dd_load_status text = 'completed';
BEGIN

    dd_date := value #> '{products,0,date}';

    IF JSON_TYPEOF(value #> '{retailer}') != 'object' THEN
        RAISE NOTICE 'no retailer data: %   %', value #>> '{retailer}', value #>> '{products,0,ean}';
        RETURN;
    END IF;

    SELECT *
    INTO dd_retailer
    FROM JSON_POPULATE_RECORD(NULL::retailers,
                              value #> '{retailer}') AS retailer;

    INSERT INTO dates (date, "createdAt", "updatedAt")
    VALUES (dd_date AT TIME ZONE 'UTC', NOW(), NOW())
    ON CONFLICT (date)
        -- WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
        DO UPDATE
        SET "updatedAt"=NOW()
    RETURNING id
        INTO dd_date_id;

    DROP TABLE IF EXISTS last_product_status;
    CREATE TEMPORARY TABLE last_product_status ON COMMIT DROP AS
    SELECT DISTINCT ON ("coreProductId") "coreProductId",
                                         date,
                                         status,
                                         "productId"
    FROM staging.product_status_history
    WHERE "retailerId" = dd_retailer.id
      AND date < dd_date
    ORDER BY "coreProductId", date DESC;

    INSERT INTO staging.load(id, data,
                             flag,
                             dd_date,
                             dd_retailer,
                             dd_date_id,
                             load_status)
    SELECT load_retailer_data_pp.load_id,
           value,
           'create-products-pp' AS flag,
           dd_date,
           dd_retailer,
           dd_date_id,
           dd_load_status       AS load_status;

    DROP TABLE IF EXISTS tmp_product_pp_dd_products;
    CREATE TEMPORARY TABLE tmp_product_pp_dd_products ON COMMIT DROP AS
    WITH tmp_daily_data_pp AS (SELECT dd_date                                               AS date,
                                      product."countryCode",
                                      product."currency",
                                      product."sourceId",
                                      product.ean,
                                      product."brand",
                                      product."title",
                                      fn_to_float(product."shelfPrice")                     AS "shelfPrice",
                                      fn_to_float(product."wasPrice")                       AS "wasPrice",
                                      fn_to_float(product."cardPrice")                      AS "cardPrice",
                                      fn_to_boolean(product."inStock")                      AS "inStock",
                                      fn_to_boolean(product."onPromo")                      AS "onPromo",
                                      COALESCE(product."promoData",
                                               ARRAY []::staging.t_promotion_pp[])          AS "promoData",
                                      COALESCE(product."skuURL", '')                        AS href,
                                      product."imageURL",

                                      product."newCoreImage",
                                      COALESCE(fn_to_boolean(product."bundled"), FALSE)     AS "bundled",
                                      COALESCE(fn_to_boolean(product."masterSku"), FALSE)   AS "productOptions",
                                      LEFT(shop, 255)                                       AS shop,
                                      LEFT("amazonShop", 255)                               AS "amazonShop",
                                      LEFT(choice, 255)                                     AS choice,
                                      LEFT("amazonChoice", 255)                             AS "amazonChoice",
                                      "lowStock",
                                      LEFT("sellParty", 255)                                AS "sellParty",
                                      LEFT("amazonSellParty", 255)                          AS "amazonSellParty",
                                      LEFT(sell, 255)                                       AS sell,
                                      LEFT("fulfilParty", 255)                              AS "fulfilParty",
                                      LEFT("amazonFulfilParty", 255)                        AS "amazonFulfilParty",
                                      LEFT("amazonSell", 255)                               AS "amazonSell",
                                      marketplace,
                                      "marketplaceData",
                                      "priceMatchDescription",
                                      "priceMatch",
                                      "priceLock",
                                      "isNpd",
                                      LEFT(product.size, 255)                               AS size,
                                      LEFT("sizeUnit", 255)                                 AS "sizeUnit",
                                      LEFT("pricePerWeight", 255)                           AS "pricePerWeight",


                                      "reviewsCount"::integer                               AS "reviewsCount",
                                      fn_to_float("reviewsStars")                           AS "reviewsStars",

                                      ROW_NUMBER()
                                      OVER (PARTITION BY "sourceId" ORDER BY "skuURL" DESC) AS rownum -- use only the first sourceId record
                               FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                            value #> '{products}') AS product)
    SELECT COALESCE("wasPrice", "shelfPrice")        AS "originalPrice",
           "shelfPrice"                              AS "productPrice",
           "shelfPrice",
           COALESCE("brand", '')                     AS "productBrand",


           COALESCE("title", '')                     AS "productTitle",
           COALESCE("imageURL", '')                  AS "productImage",
           COALESCE("newCoreImage", '')              AS "newCoreImage",

           COALESCE("inStock", TRUE)                 AS "productInStock",

           date,
           "countryCode",
           "currency",
           CASE WHEN ean = '' THEN NULL ELSE ean END AS ean,
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
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd",
           size,
           "sizeUnit",
           "pricePerWeight",

           "reviewsCount",
           "reviewsStars",

           ROW_NUMBER() OVER ()                      AS index
    FROM tmp_daily_data_pp
    WHERE rownum = 1;

    DROP TABLE IF EXISTS tmp_product_pp;
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
        prod_barcode AS (SELECT barcode, "coreProductId" FROM "coreProductBarcodes"),
        prod_core AS (SELECT ean, id AS "coreProductId" FROM "coreProducts"),
        prod_retailersource AS (SELECT "sourceId", "coreProductId"
                                FROM "coreRetailerSources"
                                         INNER JOIN "coreRetailers"
                                                    ON (
                                                        "coreRetailers"."retailerId" = dd_retailer.id AND
                                                        "coreRetailerSources"."coreRetailerId" = "coreRetailers".id
                                                        ))

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
           dd_products."newCoreImage",

           FALSE                                                               AS "secondaryImages",
           ''                                                                  AS "productDescription",
           ''                                                                  AS "productInfo",
           dd_products."originalPrice"                                         AS "promotedPrice",
           dd_products."productInStock",
           TRUE                                                                AS "productInListing",

           dd_products."reviewsCount",
           dd_products."reviewsStars",

           NULL                                                                AS "eposId",
           COALESCE(trsf_promo.is_multibuy, FALSE)                             AS multibuy,
           COALESCE(prod_barcode."coreProductId",
                    prod_core."coreProductId",
                    prod_retailersource."coreProductId")                       AS "coreProductId",
           dd_retailer.id                                                      AS "retailerId",
           NOW()                                                               AS "createdAt",
           NOW()                                                               AS "updatedAt",
           NULL                                                                AS "imageId",
           dd_products.size,
           dd_products.href,
           ''                                                                  AS nutritional,
           dd_products."originalPrice"                                         AS "basePrice",
           dd_products."originalPrice"                                         AS "shelfPrice",
           dd_products."productTitle"                                          AS "productTitleDetail",
           dd_products."sizeUnit",
           dd_date_id                                                          AS "dateId",

           dd_products."countryCode",
           dd_products."currency",
           dd_products."cardPrice",
           dd_products."onPromo",
           dd_products."bundled",
           dd_products."originalPrice",
           dd_products."productPrice",
           'Newly'                                                             AS status,
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
           dd_products.marketplace,
           dd_products."marketplaceData",
           dd_products."priceMatchDescription",
           dd_products."priceMatch",
           dd_products."priceLock",
           TRUE                                                                AS "isNpd",
           checkEAN."eanIssues",
           ''                                                                  AS screenshot,
           prod_brand."brandId",
           trsf_ean."EANs",
           COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion_mb[]) AS promotions,
           dd_products."pricePerWeight",
           load_retailer_data_pp.load_id                                       AS load_id
    FROM tmp_product_pp_dd_products AS dd_products
             CROSS JOIN LATERAL ( SELECT CASE
                                             /*
                                                 Matt (5/13/2024) :https://brand-nudge-group.slack.com/archives/C068Y51TS6L/p1715604955904309?thread_ts=1715603977.153229&cid=C068Y51TS6L
                                                 if ean is NULL or “” then we will send either <sourceId> as <ean> or <retailer>_<sourceId> as <ean>.
                                             */
                                             WHEN dd_products.ean IS NULL THEN ARRAY [dd_products."sourceId"]:: TEXT[]
                                             WHEN
                                                 dd_products."productOptions"
                                                 THEN ARRAY [ dd_retailer.name || '_' || dd_products."sourceId"] :: TEXT[]
                                             ELSE
                                                 STRING_TO_ARRAY(dd_products.ean, ',') END AS "EANs"
        ) AS trsf_ean
             CROSS JOIN LATERAL ( SELECT trsf_ean."EANs"[1]         AS ean,
                                         CASE
                                             WHEN dd_products.ean IS NULL THEN TRUE
                                             ELSE
                                                 COALESCE(trsf_ean."EANs"[1] !~
                                                          '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$',
                                                          TRUE) END AS "eanIssues"
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
             LEFT OUTER JOIN prod_brand USING ("productBrand")
             LEFT OUTER JOIN prod_barcode ON (prod_barcode.barcode = checkEAN.ean)
             LEFT OUTER JOIN prod_core ON (prod_core.ean = checkEAN.ean)
             LEFT OUTER JOIN prod_retailersource USING ("sourceId");


    /*  createCoreBy    */
    WITH coreProductData AS (SELECT ean,
                                    "productTitle"                       AS title,
                                    "newCoreImage"                       AS image,
                                    "brandId",
                                    bundled,
                                    "secondaryImages",
                                    "productDescription"                 AS description,
                                    features,
                                    "productInfo"                        AS ingredients,
                                    LEFT(size, 255)                      AS size,
                                    nutritional                          AS specification,
                                    COALESCE("productOptions", FALSE)    AS "productOptions",
                                    "eanIssues",
                                    ROW_NUMBER() OVER (PARTITION BY ean) AS row_num
                             FROM tmp_product_pp
                             WHERE "coreProductId" IS NULL),
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
                                      "productOptions",
                                      load_id)
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
                            "productOptions",
                            load_retailer_data_pp.load_id
                     FROM coreProductData
                     WHERE row_num = 1
                     ON CONFLICT (ean) DO UPDATE
                         SET disabled = FALSE,
                             "productOptions" = excluded."productOptions",
                             "updatedAt" = excluded."updatedAt"
                     RETURNING "coreProducts".*),
         debug_ins_coreProducts AS (
             INSERT INTO staging.debug_coreProducts
                 SELECT * FROM ins_coreProducts),
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
                                                                         reviewed, load_id)
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
                    reviewed,
                    load_retailer_data_pp.load_id
             --"ownLabelManufacturerId",
             --"brandbankManaged"
             FROM ins_coreProducts
             --WHERE "updatedAt" != "createdAt"
             WHERE "updatedAt" >= NOW()::date
             ON CONFLICT ("coreProductId", "countryId")
                 WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
                 DO UPDATE
                     SET "updatedAt" = excluded."updatedAt"
             RETURNING "coreProductCountryData".*),
         debug_ins_coreProductCountryData AS (
             INSERT INTO staging.debug_coreProductCountryData
                 SELECT * FROM ins_prod_country_data),
         ins_coreProductBarcodes AS (
             INSERT
                 INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt", load_id)
                     SELECT id, ean, NOW(), NOW(), load_retailer_data_pp.load_id
                     FROM ins_coreProducts
                     WHERE "updatedAt" >= NOW()::date
                     ON CONFLICT (barcode)
                         DO UPDATE
                             SET "updatedAt" = excluded."updatedAt"
                     RETURNING "coreProductBarcodes".*),
         debug_ins_coreProductBarcodes AS (
             INSERT INTO staging.debug_coreProductBarcodes
                 SELECT * FROM ins_coreProductBarcodes)
    UPDATE tmp_product_pp
    SET "coreProductId"=ins_coreProducts.id
    FROM ins_coreProducts
    WHERE tmp_product_pp.ean = ins_coreProducts.ean;

    WITH ins_coreProductBarcodes AS (
        INSERT
            INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt", load_id)
                SELECT "coreProductId", ean, NOW(), NOW(), load_retailer_data_pp.load_id
                FROM tmp_product_pp
                ON CONFLICT (barcode)
                    DO NOTHING
                RETURNING "coreProductBarcodes".*)
    INSERT
    INTO staging.debug_coreProductBarcodes
    SELECT *
    FROM ins_coreProductBarcodes;


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
                                  "coreProductId",
                                  promo_indx,
                                  lat_dates."startDate",
                                  lat_dates."endDate",

                                  "promotedPrice",
                                  "shelfPrice",
                                  "productPrice",

                                  lat_promo_id."promoId",
                                  promo.description,
                                  promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.
                                  promo."multibuyPrice"                                AS "multibuyPrice",

                                  COALESCE(ret_promo."retailerPromotionId",
                                           default_ret_promo."retailerPromotionId")    AS "retailerPromotionId",
                                  COALESCE(ret_promo.regexp, default_ret_promo.regexp) AS regexp,
                                  COALESCE(ret_promo."promotionMechanicId",
                                           default_ret_promo."promotionMechanicId")    AS "promotionMechanicId",
                                  COALESCE(
                                          ret_promo."promotionMechanicName",
                                          default_ret_promo."promotionMechanicName")   AS "promotionMechanicName",
                                  ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx ORDER BY
                                      LOWER(ret_promo."promotionMechanicName") =
                                      COALESCE(promo.mechanic, '') DESC)               AS rownum
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
                                                               COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates_base
                                    CROSS JOIN LATERAL (SELECT DATE_PART('month', lat_dates_base."startDate"::date) ||
                                                               '/' ||
                                                               DATE_PART('day', lat_dates_base."startDate"::date) ||
                                                               '/' ||
                                                               DATE_PART('year', lat_dates_base."startDate"::date) AS "startDate",

                                                               DATE_PART('month', lat_dates_base."endDate"::date) ||
                                                               '/' ||
                                                               DATE_PART('day', lat_dates_base."endDate"::date) ||
                                                               '/' ||
                                                               DATE_PART('year', lat_dates_base."endDate"::date)   AS "endDate"

                               ) AS lat_dates
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
                                     "coreProductId",
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
                                                                                   calculateMultibuyPrice(
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
         prod_prev_promo AS (SELECT *
                             FROM last_product_status
                                      INNER JOIN promotions USING ("productId")),
         upd_product_promo AS (SELECT promo."sourceId",
                                      MAX(promo."promotedPrice") FILTER (WHERE promo.promo_price_order = 1) AS "promotedPrice",
                                      MAX(promo."shelfPrice") FILTER (WHERE promo.promo_price_order = 1)    AS "shelfPrice",
                                      ARRAY_AGG((COALESCE(prev_promo."promoId", promo."promoId"),
                                                 promo."retailerPromotionId",
                                                 COALESCE(prev_promo."startDate", promo."startDate"),
                                                 promo."endDate",
                                                 promo.description,
                                                 promo."promotionMechanicName",
                                                 promo."multibuyPrice")::staging.t_promotion_mb
                                                ORDER BY promo.promo_indx)                                  AS promotions
                               FROM promo_price_calc AS promo
                                        LEFT OUTER JOIN prod_prev_promo AS prev_promo
                                                        ON (prev_promo."coreProductId" = promo."coreProductId" AND
                                                            prev_promo.description = promo.description)
                               GROUP BY 1)
    UPDATE tmp_product_pp
    SET promotions      = upd_product_promo.promotions,
        "promotedPrice" = upd_product_promo."promotedPrice",
        "shelfPrice"    = upd_product_promo."shelfPrice"
    FROM upd_product_promo
    WHERE tmp_product_pp."sourceId" = upd_product_promo."sourceId";

    UPDATE tmp_product_pp
    SET status=CASE
                   WHEN dd_date = last_product_status.date + '1 day'::interval AND
                        last_product_status.status != 'De-listed' THEN 'Listed'
                   ELSE 'Re-listed'
        END,
        "isNpd"= FALSE
    FROM last_product_status
    WHERE last_product_status."coreProductId" = tmp_product_pp."coreProductId";

    WITH delisted_ids AS (SELECT last_product_status."productId" AS id
                          FROM last_product_status
                                   LEFT OUTER JOIN tmp_product_pp USING ("coreProductId")
                          WHERE tmp_product_pp."coreProductId" IS NULL
                            AND last_product_status.status != 'De-listed'),
         delisted_product AS (SELECT *
                              FROM products
                                       INNER JOIN delisted_ids USING (id)
                                       LEFT OUTER JOIN (SELECT "sourceId" FROM tmp_product_pp) AS listed_products
                                                       USING ("sourceId")
                              WHERE listed_products."sourceId" IS NULL)
    INSERT
    INTO tmp_product_pp ("sourceType",
                         ean,
        -- promotions,
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
        -- "promotedPrice",
                         "productInStock",
                         "productInListing",
        -- "reviewsCount",
        -- "reviewsStars",
                         "eposId",
                         multibuy,
                         "coreProductId",
                         "retailerId",
                         "createdAt",
                         "updatedAt",
                         "imageId",
                         size,
                         "pricePerWeight",
                         href,
                         nutritional,
        --"basePrice",
        --"shelfPrice",
                         "productTitleDetail",
                         "sizeUnit",
                         "dateId",
                         marketplace,
                         "marketplaceData",
                         "priceMatchDescription",
                         "priceMatch",
                         "priceLock",
                         "isNpd",
                         load_id,
                         status)
    SELECT "sourceType",
           ean,
           --promotions,
           "promotionDescription",
           features,
           dd_date                       AS "date",
           "sourceId",
           "productBrand",
           "productTitle",
           "productImage",
           "secondaryImages",
           "productDescription",
           "productInfo",
           --"promotedPrice",
           "productInStock",
           "productInListing",
           --"reviewsCount",
           --"reviewsStars",
           "eposId",
           multibuy,
           "coreProductId",
           "retailerId",
           "createdAt",
           "updatedAt",
           "imageId",
           size,
           "pricePerWeight",
           href,
           nutritional,
           --"basePrice",
           --"shelfPrice",
           "productTitleDetail",
           "sizeUnit",
           dd_date_id                    AS "dateId",
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           FALSE                         AS "isNpd",
           load_retailer_data_pp.load_id AS load_id,
           'De-listed'                   AS status
    FROM delisted_product;

    WITH tmp_product_src_part AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY "sourceId" ) AS rownum
                                  FROM tmp_product_pp),
         deleted AS (
             DELETE
                 FROM tmp_product_pp USING tmp_product_src_part
                     WHERE tmp_product_pp."coreProductId" = tmp_product_src_part."coreProductId"
                         AND tmp_product_src_part.rownum > 1
                     RETURNING tmp_product_pp.*),
         ins_removed AS (
             INSERT
                 INTO staging.debug_tmp_product_pp_removed (load_id,
                                                            id,
                                                            "sourceType",
                                                            ean,
                                                            "promotionDescription",
                                                            features,
                                                            DATE,
                                                            "sourceId",
                                                            "productBrand",
                                                            "productTitle",
                                                            "productImage",
                                                            "newCoreImage",
                                                            "secondaryImages",
                                                            "productDescription",
                                                            "productInfo",
                                                            "promotedPrice",
                                                            "productInStock",
                                                            "productInListing",
                                                            "reviewsCount",
                                                            "reviewsStars",
                                                            "eposId",
                                                            multibuy,
                                                            "coreProductId",
                                                            "retailerId",
                                                            "createdAt",
                                                            "updatedAt",
                                                            "imageId",
                                                            size,
                                                            "pricePerWeight",
                                                            href,
                                                            nutritional,
                                                            "basePrice",
                                                            "shelfPrice",
                                                            "productTitleDetail",
                                                            "sizeUnit",
                                                            "dateId",
                                                            "countryCode",
                                                            currency,
                                                            "cardPrice",
                                                            "onPromo",
                                                            bundled,
                                                            "originalPrice",
                                                            "productPrice",
                                                            status,
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
                                                            "amazonSell",
                                                            marketplace,
                                                            "marketplaceData",
                                                            "priceMatchDescription",
                                                            "priceMatch",
                                                            "priceLock",
                                                            "isNpd",
                                                            "eanIssues",
                                                            screenshot,
                                                            "brandId",
                                                            "EANs",
                                                            promotions)
                     SELECT load_retailer_data_pp.load_id,
                            id,
                            "sourceType",
                            ean,
                            "promotionDescription",
                            features,
                            DATE,
                            "sourceId",
                            "productBrand",
                            "productTitle",
                            "productImage",
                            "newCoreImage",
                            "secondaryImages",
                            "productDescription",
                            "productInfo",
                            "promotedPrice",
                            "productInStock",
                            "productInListing",
                            "reviewsCount",
                            "reviewsStars",
                            "eposId",
                            multibuy,
                            "coreProductId",
                            "retailerId",
                            "createdAt",
                            "updatedAt",
                            "imageId",
                            size,
                            "pricePerWeight",
                            href,
                            nutritional,
                            "basePrice",
                            "shelfPrice",
                            "productTitleDetail",
                            "sizeUnit",
                            "dateId",
                            "countryCode",
                            currency,
                            "cardPrice",
                            "onPromo",
                            bundled,
                            "originalPrice",
                            "productPrice",
                            status,
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
                            "amazonSell",
                            marketplace,
                            "marketplaceData",
                            "priceMatchDescription",
                            "priceMatch",
                            "priceLock",
                            "isNpd",
                            "eanIssues",
                            screenshot,
                            "brandId",
                            "EANs",
                            promotions
                     FROM deleted
                     RETURNING debug_tmp_product_pp_removed.*)
    SELECT CASE WHEN COUNT(*) != 0 THEN 'partially loaded. removed ' || COUNT(*) || ' product records.' END
    INTO dd_load_status
    FROM ins_removed;

    IF dd_load_status != 'completed' THEN
        UPDATE staging.load
        SET load_status=dd_load_status
        WHERE id = load_retailer_data_pp.load_id;
    END IF;

    /*  createProductBy    */
    WITH ins_products AS (
        INSERT INTO products ("sourceType",
                              ean,
                              promotions,
                              "promotionDescription",
                              features,
                              DATE,
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
                              "dateId",
                              marketplace,
                              "marketplaceData",
                              "priceMatchDescription",
                              "priceMatch",
                              "priceLock",
                              "isNpd",
                              load_id)
            SELECT "sourceType",
                   ean,
                   COALESCE(ARRAY_LENGTH(promotions, 1) > 0, FALSE) AS promotions,
                   "promotionDescription",
                   features,
                   DATE,
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
                   "dateId",
                   marketplace,
                   "marketplaceData",
                   "priceMatchDescription",
                   "priceMatch",
                   "priceLock",
                   "isNpd",
                   load_retailer_data_pp.load_id
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
                                                    WHEN "sourceType" = 'ocado' THEN REPLACE(REPLACE(
                                                                                                     "productImage",
                                                                                                     'https://ocado.com',
                                                                                                     'https://www.ocado.com'),
                                                                                             'https://www.ocado.comhttps://www.ocado.com',
                                                                                             'https://www.ocado.com')
                                                    WHEN "sourceType" = 'morrisons' THEN
                                                        REPLACE("productImage",
                                                                'https://groceries.morrisons.comhttps://groceries.morrisons.com',
                                                                'https://groceries.morrisons.com')
                                                    ELSE "productImage"
                                                    END AS "productImage"
                ) AS new_img
            ON CONFLICT ("sourceId", "retailerId", "dateId")
                WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
                DO UPDATE
                    SET "updatedAt" = excluded."updatedAt",
                        "productInStock" = excluded."productInStock",
                        "productBrand" = excluded."productBrand",
                        "reviewsCount" = excluded."reviewsCount",
                        "reviewsStars" = excluded."reviewsStars",
                        load_id = excluded.load_id
            RETURNING products.*),
         debug_ins_products AS (
             INSERT INTO staging.debug_products
                 SELECT * FROM ins_products)
    UPDATE tmp_product_pp
    SET id=ins_products.id
    FROM ins_products
    WHERE tmp_product_pp."sourceId" = ins_products."sourceId"
      AND tmp_product_pp."retailerId" = ins_products."retailerId"
      AND tmp_product_pp."dateId" = ins_products."dateId";


    INSERT INTO staging.product_status_history("retailerId", "coreProductId", DATE, "productId", status)
    --SELECT "retailerId", "coreProductId", date, id AS "productId", status
    SELECT "retailerId", "coreProductId", DATE, MAX(id) AS "productId", status
    FROM tmp_product_pp
    GROUP BY "retailerId", "coreProductId", DATE, status
    ON CONFLICT ("retailerId", "coreProductId", DATE)
        DO UPDATE
        SET status=excluded.status;

    INSERT INTO staging.debug_tmp_product_pp (load_id,
                                              id,
                                              "sourceType",
                                              ean,
                                              "promotionDescription",
                                              features,
                                              DATE,
                                              "sourceId",
                                              "productBrand",
                                              "productTitle",
                                              "productImage",
                                              "newCoreImage",
                                              "secondaryImages",
                                              "productDescription",
                                              "productInfo",
                                              "promotedPrice",
                                              "productInStock",
                                              "productInListing",
                                              "reviewsCount",
                                              "reviewsStars",
                                              "eposId",
                                              multibuy,
                                              "coreProductId",
                                              "retailerId",
                                              "createdAt",
                                              "updatedAt",
                                              "imageId",
                                              size,
                                              "pricePerWeight",
                                              href,
                                              nutritional,
                                              "basePrice",
                                              "shelfPrice",
                                              "productTitleDetail",
                                              "sizeUnit",
                                              "dateId",
                                              "countryCode",
                                              currency,
                                              "cardPrice",
                                              "onPromo",
                                              bundled,
                                              "originalPrice",
                                              "productPrice",
                                              status,
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
                                              "amazonSell",
                                              marketplace,
                                              "marketplaceData",
                                              "priceMatchDescription",
                                              "priceMatch",
                                              "priceLock",
                                              "isNpd",
                                              "eanIssues",
                                              screenshot,
                                              "brandId",
                                              "EANs",
                                              promotions)
    SELECT load_retailer_data_pp.load_id,
           id,
           "sourceType",
           ean,
           "promotionDescription",
           features,
           DATE,
           "sourceId",
           "productBrand",
           "productTitle",
           "productImage",
           "newCoreImage",
           "secondaryImages",
           "productDescription",
           "productInfo",
           "promotedPrice",
           "productInStock",
           "productInListing",
           "reviewsCount",
           "reviewsStars",
           "eposId",
           multibuy,
           "coreProductId",
           "retailerId",
           "createdAt",
           "updatedAt",
           "imageId",
           size,
           "pricePerWeight",
           href,
           nutritional,
           "basePrice",
           "shelfPrice",
           "productTitleDetail",
           "sizeUnit",
           "dateId",
           "countryCode",
           currency,
           "cardPrice",
           "onPromo",
           bundled,
           "originalPrice",
           "productPrice",
           status,
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
           "amazonSell",
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd",
           "eanIssues",
           screenshot,
           "brandId",
           "EANs",
           promotions
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
                                                         "updatedAt", load_id)
        SELECT id                                                                         AS "productId",
               COALESCE(COALESCE(product."amazonShop", product.shop), '')                 AS shop,
               COALESCE(COALESCE(product."amazonChoice", product.choice), '')             AS choice,
               COALESCE(product."lowStock", FALSE)                                        AS "lowStock",
               COALESCE(COALESCE(product."amazonSellParty", product."sellParty"), '')     AS "sellParty",
               COALESCE(COALESCE(product."amazonSell", product."sell"), '')               AS "sell",
               COALESCE(COALESCE(product."amazonFulfilParty", product."fulfilParty"), '') AS "fulfilParty",
               NOW(),
               NOW(),
               load_retailer_data_pp.load_id
        FROM tmp_product_pp AS product
        WHERE LOWER("sourceType") LIKE '%amazon%'
        RETURNING "amazonProducts".*)
    INSERT
    INTO staging.debug_amazonproducts
    SELECT *
    FROM debug_ins_amz;


    /*  setCoreRetailer */
    DROP TABLE IF EXISTS tmp_coreRetailer;
    CREATE TEMPORARY TABLE tmp_coreRetailer ON COMMIT DROP AS
    WITH ins_coreRetailers AS (
        INSERT INTO "coreRetailers" ("coreProductId",
                                     "retailerId",
                                     "createdAt",
                                     "updatedAt", load_id)
            SELECT DISTINCT product."coreProductId",
                            dd_retailer.id,
                            NOW() AS "createdAt",
                            NOW() AS "updatedAt",
                            load_retailer_data_pp.load_id
            FROM tmp_product_pp AS product
            ON CONFLICT ("coreProductId",
                "retailerId") DO UPDATE SET "updatedAt" = excluded."updatedAt"
            RETURNING "coreRetailers".*)
    SELECT DISTINCT ins_coreRetailers.id,
                    "coreProductId",
                    ins_coreRetailers."retailerId",
                    product."sourceId",
                    ins_coreRetailers."createdAt",
                    ins_coreRetailers."updatedAt"
    FROM ins_coreRetailers
             INNER JOIN tmp_product_pp AS product USING ("coreProductId");

    INSERT
    INTO staging.debug_coreRetailers (load_id, "sourceId", id, "coreProductId", "retailerId", "createdAt",
                                      "updatedAt")
    SELECT load_retailer_data_pp.load_id, "sourceId", id, "coreProductId", "retailerId", "createdAt", "updatedAt"
    FROM tmp_coreRetailer;


    /*  coreRetailerSources */
    INSERT INTO "coreRetailerSources"("coreRetailerId", "retailerId", "sourceId", "createdAt", "updatedAt", load_id)
    SELECT id, "retailerId", "sourceId", "createdAt", "updatedAt", load_retailer_data_pp.load_id
    FROM tmp_coreRetailer
    ON CONFLICT DO NOTHING;


    /*  saveProductStatus   */
    WITH debug_productStatuses AS ( INSERT INTO "productStatuses" ("productId",
                                                                   status,
                                                                   screenshot,
                                                                   "createdAt",
                                                                   "updatedAt", load_id)
        SELECT id AS "productId",
               status,
               screenshot,
               NOW(),
               NOW(),
               load_retailer_data_pp.load_id
        FROM tmp_product_pp
        ON CONFLICT ("productId")
            DO UPDATE
                SET status = excluded.status
        RETURNING "productStatuses".*)
    INSERT
    INTO staging.debug_productStatuses
    SELECT *
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
                                "promoId", load_id)
            SELECT DISTINCT "retailerPromotionId",
                            id    AS "productId",
                            description,
                            "startDate",
                            "endDate",
                            NOW() AS "createdAt",
                            NOW() AS "updatedAt",
                            "promoId",
                            load_retailer_data_pp.load_id
            FROM tmp_product_pp
                     CROSS JOIN LATERAL UNNEST(promotions) AS promo
            ON CONFLICT ("productId", "promoId", "retailerPromotionId", "description", "startDate", "endDate")
                WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
                DO
                    UPDATE
                    SET "updatedAt" = excluded."updatedAt"
            RETURNING promotions.*)
    INSERT
    INTO staging.debug_promotions
    SELECT *
    FROM debug_ins_promotions;

    /*  aggregatedProducts  */
    WITH debug_ins_aggregatedProducts AS (
        INSERT INTO "aggregatedProducts" ("titleMatch",
                                          "productId",
                                          "createdAt",
                                          "updatedAt", load_id
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
            SELECT compareTwoStrings("titleParent", "productTitle") AS "titleMatch",
                   id                                               AS "productId",
                   NOW()                                            AS "createdAt",
                   NOW()                                               "updatedAt",
                   load_retailer_data_pp.load_id
            FROM tmp_product_pp
                     INNER JOIN (SELECT "coreProductId", title AS "titleParent"
                                 FROM "coreProductCountryData"
                                 WHERE "countryId" = dd_retailer."countryId") AS parentProdCountryData
                                USING ("coreProductId")
            ON CONFLICT ("productId")
                WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
                DO NOTHING
            RETURNING "aggregatedProducts".*)
    INSERT
    INTO staging.debug_aggregatedProducts
    SELECT *
    FROM debug_ins_aggregatedProducts;

    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  coreRetailerDates */
    WITH debug_coreRetailerDates AS ( INSERT INTO "coreRetailerDates" ("coreRetailerId",
                                                                       "dateId",
                                                                       "createdAt",
                                                                       "updatedAt", load_id)
        SELECT tmp_coreRetailer.id AS "coreRetailerId",
               dd_date_id          AS "dateId",
               NOW(),
               NOW(),
               load_retailer_data_pp.load_id
        FROM tmp_coreRetailer
        ON CONFLICT ("coreRetailerId",
            "dateId")
            DO NOTHING
        RETURNING "coreRetailerDates".*)
    INSERT
    INTO staging.debug_coreRetailerDates
    SELECT *
    FROM debug_coreRetailerDates;

    RETURN;
END;
$$;
