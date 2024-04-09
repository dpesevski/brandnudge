/*
SELECT staging.load_retailer_data('{
  "retailer": "sainsburys",
  "products": [
    {
      "ean": "5000168208749",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-milk-chocolate-433g",
      "size": "435",
      "eposId": "7955636",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "45% Wheat and Wholemeal. No Hydrogenated Vegetable Oil. The Nation''s Favourite. No Artificial Colours or Flavours. Suitable for Vegetarians. The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955636",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[{\"key\":\"Energy (kJ)\",\"value\":\"2078\"},{\"key\":\"(kcal)\",\"value\":\"496\"},{\"key\":\"Fat\",\"value\":\"23.6g\"},{\"key\":\"of which Saturates\",\"value\":\"12.4g\"},{\"key\":\"Carbohydrate\",\"value\":\"62.5g\"},{\"key\":\"of which Sugars\",\"value\":\"28.5g\"},{\"key\":\"Fibre\",\"value\":\"3g\"},{\"key\":\"Protein\",\"value\":\"6.7g\"},{\"key\":\"Salt\",\"value\":\"0.94g\"},{\"key\":\"Typical number of biscuits per pack: 26\",\"value\":\"\"}]",
      "productInfo": "Flour (39%) (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Milk Chocolate (30%) [Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Dried Whey (Milk), Butter Oil (Milk), Vegetable Fats (Palm, Shea), Emulsifiers (Soya Lecithin, E476), Natural Flavouring], Vegetable Oil (Palm), Wholemeal Wheat Flour (9%), Sugar, Glucose-Fructose Syrup, Raising Agents (Sodium Bicarbonate, Malic Acid, Ammonium Bicarbonate), Salt",
      "productRank": 11,
      "categoryType": "search",
      "featuredRank": 11,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955636/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "reviewsCount": "26",
      "reviewsStars": "3.9231",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "Wheatmeal Biscuits Covered in Milk Chocolate",
      "productTitleDetail": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "promotionDescription": ""
    },
    {
      "ean": "5000168208763",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-dark-chocolate-433g",
      "size": "435",
      "eposId": "7955692",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955692",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[]",
      "productInfo": "",
      "productRank": 12,
      "categoryType": "search",
      "featuredRank": 12,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955692/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "reviewsCount": "14",
      "reviewsStars": "4.6429",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org. McVitie''s golden-baked, crunchy wheat biscuits, topped with a layer of smooth, dark chocolate. McVitie''s Chocolate Digestives are the nation''s favourite biscuits.. Enjoy a little break from the everyday, McVitie''s biscuits are too good not to share.. McVitie''s biscuits are Too Good Not to Share.. Find us at www.mcvities.co.ukwww.123healthybalance.co. By Appointment to Her Majesty The Queen Biscuit Manufacturers United Biscuits (UK) Limited, Hayes",
      "productTitleDetail": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "promotionDescription": ""
    }
  ]
}');
 */


/*  remove coreProductCountryData duplicate records and add UQ constraint on "coreProductId", "countryId" */
CREATE TABLE staging.fix_dup_coreProductCountryData_deleted_rec AS
WITH coreProductCountryData_ext AS (SELECT *,
                                           ROW_NUMBER()
                                           OVER (PARTITION BY "coreProductId", "countryId" ORDER BY "createdAt" ASC ) AS rownum
                                    FROM "coreProductCountryData"),
     deleted AS (
         DELETE
             FROM "coreProductCountryData"
                 USING coreProductCountryData_ext
                 WHERE "coreProductCountryData".id = coreProductCountryData_ext.id AND rownum > 1
                 RETURNING "coreProductCountryData".*)
SELECT *
FROM deleted;

ALTER TABLE "coreProductCountryData"
    ADD CONSTRAINT coreProductCountryData_pk
        UNIQUE ("coreProductId", "countryId");

/*  temporary solution for fix_dup_products  */
CREATE UNIQUE INDEX products_sourceId_retailerId_dateId_key
    ON products ("sourceId", "retailerId", "dateId")
    WHERE "createdAt" >= '2024-02-29';
-- WHERE  "dateId">18166;

/*  temporary solution for fix_dup_coreRetailerTaxonomies  */
CREATE UNIQUE INDEX coreRetailerTaxonomies_coreRetailerId_retailerTaxonomyId_uq
    ON "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId")
    WHERE "createdAt" >= '2024-02-29';-- WHERE  "dateId">18166;

CREATE UNIQUE INDEX promotions_uq_key
    ON promotions ("productId")
    WHERE "createdAt" >= '2024-02-29';

