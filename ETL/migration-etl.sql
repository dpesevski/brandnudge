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

/*  remove ranking from PP as it is not applicable    */
ALTER TABLE staging.debug_tmp_product_pp
    DROP COLUMN dd_ranking;

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

DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;

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
    "isNpd"                 boolean
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

DROP TABLE IF EXISTS staging.product_status;
CREATE TABLE staging.product_status AS
WITH retailer_latest_load AS (SELECT "retailerId", MAX(date) AS date
                              FROM products
                              GROUP BY 1),
     past_product_records AS (SELECT "retailerId",
                                     "sourceId",
                                     id                                                                  AS "productId",
                                     date,
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "retailerId", "sourceId" ORDER BY "dateId" DESC) AS rownum
                              FROM products),
     latest AS (SELECT "retailerId", "sourceId", "productId", date
                FROM past_product_records
                WHERE rownum = 1),
     prev AS (SELECT "retailerId", "sourceId", "productId", date
              FROM past_product_records
              WHERE rownum = 2)
SELECT "retailerId",
       "sourceId",
       latest."productId",
       latest.date,
       CASE
           WHEN latest.date < retailer_latest_load.date THEN 'De-listead'
           WHEN prev.date IS NULL THEN 'Newly'
           WHEN prev.date < latest.date - '1 day'::interval THEN 'Re-Listed'
           ELSE 'Listed'
           END AS status
FROM latest
         INNER JOIN retailer_latest_load USING ("retailerId")
         LEFT OUTER JOIN prev USING ("retailerId", "sourceId");

DROP TABLE IF EXISTS staging.products_last;
CREATE TABLE staging.products_last AS
WITH past_product_records AS (SELECT "retailerId",
                                     "sourceId",
                                     id                                                                  AS "productId",
                                     date,
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "retailerId", "sourceId" ORDER BY "dateId" DESC) AS rownum
                              FROM products)
SELECT "retailerId", "sourceId", "productId", date
FROM past_product_records
WHERE rownum = 1;


