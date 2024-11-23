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
                          "isNpd",
                          load_id)
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


SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

WITH tmp_product_pp AS (SELECT * FROM staging.debug_tmp_product_pp WHERE load_id = 216),
     duplicates AS (SELECT "coreProductId", "retailerId", "dateId"
                    FROM tmp_product_pp
                    GROUP BY "coreProductId", "retailerId", "dateId"
                    HAVING COUNT(*) > 1)
SELECT DISTINCT "coreProductId"
FROM tmp_product_pp
         INNER JOIN duplicates USING ("coreProductId", "retailerId", "dateId")
ORDER BY "coreProductId";
SELECT *
FROM retailers
WHERE id = 1;
SELECT *
FROM dates
WHERE date = '2024-11-17';

SELECT ean, "sourceId", *
FROM test.dd_products
WHERE "sourceId" = '308499433';

SELECT ean, "sourceId", "coreProductId", status, date, "dateId"
FROM test.tmp_product_pp
WHERE "sourceId" = '308499433';

SELECT "retailerId", "sourceId", ean, "coreProductId", date::date
FROM products
WHERE "sourceId" = '308499433'
   OR ean = '5011166080244'
ORDER BY date DESC;

SELECT "retailerId",
       "sourceId",
       ean,
       "coreProductId",
       COUNT(*),
       MIN(date::date) AS dt_since,
       MAX(date::date) AS dt_till
FROM products
WHERE ("sourceId" = '308499433'
    OR ean = '5011166080244')
  AND date::date < '2024-11-17'
GROUP BY "retailerId", "sourceId", ean, "coreProductId";


/*
+----------+---------+-------------+-------------+----------+
|retailerId|sourceId |ean          |coreProductId|date      |
+----------+---------+-------------+-------------+----------+
|1         |308499433|5011166080244|843542       |2024-11-17|
|1         |308499433|5011166063223|54597        |2024-11-15|
|8         |615252011|5011166080244|843542       |2024-11-15|
|8         |615252011|5011166080244|843542       |2024-11-14|
|1         |308499433|5011166063223|54597        |2024-11-14|
+----------+---------+-------------+-------------+----------+

+----------+---------+-------------+-------------+-----+----------+----------+
|retailerId|sourceId |ean          |coreProductId|count|dt_since  |dt_till   |
+----------+---------+-------------+-------------+-----+----------+----------+
|1         |308499433|5011166063223|54597        |616  |2021-09-05|2024-11-15|
|1         |308499433|5011166080244|843542       |458  |2023-07-08|2024-10-10|
|8         |615252011|5011166080244|843542       |449  |2023-08-25|2024-11-15|
|9         |609685011|5011166080244|843542       |457  |2023-03-18|2024-09-28|
+----------+---------+-------------+-------------+-----+----------+----------+

+------+-------------+--------------------------------------------------+
|id    |ean          |title                                             |
+------+-------------+--------------------------------------------------+
|54597 |5011166063223|J.J Whitley Blood Orange Vodka 1l                 |
|843542|5011166080244|J.J Whitley Blood Orange Vodka Mix Spirit Drink 1l|
+------+-------------+--------------------------------------------------+

*/
SELECT *
FROM "coreRetailers"
         INNER JOIN
     "coreRetailerSources" ON ("coreRetailerId" = "coreRetailers".id)
WHERE "sourceId" = '308499433';


SELECT ean, "coreProductId", "sourceId", "coreProducts".*
FROM "coreProducts"
         INNER JOIN "coreRetailers" ON ("coreProductId" = "coreProducts".id)
         LEFT OUTER JOIN "coreRetailerSources" ON ("coreRetailerId" = "coreRetailers".id)
WHERE "coreRetailers"."retailerId" = 1
  AND ean IN ('5011166080244', '5011166063223');