CREATE UNIQUE INDEX coreProductSourceCategories_uq_key
    ON "coreProductSourceCategories" ("coreProductId", "sourceCategoryId")
    WHERE "createdAt" >= '2024-02-29';

CREATE UNIQUE INDEX aggregatedProducts_uq_key
    ON "aggregatedProducts" ("productId")
    WHERE "createdAt" >= '2024-02-29';

/*  There are product entries in the daily load having more then one record for the category, "categoryType"
    This is for the same href/pageNumber where only featured, featuredRank and ProductRank vary.

    Example:    "sourceId" = '7878751'
    SELECT "sourceId",
       "categoryType",
       category,
       "pageNumber",
       featured,
       "featuredRank",
       "productRank"
    FROM staging.tmp_daily_data
    WHERE "sourceId" = '7878751';

    +--------+------------+-------------------------+----------+--------+----------+------------+-----------+
    |sourceId|categoryType|category                 |pageNumber|featured|isFeatured|featuredRank|productRank|
    +--------+------------+-------------------------+----------+--------+----------+------------+-----------+
    |7878751 |aisle       |Flavoured & vitamin water|1         |false   |false     |9           |6          |
    |7878751 |aisle       |Flavoured & vitamin water|1         |true    |true      |1           |1          |
    +--------+------------+-------------------------+----------+--------+----------+------------+-----------+

    WITH dup AS (SELECT "sourceId",
                        "categoryType",
                        category,
                        COUNT(*)
                 FROM staging.tmp_daily_data
                 GROUP BY 1, 2, 3
                 HAVING COUNT(*) > 1)
    SELECT *
    FROM staging.tmp_daily_data
             INNER JOIN dup USING ("sourceId", "categoryType", category);
*/


