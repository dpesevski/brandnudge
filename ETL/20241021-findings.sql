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

/*  "UrlFriendlyName" */

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
WHERE load_id = 232
  AND "sourceId" = '170647';


WITH load AS (SELECT data
              FROM staging.load
              WHERE id = 232)
SELECT product
FROM load
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(data -> 'products') AS product
WHERE product ->> 'sourceId' = '170647';

/*
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|product                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|{"date":"2024-10-22 12:00:00","sourceId":"170647","ean":"4902430858076","brand":"Gillette","title":"Gillette King c Beard Trimmer Each","shelfPrice":"60.00","wasPrice":"60.00","cardPrice":"60.00","inStock":true,"onPromo":false,"promoData":[],"skuURL":"https://www.woolworths.com.au/shop/productdetails/170647/gillette-king-c-beard-trimmer","imageURL":"https://cdn0.woolworths.media/content/wowproductimages/large/170647.jpg","bundled":"false","masterSku":"false"}|
|{"date":"2024-10-22 12:00:00","sourceId":"170647","ean":"4902430858076","brand":"Gillette","title":"Gillette King c Beard Trimmer Each","shelfPrice":"60.00","wasPrice":"60.00","cardPrice":"60.00","inStock":true,"onPromo":false,"promoData":[],"skuURL":"https://www.woolworths.com.au/shop/productdetails/170647/UrlFriendlyName",              "imageURL":"https://cdn0.woolworths.media/content/wowproductimages/large/170647.jpg","bundled":"false","masterSku":"false"}|
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
*/

SELECT "coreProductId",*
FROM products
WHERE load_id = 299
  AND "productBrand" = '1000 Hour';
--  AND "sourceId" = '6611448';

SELECT "coreProductId",*
FROM prod_fdw.products
WHERE "dateId" = 28759
  AND "sourceType" = 'coles'
  AND "productBrand" = '1000 Hour'
-- AND "sourceId" = '6611448'
ORDER BY "productTitle";

SELECT "coreProductId", "coreRetailerId", barcode, *
FROM "coreRetailerSources"
         INNER JOIN "coreRetailers" ON ("coreRetailers".id = "coreRetailerSources"."coreRetailerId")
         INNER JOIN "coreProductBarcodes" USING ("coreProductId")
WHERE "sourceId" = '6611448';

SELECT "coreProductId", "coreRetailerId", barcode, *
FROM prod_fdw."coreRetailerSources"
         INNER JOIN prod_fdw."coreRetailers" ON ("coreRetailers".id = "coreRetailerSources"."coreRetailerId")
         INNER JOIN prod_fdw."coreProductBarcodes" USING ("coreProductId")
WHERE "sourceId" = '6611448';

select * from "coreProductBarcodes" where barcode='Coles_6611448';
select * from "coreProducts" where ean='Coles_6611448';
select * from "coreRetailerSources" WHERE "sourceId" = '6611448';

select * from  prod_fdw."coreProductBarcodes" where barcode='Coles_6611448';
select * from  prod_fdw."coreProducts" where ean='Coles_6611448';
select * from  prod_fdw."coreRetailerSources" WHERE "sourceId" = '6611448';