ALTER TABLE staging.products_last
    ADD CONSTRAINT products_last_pk
        PRIMARY KEY ("retailerId", "sourceId");

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
    IF flag = 'create-products' THEN

        IF JSON_TYPEOF(fetched_data) = 'array' THEN
            RAISE EXCEPTION 'old create-products structure, with no retailer object';
        ELSE
            PERFORM staging.load_retailer_data_base(fetched_data, _load_id);
        END IF;


    ELSEIF flag = 'create-products-pp' THEN
        PERFORM staging.load_retailer_data_pp(fetched_data, _load_id);
    ELSE
        RAISE EXCEPTION 'no flag provided';
    END IF;

    UPDATE staging.load
    SET execution_time=1000 * (EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) - EXTRACT(EPOCH FROM _start_ts))
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
    dd_date                    date;
    dd_date_id                 integer;
    dd_retailer                retailers;
    dd_retailer_last_load_date date;
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

    SELECT MAX(date) AS dd_retailer_last_load_date
    FROM staging.products_last
    WHERE "retailerId" = dd_retailer.id;

    INSERT INTO staging.load(id, data,
                             flag,
                             dd_date,
                             dd_retailer,
                             dd_date_id)
    SELECT load_retailer_data_pp.load_id,
           value,
           'create-products-pp' AS flag,
           dd_date,
           dd_retailer,
           dd_date_id;
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
                                                        )),

        tmp_daily_data_pp AS (SELECT dd_date                                               AS date,
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
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "sourceId" ORDER BY "skuURL" DESC) AS rownum -- use only the first sourceId record
                              FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                           value #> '{products}') AS product),
        dd_products AS (SELECT COALESCE("wasPrice", "shelfPrice")        AS "originalPrice",
                               "shelfPrice"                              AS "productPrice",
                               "shelfPrice",
                               COALESCE("brand", '')                     AS "productBrand",

                               lat_product_statuses.status,

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
                               ROW_NUMBER() OVER ()                      AS index
                        FROM tmp_daily_data_pp
                                 LEFT OUTER JOIN staging.products_last
                                                 ON (products_last."retailerId" = dd_retailer.id AND
                                                     products_last."sourceId" = tmp_daily_data_pp."sourceId")
                                 CROSS JOIN LATERAL (SELECT CASE
                                                                WHEN dd_date <= dd_retailer_last_load_date THEN
                                                                    'Listed' -- ? Re-loaded. Should take in consideration past records and additionally update also the future records.
                                                                WHEN products_last.date IS NULL THEN 'Newly'
                                                                WHEN date - products_last.date = '1 day' THEN 'Listed'
                                                                ELSE 'Re-listed'
                                                                END AS status
                            ) AS lat_product_statuses

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
           dd_products."newCoreImage",

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
           COALESCE(prod_barcode."coreProductId",
                    prod_core."coreProductId",
                    prod_retailersource."coreProductId")                       AS "coreProductId",
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
           dd_products.marketplace,
           dd_products."marketplaceData",
           dd_products."priceMatchDescription",
           dd_products."priceMatch",
           dd_products."priceLock",
           dd_products."isNpd",
           checkEAN."eanIssues",
           ''                                                                  AS screenshot,
           prod_brand."brandId",
           trsf_ean."EANs",
           COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion_mb[]) AS promotions

    FROM dd_products
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
                             FROM staging.products_last
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
                                                        ON (prev_promo."sourceId" = promo."sourceId" AND
                                                            prev_promo."retailerId" = dd_retailer.id AND
                                                            prev_promo.description = promo.description)
                               GROUP BY 1)
    UPDATE tmp_product_pp
    SET promotions      = upd_product_promo.promotions,
        "promotedPrice" = upd_product_promo."promotedPrice",
        "shelfPrice"    = upd_product_promo."shelfPrice"
    FROM upd_product_promo
    WHERE tmp_product_pp."sourceId" = upd_product_promo."sourceId";

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

    WITH delisted_ids AS (SELECT products_last."productId" AS id
                          FROM staging.products_last
                                   LEFT OUTER JOIN tmp_product_pp USING ("retailerId", "sourceId")
                          WHERE tmp_product_pp."retailerId" IS NULL
                            AND products_last.date = dd_date - '2 days'), /* Only select those which just got de-listed.
                                                                     The expression will select it only once.
                                                                     This would work if there are loads every day from the  retailer.
                                                                     Better add the status here and filter by !='De-listed'
                                                                      */
         delisted_product AS (SELECT *
                              FROM products
                                       INNER JOIN delisted_ids USING (id))
    INSERT
    INTO tmp_product_pp ("sourceType",
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
                         marketplace,
                         "marketplaceData",
                         "priceMatchDescription",
                         "priceMatch",
                         "priceLock",
                         "isNpd", status)
    SELECT "sourceType",
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
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd",
           'De-listed'
    FROM delisted_product;

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
                              "dateId",
                              marketplace,
                              "marketplaceData",
                              "priceMatchDescription",
                              "priceMatch",
                              "priceLock",
                              "isNpd", load_id)
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


    INSERT INTO staging.products_last ("retailerId", "sourceId", "productId", date)
    SELECT "retailerId", "sourceId", id AS "productId", date
    FROM tmp_product_pp
    WHERE status != 'De-listed'
    ON CONFLICT ("sourceId", "retailerId" )
        DO UPDATE
        SET "productId" = excluded."productId",
            date=excluded.date
    WHERE products_last.date <= excluded.date;

    INSERT INTO staging.debug_tmp_product_pp
    SELECT load_retailer_data_pp.load_id, *
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
            DO NOTHING
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


    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    RETURN;
END ;
$$;

DROP FUNCTION IF EXISTS staging.load_retailer_data_base(json, integer);
CREATE OR REPLACE FUNCTION staging.load_retailer_data_base(value json, load_id integer DEFAULT NULL) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    dd_date     date;
    dd_date_id  integer;
    dd_retailer retailers;