/*
     I - promotionMechanic defaults

        if (!promo) {
         [mechanic] = await db.promotionMechanic.findOrCreate({
          where: { name: defaultMechanic },
          defaults: { name: defaultMechanic },
        });

      ...

        const obj = {
          retailerId: retailerId,
          promotionMechanicId: mechanic.id,
        };
        [promo] = await db.retailerPromotion.findOrCreate({
          where: obj,
          defaults: obj,
        });

     findRetailerPromotion function (possibly) creates records in two tables:
     - promotionMechanic with a defaultMechanic, and
     - retailerPromotion with retailerId and promotionMechanicId

     promotionMechanics contains 3 records including current defaultMechanic ("Other").

     retailerPromotion records manage "regexp", and these are recorded outside the daily load job.
     The only record which may be inserted in the retailerPromotion at the daily load job would have defaultMechanic (Other) for the promotionMechanicId.

     In case new defaultMechanic is set, the same should be added in the promotionMechanics.
     Also, in table retailerPromotion a record should be added for each retailerId with the promotionMechanic = defaultMechanic.
     This is better approach then to have to check the existence of the default records and then handle it in the code at the every day within the daily load job.

     II - comparePromotionWithPreviousProduct

     The "comparePromotionWithPreviousProduct" function checks for prevProduct using product's dateId. Every call to load_retailer_data creates a new dateId, so prevProduct can only be another record from the products list in this call.
     The products list contains also data for the ranking, effectively duplicating the part for the public.product record for each of the ranking.
     The staging.tmp_product has field "rownum" where only 1st value (rownum=-1) is considered for updating the public.products table.
     Similarly, only promotions from this record will be used to update public.promotions.
     This leads to calling comparePromotionWithPreviousProduct only once, so there won't be any prevProduct to compare to, so effectively it can be avoided.

*/
CREATE EXTENSION plv8;
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
DROP TABLE IF EXISTS staging.retailer_data;
CREATE TABLE IF NOT EXISTS staging.retailer_data
(
    retailer               text,--retailers,
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
    "productOptions"       boolean DEFAULT FALSE,
    shop                   text,
    "amazonShop"           text    DEFAULT 'Core'::text,
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

DROP FUNCTION IF EXISTS staging.compareTwoStrings(text, text);
CREATE OR REPLACE FUNCTION staging.compareTwoStrings(title1 text, title2 text) RETURNS float
    LANGUAGE plv8
AS
$$
 const first = title1.replace(/\s+/g, '');
    const second = title2.replace(/\s+/g, '');

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

DROP FUNCTION IF EXISTS staging.calculateMultibuyPrice(text, float);
CREATE OR REPLACE FUNCTION staging.calculateMultibuyPrice(description text, price float) RETURNS float
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

--DROP FUNCTION IF EXISTS staging.load_retailer_data(jsonb);
CREATE OR REPLACE FUNCTION staging.load_retailer_data(value json) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    dd_date               date;
    dd_source_type        text;
    dd_sourceCategoryType text;
    dd_date_id            integer;
    dd_retailer           retailers;
BEGIN
    /*
    INSERT INTO staging.retailer_daily_data (fetched_data)
    VALUES (value);
    */
    DROP TABLE IF EXISTS staging.tmp_daily_data;
    CREATE TABLE staging.tmp_daily_data AS
    SELECT product.*
    FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data,
                                 value -> 'products') AS product;

    SELECT date, "sourceType", CASE WHEN "categoryType" = 'search' THEN 'search' ELSE 'taxonomy' END
    INTO dd_date, dd_source_type, dd_sourceCategoryType
    FROM staging.tmp_daily_data
    LIMIT 1;

    /*  ProductService.getCreateProductCommonData  */
    /*  dates.findOrCreate  */
    /*  TO DO:  add UQ constraint on date   */

    SELECT id
    INTO dd_date_id
    FROM dates
    WHERE date = dd_date AT TIME ZONE 'UTC';
    IF dd_date_id IS NULL THEN
        INSERT INTO dates (date) VALUES (dd_date) RETURNING id INTO dd_date_id;
    END IF;

    /*  RetailerService.getRetailerByName   */
    SELECT *
    INTO dd_retailer
    FROM retailers
    WHERE name = dd_source_type;

    IF dd_retailer IS NULL THEN
        INSERT INTO retailers (name, "countryId") VALUES (dd_source_type, 'GB') RETURNING * INTO dd_retailer;
    END IF;

    /*  create the new categories   */
    WITH product_categ AS (SELECT DISTINCT category              AS name,
                                           dd_sourceCategoryType AS type
                           FROM staging.tmp_daily_data)
    INSERT
    INTO "sourceCategories"(name, type, "createdAt", "updatedAt")
    SELECT name, type, NOW(), NOW()
    FROM product_categ
             LEFT OUTER JOIN "sourceCategories"
                             USING (name, type)
    WHERE "sourceCategories".id IS NULL;

    DROP TABLE IF EXISTS staging.tmp_product;
    CREATE TABLE staging.tmp_product AS
    WITH prod_categ AS (SELECT id AS "sourceCategoryId", name AS category
                        FROM "sourceCategories"
                        WHERE type = dd_sourceCategoryType),
         prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
         daily_data AS (SELECT NULL::integer                        AS id,
                               NULL::integer                        AS "coreProductId",
                               NULL::integer                        AS "parentCategory", -- TO DO

                               promotions,
                               "productPrice",
                               "originalPrice",
                               "originalPrice"                      AS "basePrice",
                               "originalPrice"                      AS "shelfPrice",
                               "originalPrice"                      AS "promotedPrice",
                               dd_retailer.id                       AS "retailerId",
                               dd_date_id                           AS "dateId",
                               NOT (NOT featured)                   AS featured,
                               "bundled",
                               "category",
                               "categoryType",
                               "date",
                               "ean",
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
                               COALESCE("taxonomyId", 0)            AS "taxonomyId",
                               "sourceCategoryId",
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
                               sell,
                               "fulfilParty",
                               "amazonFulfilParty",
                               status,
                               ROW_NUMBER() OVER (PARTITION BY ean) AS rownum
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
                        FROM staging.tmp_daily_data
                                 INNER JOIN prod_categ USING (category)
                                 LEFT OUTER JOIN prod_brand USING ("productBrand")
                            /*  CompareUtil.checkEAN    */
                            -- strict === true then '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$'
                                 CROSS JOIN LATERAL ( SELECT ean !~ '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$' AS "eanIssues"
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
                                     "sourceCategoryId",
                                     featured,
                                     "featuredRank",
                                     "taxonomyId")::"productsData"
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
           sell,
           "fulfilParty",
           "amazonFulfilParty",
           status,
           screenshot,
           ranking.ranking_data
    FROM daily_data
             INNER JOIN ranking USING ("sourceId")
    WHERE rownum = 1;

    UPDATE staging.tmp_product
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

                                  lat_promo_id."promoId",
                                  promo.description,
                                  promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.


                                  COALESCE(ret_promo."retailerPromotionId",
                                           default_ret_promo."retailerPromotionId")       AS "retailerPromotionId",
                                  COALESCE(ret_promo.regexp, default_ret_promo.regexp)    AS regexp,
                                  COALESCE(ret_promo."promotionMechanicId",
                                           default_ret_promo."promotionMechanicId")       AS "promotionMechanicId",
                                  COALESCE(
                                          ret_promo."promotionMechanicName",
                                          default_ret_promo."promotionMechanicName")      AS "promotionMechanicName",
                                  ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx) AS rownum
                           FROM staging.tmp_product AS product
                                    CROSS JOIN LATERAL UNNEST(promotions) WITH ORDINALITY AS promo("promoId",
                                                                                                   "retailerPromotionId",
                                                                                                   "startDate",
                                                                                                   "endDate",
                                                                                                   description,
                                                                                                   mechanic,
                                                                                                   promo_indx)
                                    CROSS JOIN LATERAL (SELECT COALESCE(promo."startDate", product.date) AS "startDate",
                                                               COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates
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
         upd_product_promo AS (SELECT "sourceId",
                                      MAX(description) FILTER (WHERE "promotionMechanicName" = 'Multibuy') AS Multibuy_description,
                                      MAX(description)
                                      FILTER (WHERE LOWER("promotionMechanicName") ~ 'clubcard price')     AS tescoClubcardPromo_description,
                                      ARRAY_AGG(("promoId",
                                                 "retailerPromotionId",
                                                 "startDate",
                                                 "endDate",
                                                 description,
                                                 "promotionMechanicName")::staging.t_promotion
                                                ORDER BY promo_indx)                                       AS promotions
                               FROM product_promo
                               WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
                               GROUP BY 1)
    UPDATE staging.tmp_product
    SET promotions=upd_product_promo.promotions,
        "promotedPrice" = CASE
                              WHEN upd_product_promo.Multibuy_description IS NOT NULL
                                  THEN staging.calculateMultibuyPrice(upd_product_promo.Multibuy_description,
                                                                      all_products."promotedPrice")
                              WHEN upd_product_promo."sourceId" IS NOT NULL THEN all_products."productPrice"
                              ELSE
                                  all_products."promotedPrice"
            END,
        "shelfPrice"= CASE
                          WHEN upd_product_promo.Multibuy_description IS NOT NULL
                              THEN all_products."shelfPrice"
                          WHEN NOT (all_products."sourceType" = 'tesco' AND
                                    upd_product_promo.tescoClubcardPromo_description IS NOT NULL)
                              THEN
                              all_products."productPrice"
                          ELSE
                              all_products."shelfPrice"
            END
    FROM staging.tmp_product AS all_products
             LEFT OUTER JOIN upd_product_promo
                             ON all_products."sourceId" = upd_product_promo."sourceId"
    WHERE tmp_product."sourceId" = all_products."sourceId";


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
        - updates disabled=true in coreProduct

        logic on selecting coreProductId relating to coreProductBarcode, coreRetailer....
    */
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
                             FROM staging.tmp_product),
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
                     RETURNING *),
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
                 DO UPDATE
                     SET "updatedAt" = excluded."updatedAt"),
         ins_coreProductBarcodes AS (
             INSERT
                 INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt")
                     SELECT id, ean, NOW(), NOW()
                     FROM ins_coreProducts
                     WHERE "updatedAt" >= NOW()::date
                     ON CONFLICT (barcode)
                         DO UPDATE
                             SET "updatedAt" = excluded."updatedAt")
    UPDATE staging.tmp_product
    SET "coreProductId"=ins_coreProducts.id
    FROM ins_coreProducts
    WHERE tmp_product.ean = ins_coreProducts.ean;


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
                   COALESCE(promotions[0].description, '')          AS "promotionDescription",
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
            FROM staging.tmp_product
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
                WHERE "createdAt" >= '2024-02-29'
                DO UPDATE
                    SET "updatedAt" = excluded."updatedAt"
            RETURNING products.*)
    UPDATE staging.tmp_product
    SET id=ins_products.id
    FROM ins_products
    WHERE tmp_product."sourceId" = ins_products."sourceId"
      AND tmp_product."retailerId" = ins_products."retailerId"
      AND tmp_product."dateId" = ins_products."dateId";

    /*  createProductsData  */
    /*
    TO DO:
        1. parentCategory
        2. set UQ constrain in productsData on productId, category to keep only one ranking record for product/category per day.
            Current solution and also the provided data in the daily_retail_load contains multiple ranking records for a product/category per day.
    */
    INSERT INTO "productsData" ("productId",
                                category,
                                "categoryType",
                                "parentCategory",
                                "productRank",
                                "pageNumber",
                                screenshot,
                                "sourceCategoryId",
                                featured,
                                "featuredRank",
                                "taxonomyId")
    SELECT product.id AS "productId",
           ranking.category,
           ranking."categoryType",
           ranking."parentCategory",
           ranking."productRank",
           ranking."pageNumber",
           ranking.screenshot,
           ranking."sourceCategoryId",
           ranking.featured,
           ranking."featuredRank",
           ranking."taxonomyId"
    FROM staging.tmp_product AS product
             CROSS JOIN LATERAL UNNEST(ranking_data) AS ranking;

    /*  createAmazonProduct */
    /*
       TO DO: set UQ constrain in amazonProducts on productId?.
     */
    INSERT INTO "amazonProducts" ("productId",
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
    FROM staging.tmp_product AS product
    WHERE LOWER("sourceType") LIKE '%amazon%';


    /*  setCoreRetailer */
    DROP TABLE IF EXISTS staging.tmp_coreRetailer;
    CREATE TABLE staging.tmp_coreRetailer AS
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
            FROM staging.tmp_product AS product
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

    /*  setCoreRetailerTaxonomy */
    /*  nodejs code interpreted as insert in coreRetailerTaxonomies only if the given taxonomyId already exists in retailerTaxonomies */
    INSERT INTO "coreRetailerTaxonomies" ("coreRetailerId",
                                          "retailerTaxonomyId",
                                          "createdAt",
                                          "updatedAt")
    SELECT tmp_coreRetailer.id AS "coreRetailerId",
           "taxonomyId"        AS "retailerTaxonomyId",
           NOW(),
           NOW()
    FROM staging.tmp_coreRetailer
             INNER JOIN (SELECT DISTINCT tmp_product.id AS "productId",
                                         ranking."taxonomyId"
                         FROM staging.tmp_product
                                  CROSS JOIN LATERAL UNNEST(ranking_data) AS ranking) AS product
                        USING ("productId")
             INNER JOIN (SELECT id AS "taxonomyId" FROM "retailerTaxonomies") AS ret_tax USING ("taxonomyId")
    ON CONFLICT ("coreRetailerId",
        "retailerTaxonomyId")
    WHERE "createdAt" >= '2024-02-29'
        DO NOTHING;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  saveProductStatus   */
    INSERT INTO "productStatuses" ("productId",
                                   status,
                                   screenshot,
                                   "createdAt",
                                   "updatedAt")
    SELECT id AS "productId",
           status,
           screenshot,
           NOW(),
           NOW()
    FROM staging.tmp_product
    ON CONFLICT ("productId")
        DO NOTHING;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  PromotionService.processProductPromotions, part 2 insert promotions  */
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
    FROM staging.tmp_product
             CROSS JOIN LATERAL UNNEST(promotions) AS promo
    ON CONFLICT ("productId")
    WHERE "createdAt" >= '2024-02-29'
        DO
    UPDATE
    SET "startDate"=LEAST(promotions."startDate", excluded."startDate"),
        "endDate"=GREATEST(promotions."endDate", excluded."endDate"),
        "updatedAt" = excluded."updatedAt";

    /*  aggregatedProducts  */
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
    FROM staging.tmp_product
             INNER JOIN (SELECT "coreProductId", title AS "titleParent"
                         FROM "coreProductCountryData"
                         WHERE "countryId" = dd_retailer."countryId") AS parentProdCountryData USING ("coreProductId")
    ON CONFLICT ("productId")
    WHERE "createdAt" >= '2024-02-29'
        DO NOTHING;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    /*  coreRetailerDates */
    INSERT INTO "coreRetailerDates" ("coreRetailerId",
                                     "dateId",
                                     "createdAt",
                                     "updatedAt")
    SELECT tmp_coreRetailer.id AS "coreRetailerId",
           dd_date_id          AS "dateId",
           NOW(),
           NOW()
    FROM staging.tmp_coreRetailer
    ON CONFLICT ("coreRetailerId",
        "dateId")
        DO NOTHING;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";


    /*  coreProductSourceCategory   */
    INSERT INTO "coreProductSourceCategories" ("coreProductId",
                                               "sourceCategoryId",
                                               "createdAt",
                                               "updatedAt")
    SELECT DISTINCT tmp_product."coreProductId",
                    ranking."sourceCategoryId",
                    NOW(),
                    NOW()
    FROM staging.tmp_product
             CROSS JOIN LATERAL UNNEST(ranking_data) AS ranking
    ON CONFLICT ("coreProductId", "sourceCategoryId")
    WHERE "createdAt" >= '2024-02-29'
        DO NOTHING;
    --  UPDATE SET "updatedAt" = excluded."updatedAt";

    RETURN;
END ;

$$;

DELETE
FROM "productsData" USING products
WHERE "productId" = products.id
  AND products."createdAt" >= '2024-02-29';

SELECT staging.load_retailer_data(fetched_data)
FROM staging.retailer_daily_data;

