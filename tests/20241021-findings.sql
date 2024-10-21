/*  T01:  product count prod <-> staging    */
WITH prod AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
              FROM test.tprd_products),
     staging AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
                 FROM test.tstg_products),
     prod_cnt AS (SELECT "retailerId", COUNT(prod.*) AS prod_prd_count, COUNT(staging.*) AS stg_prd_count
                  FROM prod
                           FULL OUTER JOIN staging USING ("retailerId", dates_date, "sourceId")
                  GROUP BY "retailerId")
SELECT "retailerId",
       retailer_name,
       prod_prd_count,
       stg_prd_count,
       prod_prd_count - stg_prd_count AS prd_count_diff
FROM prod_cnt
         FULL OUTER JOIN (SELECT "retailerId", retailers.name AS retailer_name
                          FROM public.retailers
                                   INNER JOIN test.retailer ON (retailer."retailerId" = retailers.id)) AS retailer
                         USING ("retailerId")
ORDER BY "retailerId";
-- -2160


SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" = 28627
  AND "sourceType" = 'woolworths';

SELECT COUNT(*)
FROM products
WHERE "dateId" = 28693
  AND "sourceType" = 'woolworths';


/*  T02:  missing products in prod    */
SELECT staging.*
FROM test.tstg_products AS staging
         LEFT OUTER JOIN test.tprd_products AS prod
                         USING ("retailerId", dates_date, "sourceId")
WHERE prod.id IS NULL;

SELECT *
FROM products
WHERE load_id = 67
  AND "productBrand" = 'Fluffy'
ORDER BY "productTitle";

SELECT *
FROM prod_fdw.products
WHERE "dateId" = 28627
  AND "sourceType" = 'woolworths'
  AND "productBrand" = 'Fluffy'
ORDER BY "productTitle";



/*  2nd part    */

/*  T08:  product differences in promotionDescription    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."promotionDescription" AS staging_promotionDescription,
       prod."promotionDescription"    AS prod_promotionDescription,
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."promotionDescription" != prod."promotionDescription"
ORDER BY staging."sourceId" DESC;

/*  T09:  product differences in href    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       load_id,
       staging."href" AS staging_href,
       prod."href"    AS prod_href
FROM test.tstg_products staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."href" != prod."href";


SELECT href, *
FROM products
WHERE load_id = 67
  AND "sourceId" = '164891';


WITH load AS (SELECT data
              FROM staging.load
              WHERE id = 67)
SELECT product
FROM load
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(data -> 'products') AS product
WHERE product ->> 'sourceId' = '164891';

/*
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|product                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|{"date":"2024-10-19 12:00:00","sourceId":"164891","ean":"4987176039224","brand":"Gillette","title":"Gillette Venus Smooth Razor each","shelfPrice":"4.75","wasPrice":"9.50","cardPrice":"4.75","inStock":true,"onPromo":true,"promoData":[{"promo_id":"","promo_description":"Was $9.50 Now $4.75","promo_type":"price cut"}],"skuURL":"https://www.woolworths.com.au/shop/productdetails/164891/gillette-venus-smooth-razor","imageURL":"https://cdn0.woolworths.media/content/wowproductimages/large/164891.jpg","bundled":"false","masterSku":"false"}|
|{"date":"2024-10-19 12:00:00","sourceId":"164891","ean":"4987176039224","brand":"Gillette","title":"Gillette Venus Smooth Razor each","shelfPrice":"4.75","wasPrice":"9.50","cardPrice":"4.75","inStock":true,"onPromo":true,"promoData":[{"promo_id":"","promo_description":"Was $9.50 Now $4.75","promo_type":"price cut"}],"skuURL":"https://www.woolworths.com.au/shop/productdetails/164891/UrlFriendlyName",            "imageURL":"https://cdn0.woolworths.media/content/wowproductimages/large/164891.jpg","bundled":"false","masterSku":"false"}|
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
*/