BEGIN

    IF JSON_TYPEOF(value #> '{retailer}') != 'object' THEN
        RAISE NOTICE 'no retailer data: %', value #>> '{retailer}';
        RETURN;
    END IF;

    IF JSON_TYPEOF(value #> '{products}') != 'array' THEN
        RAISE NOTICE 'no products data: %', value #>> '{products}';
        RETURN;
    END IF;

    SELECT *
    INTO dd_retailer
    FROM JSON_POPULATE_RECORD(NULL::retailers,
                              value #> '{retailer}') AS retailer;


    IF value #>> '{products}' = '[]' THEN
        INSERT INTO staging.load(id,
                                 data,
                                 flag)
        SELECT load_retailer_data_base.load_id,
               value,
               'create-products' AS flag;

        RETURN;
    END IF;

    dd_date := value #> '{products,0,date}';

    DROP TABLE IF EXISTS tmp_daily_data;
    CREATE TEMPORARY TABLE tmp_daily_data ON COMMIT DROP AS
    SELECT dd_retailer,
           ean,
           dd_date                        AS date,
           href,
           LEFT(product.size, 255)        AS size,
           "eposId",
           LEFT(status, 255)              AS status,--  check if status should be changed to type "text"
           bundled,
           category,
           featured,
           features,
           promotions,
           multibuy,
           LEFT("sizeUnit", 255)          AS "sizeUnit",
           "sourceId",
           "inTaxonomy",
           "isFeatured",
           LEFT("pageNumber", 255)        AS "pageNumber",
           screenshot,
           dd_retailer.name               AS "sourceType",
           "taxonomyId",
           nutritional,
           "productInfo",
           "productRank",
           "categoryType",
           "featuredRank",
           "productBrand",
           "productImage",
           "newCoreImage",
           fn_to_float("productPrice")    AS "productPrice",
           "productTitle",
           "reviewsCount",
           fn_to_float("reviewsStars")    AS "reviewsStars",
           fn_to_float("originalPrice")   AS "originalPrice",
           LEFT("pricePerWeight", 255)    AS "pricePerWeight",
           "productInStock",
           "secondaryImages",
           "productDescription",
           "productTitleDetail",
           "promotionDescription",
           "productOptions",

           LEFT(shop, 255)                AS shop,
           LEFT("amazonShop", 255)        AS "amazonShop",
           LEFT(choice, 255)              AS choice,
           LEFT("amazonChoice", 255)      AS "amazonChoice",
           "lowStock",
           LEFT("sellParty", 255)         AS "sellParty",
           LEFT("amazonSellParty", 255)   AS "amazonSellParty",
           LEFT(sell, 255)                AS sell,
           LEFT("fulfilParty", 255)       AS "fulfilParty",
           LEFT("amazonFulfilParty", 255) AS "amazonFulfilParty",
           LEFT("amazonSell", 255)        AS "amazonSell",
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd"


    FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data,
                                 value #> '{products}') AS product;
    /* value -> 'products' */

    /*  ProductService.getCreateProductCommonData  */
    /*  dates.findOrCreate  */
    /*  TO DO:  add UQ constraint on date   */

    INSERT INTO dates (date, "createdAt", "updatedAt")
    VALUES (dd_date AT TIME ZONE 'UTC', NOW(), NOW())
    ON CONFLICT (date)
        -- WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
        DO UPDATE
        SET "updatedAt"=NOW()
    RETURNING id INTO dd_date_id;

    INSERT INTO staging.load(id,
                             data,
                             flag,
                             dd_date,
                             dd_retailer,
                             dd_date_id,
                             dd_source_type)
    SELECT load_retailer_data_base.load_id,
           value,
           'create-products' AS flag,
           dd_date,
           dd_retailer,
           dd_date_id,
           dd_retailer.name;

    DROP TABLE IF EXISTS tmp_product;
    CREATE TEMPORARY TABLE tmp_product ON COMMIT DROP AS
    WITH prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
         prod_barcode AS (SELECT barcode, "coreProductId" FROM "coreProductBarcodes"),
         prod_core AS (SELECT ean, id AS "coreProductId" FROM "coreProducts"),
         prod_retailersource AS (SELECT "sourceId", "coreProductId"
                                 FROM "coreRetailerSources"
                                          INNER JOIN "coreRetailers"
                                                     ON ("coreRetailers"."retailerId" = dd_retailer.id AND
                                                         "coreRetailerSources"."coreRetailerId" = "coreRetailers".id)),

         daily_data AS (SELECT NULL::integer                                                                 AS id,
                               COALESCE(prod_barcode."coreProductId",
                                        prod_core."coreProductId",
                                        prod_retailersource."coreProductId")                                 AS "coreProductId",
                               NULL::integer                                                                 AS "parentCategory", -- TO DO

                               promotions,
                               "productPrice",
                               "originalPrice",
                               "originalPrice"                                                               AS "basePrice",
                               "originalPrice"                                                               AS "shelfPrice",
                               "originalPrice"                                                               AS "promotedPrice",
                               dd_retailer.id                                                                AS "retailerId",
                               dd_date_id                                                                    AS "dateId",
                               NOT (NOT featured)                                                            AS featured,
                               "bundled",
                               "category",
                               "categoryType",
                               "date",
                               tmp_daily_data."ean",
                               "eposId",
                               "featuredRank",
                               "features",
                               "href",
                               "inTaxonomy",
                               "isFeatured",
                               "multibuy",
                               "nutritional",
                               "pageNumber",
                               "pricePerWeight",
                               "productBrand",
                               "productDescription",
                               "productImage",
                               "newCoreImage",
                               "productInStock",
                               "productInfo",
                               "productRank",
                               "productTitle",
                               "productTitleDetail",
                               "reviewsCount",
                               "reviewsStars",
                               "screenshot",
                               "secondaryImages",
                               "size",
                               "sizeUnit",
                               "sourceId",
                               "sourceType",
                               COALESCE("taxonomyId", 0)                                                     AS "taxonomyId",
                               "brandId",
                               "productOptions",
                               checkEAN."eanIssues",
                               shop,
                               "amazonShop",
                               choice,
                               "amazonChoice",
                               "lowStock",
                               "sellParty",
                               "amazonSellParty",
                               "amazonSell",
                               marketplace,
                               "marketplaceData",
                               "priceMatchDescription",
                               "priceMatch",
                               "priceLock",
                               "isNpd",
                               sell,
                               "fulfilParty",
                               "amazonFulfilParty",
                               status,
                               ROW_NUMBER() OVER (PARTITION BY "sourceId" ORDER BY href DESC, features DESC) AS rownum
/*
TO DO
    if (
      product.sourceType === 'waitrose' &&
      !CompareUtil.checkEAN(product.ean)
    ) {
      const waitroseEAN = await ProductService.fetchWaitroseProductEAN(
        product.sourceId,
      );
      if (waitroseEAN) product.ean = waitroseEAN;
    }

*/
                        FROM tmp_daily_data
                                 LEFT OUTER JOIN prod_brand USING ("productBrand")
                                 LEFT OUTER JOIN prod_barcode ON (prod_barcode.barcode = tmp_daily_data.ean)
                                 LEFT OUTER JOIN prod_core ON (prod_core.ean = tmp_daily_data.ean)
                                 LEFT OUTER JOIN prod_retailersource USING ("sourceId")
                            /*  CompareUtil.checkEAN    */
                            -- strict === true then '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$'
                                 CROSS JOIN LATERAL ( SELECT tmp_daily_data.ean !~
                                                             '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$' AS "eanIssues"
                            ) AS checkEAN),
         ranking AS (SELECT "sourceId",
                            ARRAY_AGG(
                                    (NULL,
                                     NULL,
                                     category,
                                     "categoryType",
                                     "parentCategory",
                                     "productRank",
                                     "pageNumber",
                                     screenshot,
                                     featured,
                                     "featuredRank",
                                     "taxonomyId",
                                     load_retailer_data_base.load_id)::"productsData"
                            ) AS ranking_data
                     FROM daily_data
                     GROUP BY "sourceId")
    SELECT id,
           "coreProductId",
           promotions,
           "productPrice",
           "originalPrice",
           "basePrice",
           "shelfPrice",
           "promotedPrice",
           "retailerId",
           "dateId",
           featured,
           "bundled",
           "date",
           "ean",
           "eposId",
           "features",
           "href",
           "inTaxonomy",
           "isFeatured",
           "multibuy",
           "nutritional",
           "pricePerWeight",
           "productBrand",
           "productDescription",
           "productImage",
           "newCoreImage",
           "productInStock",
           "productInfo",
           "productTitle",
           "productTitleDetail",
           "reviewsCount",
           "reviewsStars",
           "secondaryImages",
           "size",
           "sizeUnit",
           "sourceId",
           "sourceType",
           "brandId",
           "productOptions",
           "eanIssues",
           shop,
           "amazonShop",
           choice,
           "amazonChoice",
           "lowStock",
           "sellParty",
           "amazonSellParty",
           "amazonSell",
           marketplace,
           "marketplaceData",
           "priceMatchDescription",
           "priceMatch",
           "priceLock",
           "isNpd",
           sell,
           "fulfilParty",
           "amazonFulfilParty",
           status,
           screenshot,
           ranking.ranking_data
    FROM daily_data
             INNER JOIN ranking USING ("sourceId")
    WHERE rownum = 1;

    UPDATE tmp_product
    SET status='re-listed'
    WHERE status = 'newly'
      AND NOT EXISTS (SELECT * FROM products WHERE "sourceId" = tmp_product."sourceId");

    /*  prepare products' promotions data   */
    /*  promotions - multibuy price calc  (not as in the order in createProducts) */
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
                                  "sourceType",

                                  lat_promo_id."promoId",
                                  promo.description,
                                  promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.


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
                           FROM tmp_product AS product
                                    CROSS JOIN LATERAL UNNEST(promotions) WITH ORDINALITY AS promo("promoId",
                                                                                                   "retailerPromotionId",
                                                                                                   "startDate",
                                                                                                   "endDate",
                                                                                                   description,
                                                                                                   mechanic,
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
                                                                        REPLACE("retailerId" || '_' || "sourceId" ||
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
                                     "promoId",
                                     "retailerPromotionId",
                                     "startDate",
                                     "endDate",
                                     "promotionMechanicName",
                                     promo_indx,
                                     price_calc."promotedPrice",
                                     price_calc."shelfPrice",
                                     ROW_NUMBER()
                                     OVER (PARTITION BY "sourceId" ORDER BY price_calc."promotedPrice" ) AS promo_price_order
                              FROM product_promo
                                       CROSS JOIN LATERAL (SELECT CASE
                                                                      WHEN "promotionMechanicName" = 'Multibuy'
                                                                          THEN calculateMultibuyPrice(
                                                                              description,
                                                                              "promotedPrice")
                                                                      ELSE
                                                                          "productPrice"
                                                                      END AS "promotedPrice",
                                                                  CASE
                                                                      WHEN "promotionMechanicName" = 'Multibuy'
                                                                          THEN "shelfPrice"
                                                                      WHEN NOT (
                                                                          "sourceType" = 'tesco' AND
                                                                          LOWER(description) ~
                                                                          'clubcard price')
                                                                          THEN
                                                                          "productPrice"
                                                                      ELSE
                                                                          "shelfPrice"
                                                                      END AS "shelfPrice") AS price_calc
                              WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
         ),

         prod_prev_promo AS (SELECT *
                             FROM staging.products_last
                                      INNER JOIN promotions USING ("productId")),
         upd_product_promo AS (SELECT promo."sourceId",
                                      MAX(promo."promotedPrice") FILTER (WHERE promo.promo_price_order = 1) AS "promotedPrice",
                                      MAX(promo."shelfPrice") FILTER (WHERE promo.promo_price_order = 1)    AS "shelfPrice",
                                      ARRAY_AGG(DISTINCT (COALESCE(prev_promo."promoId", promo."promoId"),
                                                          promo."retailerPromotionId",
                                                          COALESCE(prev_promo."startDate", promo."startDate"),
                                                          promo."endDate",
                                                          promo.description,
                                                          promo."promotionMechanicName")::staging.t_promotion
                                          --          ORDER BY promo.promo_indx
                                      )                                                                     AS promotions
                               FROM promo_price_calc AS promo
                                        LEFT OUTER JOIN prod_prev_promo AS prev_promo
                                                        ON (prev_promo."sourceId" = promo."sourceId" AND
                                                            prev_promo."retailerId" = dd_retailer.id AND
                                                            prev_promo.description = promo.description)
                               GROUP BY 1)
    UPDATE tmp_product
    SET promotions      = upd_product_promo.promotions,
        "promotedPrice" = upd_product_promo."promotedPrice",
        "shelfPrice"    = upd_product_promo."shelfPrice"
    FROM upd_product_promo
    WHERE tmp_product."sourceId" = upd_product_promo."sourceId";


    /*  create the new coreProduct   */
    /*
    TO DO:
        const img = product.image;
        product.image = await AWSUtil.uploadImage({
          bucket: 'coreImages',
          key: product.ean,

          link: img,
        });
    */

    /*  findCreateProductCore

        - creates a coreProduct and coreProductBarcode if missing, otherwise
        - updates disabled=false in coreProduct

        logic on selecting coreProductId relating to coreProductBarcode, coreRetailer....
    */
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
                             FROM tmp_product
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
                                      "productOptions", load_id)
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
                            load_retailer_data_base.load_id
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
                    load_retailer_data_base.load_id
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
                     SELECT id, ean, NOW(), NOW(), load_retailer_data_base.load_id
                     FROM ins_coreProducts
                     WHERE "updatedAt" >= NOW()::date
                     ON CONFLICT (barcode)
                         DO UPDATE
                             SET "updatedAt" = excluded."updatedAt"
                     RETURNING "coreProductBarcodes".*),
         debug_ins_coreProductBarcodes AS (
             INSERT INTO staging.debug_coreProductBarcodes
                 SELECT * FROM ins_coreProductBarcodes)
    UPDATE tmp_product
    SET "coreProductId"=ins_coreProducts.id
    FROM ins_coreProducts
    WHERE tmp_product.ean = ins_coreProducts.ean;

    WITH ins_coreProductBarcodes AS (
        INSERT
            INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt", load_id)
                SELECT "coreProductId", ean, NOW(), NOW(), load_retailer_data_base.load_id
                FROM tmp_product
                ON CONFLICT (barcode)
                    DO NOTHING
                RETURNING "coreProductBarcodes".*)
    INSERT
    INTO staging.debug_coreProductBarcodes
    SELECT *
    FROM ins_coreProductBarcodes;

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
                              "dateId", marketplace,
                              "marketplaceData",
                              "priceMatchDescription",
                              "priceMatch",
                              "priceLock",
                              "isNpd", load_id)
            SELECT "sourceType",
                   ean,
                   COALESCE(ARRAY_LENGTH(promotions, 1) > 0, FALSE) AS promotions,
                   COALESCE(promotions[1].description, '')          AS "promotionDescription",
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
                   "dateId",
                   marketplace,
                   "marketplaceData",
                   "priceMatchDescription",
                   "priceMatch",
                   "priceLock",
                   "isNpd",
                   load_retailer_data_base.load_id
            FROM tmp_product
                     CROSS JOIN LATERAL ( SELECT CASE
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
                                                     END AS "productImage") AS new_img
            ON CONFLICT ("sourceId", "retailerId", "dateId")
                WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
                DO
                    UPDATE
                    SET "updatedAt" = excluded."updatedAt",
                        "productInStock" = excluded."productInStock",
                        "productBrand" = excluded."productBrand",
                        "reviewsCount" = excluded."reviewsCount",
                        "reviewsStars" = excluded."reviewsStars",
                        load_id = excluded.load_id
            RETURNING *),
         debug_ins_products AS (
             INSERT
                 INTO staging.debug_products
                     SELECT *
                     FROM ins_products)
    UPDATE tmp_product
    SET id=ins_products.id
    FROM ins_products
    WHERE tmp_product."sourceId" = ins_products."sourceId";

    /*  createProductsData  */
    /*
    TO DO:
        1. parentCategory
        2. set UQ constrain in productsData on productId, category to keep only one ranking record for product/category per day.
            Current solution and also the provided data in the daily_retail_load contains multiple ranking records for a product/category per day.
    */
    WITH debug_ins_productsData AS ( INSERT INTO "productsData" ("productId",
                                                                 category,
                                                                 "categoryType",
                                                                 "parentCategory",
                                                                 "productRank",
                                                                 "pageNumber",
                                                                 screenshot,
                                                                 featured,
                                                                 "featuredRank",
                                                                 "taxonomyId", load_id)
        SELECT product.id AS "productId",
               ranking.category,
               ranking."categoryType",
               ranking."parentCategory",
               ranking."productRank",
               ranking."pageNumber",
               ranking.screenshot,
               ranking.featured,
               ranking."featuredRank",
               ranking."taxonomyId",
               load_retailer_data_base.load_id
        FROM tmp_product AS product
                 CROSS JOIN LATERAL UNNEST(ranking_data) AS ranking
        RETURNING "productsData".*)
    INSERT
    INTO staging.debug_productsdata
    SELECT *
    FROM debug_ins_productsData;

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
               load_retailer_data_base.load_id
        FROM tmp_product AS product
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
                            load_retailer_data_base.load_id
            FROM tmp_product AS product
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
             INNER JOIN tmp_product AS product USING ("coreProductId");

    INSERT
    INTO staging.debug_coreRetailers (load_id, "sourceId", id, "coreProductId", "retailerId", "createdAt",
                                      "updatedAt")
    SELECT load_retailer_data_base.load_id, "sourceId", id, "coreProductId", "retailerId", "createdAt", "updatedAt"
    FROM tmp_coreRetailer;


    /*  coreRetailerSources */
    INSERT INTO "coreRetailerSources"("coreRetailerId", "retailerId", "sourceId", "createdAt", "updatedAt", load_id)
    SELECT id, "retailerId", "sourceId", "createdAt", "updatedAt", load_retailer_data_base.load_id
    FROM tmp_coreRetailer
    ON CONFLICT DO NOTHING;

    /*  setCoreRetailerTaxonomy */
    /*  nodejs code interpreted as insert in coreRetailerTaxonomies only if the given taxonomyId already exists in retailerTaxonomies */
    WITH debug_coreRetailerTaxonomies AS ( INSERT INTO "coreRetailerTaxonomies" ("coreRetailerId",
                                                                                 "retailerTaxonomyId",
                                                                                 "createdAt",
                                                                                 "updatedAt", load_id)
        SELECT tmp_coreRetailer.id AS "coreRetailerId",
               "taxonomyId"        AS "retailerTaxonomyId",
               NOW(),
               NOW(),
               load_retailer_data_base.load_id
        FROM tmp_coreRetailer
                 INNER JOIN (SELECT DISTINCT tmp_product."sourceId",
                                             ranking."taxonomyId"
                             FROM tmp_product
                                      CROSS JOIN LATERAL UNNEST(ranking_data) AS ranking) AS product
                            USING ("sourceId")
                 INNER JOIN (SELECT id AS "taxonomyId" FROM "retailerTaxonomies") AS ret_tax USING ("taxonomyId")
        ON CONFLICT ("coreRetailerId",
            "retailerTaxonomyId")
            WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
            DO NOTHING
        RETURNING "coreRetailerTaxonomies".*)
    INSERT
    INTO staging.debug_coreretailertaxonomies
    SELECT *
    FROM debug_coreRetailerTaxonomies;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  saveProductStatus   */
    WITH debug_productStatuses AS (INSERT INTO "productStatuses" ("productId",
                                                                  status,
                                                                  screenshot,
                                                                  "createdAt",
                                                                  "updatedAt", load_id)
        SELECT id AS "productId",
               status,
               screenshot,
               NOW(),
               NOW(),
               load_retailer_data_base.load_id
        FROM tmp_product
        ON CONFLICT ("productId")
            DO NOTHING
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
                            load_retailer_data_base.load_id
            FROM tmp_product
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
                   load_retailer_data_base.load_id
            FROM tmp_product
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
    WITH debug_ins_coreRetailerDates AS (
        INSERT INTO "coreRetailerDates" ("coreRetailerId",
                                         "dateId",
                                         "createdAt",
                                         "updatedAt", load_id)
            SELECT tmp_coreRetailer.id AS "coreRetailerId",
                   dd_date_id          AS "dateId",
                   NOW(),
                   NOW(),
                   load_retailer_data_base.load_id
            FROM tmp_coreRetailer
            ON CONFLICT ("coreRetailerId",
                "dateId")
                DO NOTHING
            RETURNING "coreRetailerDates".*)
    INSERT
    INTO staging.debug_coreRetailerDates
    SELECT *
    FROM debug_ins_coreRetailerDates;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    INSERT INTO staging.products_last ("retailerId", "sourceId", "productId", date)
    SELECT "retailerId", "sourceId", id AS "productId", date
    FROM tmp_product
    ON CONFLICT ("sourceId", "retailerId" )
        DO UPDATE
        SET "productId" = excluded."productId",
            date=excluded.date
    WHERE products_last.date <= excluded.date;

    INSERT INTO staging.debug_tmp_product
    SELECT load_retailer_data_base.load_id, *
    FROM tmp_product;

    INSERT INTO staging.debug_tmp_daily_data
    SELECT load_retailer_data_base.load_id, *
    FROM tmp_daily_data;

    RETURN;
END ;

$$;
