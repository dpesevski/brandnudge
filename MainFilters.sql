DROP TABLE IF EXISTS tests."coreProductRetailer_agg";
CREATE TABLE tests."coreProductRetailer_agg" AS
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
                                                  ARRAY_AGG("coreProductRetailer_agg"."retailerId") AS "retailers"
                                           FROM tests."coreProductRetailer_agg"
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
