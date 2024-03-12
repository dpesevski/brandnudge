CREATE SCHEMA staging;
CREATE SCHEMA tests;

CREATE TABLE IF NOT EXISTS staging.retailer_daily_data
(
    fetched_data json,
    created_at   timestamptz DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION staging.load_retailer_data(value json) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO staging.retailer_daily_data (fetched_data)
    VALUES (value);
    RETURN;
END;
$$;

CREATE FUNCTION fn_to_float(value text) RETURNS double precision
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

CREATE FUNCTION fn_to_date(value text) RETURNS date
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

/*  MainFilters */
DROP TABLE IF EXISTS tests."agg_coreProductRetailer";
CREATE TABLE tests."agg_coreProductRetailer" AS
WITH product_dates AS (SELECT "coreProductId",
                              "retailerId",
                              date::date,
                              ROW_NUMBER()
                              OVER ( PARTITION BY "coreProductId","retailerId" ORDER BY date ) AS row_num
                       FROM "coreRetailers"
                                INNER JOIN "coreRetailerDates" ON ("coreRetailerId" = "coreRetailers".id)
                                INNER JOIN dates ON ("dateId" = dates.id))
SELECT "coreProductId",
       "retailerId",
       ARRAY_AGG(DATERANGE(start_date,
                           end_date, '[]') ORDER BY end_date) AS listing_intervals
FROM (SELECT "coreProductId",
             "retailerId",
             MIN(date) start_date,
             MAX(date) end_date
      FROM product_dates
      GROUP BY "coreProductId", "retailerId", DATE - row_num * INTERVAL '1 day') AS date_ranges
GROUP BY "coreProductId",
         "retailerId";

/*  sample query for MainFilters*/
/*
WITH params("p_companyId", "p_countryId", "p_userId") AS (VALUES (74, 1, NULL::integer)),
     product_base AS (SELECT "coreProducts"."id",
                             "coreProducts"."title",
                             "coreProducts"."ean",
                             "coreProducts"."image",
                             "coreProducts"."brandId",
                             "coreProducts"."categoryId",
                             "brands"."manufacturerId",
                             "coreProducts"."secondaryImages",
                             "coreProductCountryData"."ownLabelManufacturerId",
                             COALESCE("productGroups"."productGroupIds", ARRAY []::int[]) AS "productGroupIds",
                             "brands"."color",
                             "coreRetailers".retailers,
                             "coreRetailers".listing_periods

                      FROM (SELECT *
                            FROM "coreProducts"
                            WHERE NOT disabled) AS "coreProducts"

                               INNER JOIN (SELECT *
                                           FROM "coreProductCountryData"
                                                    CROSS JOIN params
                                           WHERE "countryId" = params."p_countryId") AS "coreProductCountryData"
                                          ON ("coreProducts".id = "coreProductCountryData"."coreProductId")

                               INNER JOIN "brands" ON ("coreProducts"."brandId" = "brands".id)
                               INNER JOIN (SELECT "coreProductId",
                                                  ARRAY_AGG(ret_listing_intervals)                  AS "listing_periods",
                                                  ARRAY_AGG("agg_coreProductRetailer"."retailerId") AS "retailers"
                                           FROM tests."agg_coreProductRetailer"
                                                    INNER JOIN "companyRetailers" USING ("retailerId")
                                                    INNER JOIN companies ON ("companyRetailers"."companyId" = companies.id)

                                                    INNER JOIN "coreProducts"
                                                               ON ("coreProductId" = "coreProducts".id AND NOT companies.disabled)
                                                    INNER JOIN "companyCoreCategories"
                                                               ON ("companyCoreCategories"."companyId" =
                                                                   companies.id AND
                                                                   "companyCoreCategories"."categoryId" =
                                                                   "coreProducts"."categoryId")
                                                    CROSS JOIN LATERAL (SELECT "retailerId", listing_intervals) AS ret_listing_intervals
                                                    CROSS JOIN params
                                           WHERE companies.id = params."p_companyId"
                                           GROUP BY "coreProductId") AS "coreRetailers"
                                          ON ("coreProducts".id = "coreRetailers"."coreProductId")

                               LEFT OUTER JOIN (SELECT "coreProductId",
                                                       ARRAY_AGG("productGroupId") AS "productGroupIds"
                                                FROM "productGroupCoreProducts"
                                                GROUP BY "coreProductId") AS "productGroups"
                                               ON ("coreProducts"."id" = "productGroups"."coreProductId")),
     "product" AS (SELECT COALESCE(ARRAY_AGG(product_base),
                                   ARRAY []::record[]) AS data
                   FROM product_base),
     "productGroup" AS (WITH prod_group AS (SELECT id,
                                                   "companyId",
                                                   "userId",
                                                   name,
                                                   color,
                                                   COALESCE("productsCount", 0) AS "productsCount"
                                            FROM "productGroups"
                                                     LEFT OUTER JOIN (SELECT "productGroupId" AS id, COUNT(*) AS "productsCount"
                                                                      FROM "productGroupCoreProducts"
                                                                      --   INNER JOIN product_base ON "coreProductId" = product_base.id
                                                                      GROUP BY "productGroupId") AS "productGroupCoreProducts"
                                                                     USING (id))

                        SELECT COALESCE(ARRAY_AGG("productGroup") FILTER (WHERE "companyId" = params."p_companyId"),
                                        ARRAY []::record[]) AS "companyProductGroup",
                               COALESCE(ARRAY_AGG("productGroup") FILTER (WHERE "userId" = params."p_userId"),
                                        ARRAY []::record[]) AS "userProductGroup"
                        FROM prod_group
                                 CROSS JOIN LATERAL (SELECT "id",
                                                            "name",
                                                            "color",
                                                            "productsCount") AS "productGroup"
                                 CROSS JOIN params),
     manufacturer AS (SELECT "manufacturers".id,
                             "manufacturers".name,
                             "manufacturers".color,
                             COUNT(*) AS "productsCount"
                      FROM "manufacturers"
                               INNER JOIN product_base ON ("manufacturerId" = "manufacturers".id)
                      GROUP BY "manufacturers".id,
                               "manufacturers".name,
                               "manufacturers".color),
     manufacturer_agg AS (SELECT ARRAY_AGG(manufacturer) AS data
                          FROM manufacturer),
     brand_base AS (SELECT brands.id,
                           brands."name",
                           brands."color",
                           brands."manufacturerId",
                           brands."brandId",
                           COALESCE(prod."productsCount", 0) AS "productsCount"
                    FROM brands
                             LEFT OUTER JOIN (SELECT "brandId" AS id, COUNT(*) AS "productsCount"
                                              FROM product_base
                                              GROUP BY 1) AS prod USING (id)),
     brand AS (WITH brand_children AS (SELECT brand_base.id, ARRAY_AGG(child) AS child
                                       FROM brand_base
                                                INNER JOIN brand_base AS child ON (child."brandId" = brand_base.id)
                                       GROUP BY brand_base.id)
               SELECT brand_base.*, COALESCE(child, ARRAY []::record[]) AS child
               FROM brand_base
                        LEFT OUTER JOIN brand_children USING (id)),
     brand_extended AS (SELECT *
                        FROM brand
                        WHERE "productsCount" > 0

                        /*  include the missing parent brands   */
                        UNION

                        SELECT *
                        FROM brand AS parent
                                 INNER JOIN (SELECT "brandId" AS id
                                             FROM brand
                                             WHERE "productsCount" > 0) AS brand USING (id)),
     brand_agg AS (SELECT ARRAY_AGG(brand_extended) AS data
                   FROM brand_extended),
     category AS (SELECT "id",
                         "name",
                         "color",
                         "productsCount"
                  FROM categories
                           INNER JOIN (SELECT "brandId" AS id, COUNT(*) AS "productsCount"
                                       FROM product_base
                                       GROUP BY 1) AS prod USING (id)),
     "category_agg" AS (SELECT ARRAY_AGG(category) AS data
                        FROM category),
     retailer AS (SELECT "id",
                         "name",
                         "color",
                         NULL AS label, -- in the sample data this has same value as the attribute "name"
                         NULL AS title  -- ?
                  FROM retailers
                           INNER JOIN (SELECT DISTINCT retailer AS id
                                       FROM product_base
                                                CROSS JOIN UNNEST(product_base.retailers) AS "retailer") AS prod
                                      USING (id)),
     "sourceType_agg" AS (SELECT ARRAY_AGG(retailer) AS data
                          FROM retailer)
SELECT JSON_BUILD_OBJECT('sourceType', "sourceType_agg".data,
                         'category', "category_agg".data,
                         'manufacture', manufacturer_agg.data, -- changed to manufacture as in the given sample data
                         'productBrand', brand_agg.data,
                         'productGroup', "productGroup",
                         'product', "product".data,
                         'productCount', ARRAY_LENGTH("product".data, 1)) AS result
FROM "product"
         CROSS JOIN "productGroup"
         CROSS JOIN brand_agg
         CROSS JOIN "manufacturer_agg"
         CROSS JOIN "category_agg"
         CROSS JOIN "sourceType_agg";
 */


/*  products pricing and ranking    */
CREATE TYPE tests.product_pricing AS
(
    perid           daterange,
    "shelfPrice"    text,
    "basePrice"     text,
    "promotedPrice" text
);

CREATE TYPE tests.product_ranking AS
(
    period             daterange,
    category           varchar(255),
    "categoryType"     varchar(255),
    "parentCategory"   varchar(255),
    "productRank"      integer,
    "sourceCategoryId" integer,
    featured           boolean,
    "featuredRank"     integer,
    "taxonomyId"       integer
);

CREATE TABLE tests.products AS
WITH status AS (WITH status AS (SELECT "coreProductId",
                                       "retailerId",
                                       status = 'de-listed'                                                        AS is_delisted,
                                       ROW_NUMBER()
                                       OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY "updatedAt" DESC) AS row_num
                                FROM "productStatuses"
                                         INNER JOIN (SELECT id AS "productId",
                                                            "coreProductId",
                                                            "retailerId",
                                                            date
                                                     FROM products) AS products USING ("productId"))
                SELECT "coreProductId" AS id,
                       "retailerId",
                       is_delisted
                FROM status
                WHERE row_num = 1),
     ranking AS (WITH products AS (SELECT "coreProductId",
                                          "retailerId",
                                          date,
                                          category,
                                          "categoryType",
                                          "parentCategory",
                                          "productRank",
                                          "sourceCategoryId",
                                          featured,
                                          "featuredRank",
                                          "taxonomyId",

                                          LAG("productRank")
                                          OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS "prev_productRank",
                                          LAG("featuredRank")
                                          OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS "prev_featuredRank"

                                   FROM "productsData"
                                            INNER JOIN (SELECT id AS "productId",
                                                               "coreProductId",
                                                               "retailerId",
                                                               date
                                                        FROM products) AS products
                                                       USING ("productId")),
                      distinct_samples AS (SELECT *,
                                                  LEAD(DATE)
                                                  OVER (PARTITION BY "coreProductId", "retailerId", category, "sourceCategoryId" ORDER BY DATE) AS date_till
                                           FROM products
                                           WHERE "productRank" IS DISTINCT FROM "prev_productRank"
                                              OR "featuredRank" IS DISTINCT FROM "prev_featuredRank")
                 SELECT "coreProductId"                                            AS id,
                        "retailerId",
                        ARRAY_AGG((
                                   DATERANGE(date::date, date_till::date, '[)'),
                                   CATEGORY,
                                   "categoryType",
                                   "parentCategory",
                                   "productRank",
                                   "sourceCategoryId",
                                   featured,
                                   "featuredRank",
                                   "taxonomyId"
                                      )::tests.product_ranking ORDER BY DATE DESC) AS ranking
                 FROM distinct_samples
                 GROUP BY "coreProductId", "retailerId"),
     pricing AS (WITH products AS (SELECT "coreProductId",
                                          "retailerId",
                                          DATE,
                                          "basePrice",
                                          "shelfPrice",
                                          "promotedPrice",
                                          LAG("basePrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_basePrice",
                                          LAG("shelfPrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_shelfPrice",
                                          LAG("promotedPrice")
                                          OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS "prev_promotedPrice"
                                   FROM products),
                      distinct_samples AS (SELECT *,
                                                  LEAD(DATE)
                                                  OVER (PARTITION BY "coreProductId", "retailerId" ORDER BY DATE) AS date_till
                                           FROM products
                                           WHERE "basePrice" IS DISTINCT FROM "prev_basePrice"
                                              OR "shelfPrice" IS DISTINCT FROM "prev_shelfPrice"
                                              OR "promotedPrice" IS DISTINCT FROM "prev_promotedPrice")
                 SELECT "coreProductId"                                                     AS id,
                        "retailerId",
                        ARRAY_AGG((DATERANGE(date::date, date_till::date, '[)'),
                                   "promotedPrice",
                                   "basePrice",
                                   "shelfPrice")::tests.product_pricing ORDER BY date DESC) AS pricing
                 FROM distinct_samples
                 GROUP BY "coreProductId", "retailerId")
SELECT *
FROM pricing
         LEFT OUTER JOIN ranking USING (id, "retailerId")
         LEFT OUTER JOIN status USING (id, "retailerId");


/*  promotions  */
CREATE TYPE tests.product_promo_pricing AS
(
    "coreProductId" integer,
    period          daterange,
    "shelfPrice"    float, -- maybe keep it everywhere as an array to avoid to array transformation
    "basePrice"     float,
    "promotedPrice" float
);

CREATE TABLE tests.promotions AS
WITH products AS (SELECT id                           AS "productId",
                         date::date,
                         "coreProductId",
                         fn_to_float("shelfPrice")    AS "shelfPrice",
                         fn_to_float("basePrice")     AS "basePrice",
                         fn_to_float("promotedPrice") AS "promotedPrice"
                  FROM products),
     agg_1 AS (SELECT "retailerId",
                      "promoId",
                      products."coreProductId",
                      MIN("promotionMechanicId")                  AS "promotionMechanicId",
                      MIN(description)                            AS description,

                      COALESCE(fn_to_date(MIN(promotions."startDate")),
                               MIN(promotions."createdAt")::date) AS "startDate",
                      COALESCE(fn_to_date(MAX(promotions."endDate")),
                               MAX(promotions."updatedAt")::date) AS "endDate",
                      DATERANGE(MIN(products.date),
                                MAX(products.date), '[]')         AS pricing_period,

                      products."shelfPrice",
                      products."basePrice",
                      products."promotedPrice"

               FROM promotions
                        INNER JOIN "retailerPromotions" ON ("retailerPromotionId" = "retailerPromotions".id)
                        INNER JOIN products USING ("productId")
               WHERE NOT ("promoId" IS NULL
                   OR description = ''
                   OR "endDate" < "startDate")
               GROUP BY "retailerId",
                        "promoId",
                        products."coreProductId",
                        products."shelfPrice",
                        products."basePrice",
                        products."promotedPrice")
SELECT "retailerId",
       "promoId",
       ARRAY_AGG(DISTINCT "coreProductId")                                AS "coreProductId",
       MIN("promotionMechanicId")                                         AS "promotionMechanicId",
       MIN(description)                                                   AS description,
       DATERANGE(MIN("startDate"), MAX("endDate"), '[]')                  AS promotion_period,
       ARRAY_AGG(DISTINCT ("coreProductId",
                           pricing_period,
                           "shelfPrice",
                           "basePrice",
                           "promotedPrice")::tests.product_promo_pricing) AS pricing
FROM agg_1
WHERE NOT ("endDate" < "startDate")
GROUP BY "retailerId",
         "promoId";

ALTER TABLE tests.promotions
    ADD CONSTRAINT promotions_pk
        PRIMARY KEY ("retailerId", "promoId");

CREATE INDEX IF NOT EXISTS promotions_retailerid_promotion_period_index
    ON tests.promotions ("retailerId", promotion_period);

CREATE INDEX IF NOT EXISTS promotions_coreproductid_index
    ON tests.promotions USING gin ("coreProductId");