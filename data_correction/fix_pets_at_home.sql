SELECT "coreProductId", "sourceId", ean, *
FROM products
WHERE "retailerId" = 1302
  AND "sourceId" = '5375409444'
ORDER BY "dateId" DESC;

SELECT "coreProductId", "sourceId"
FROM "coreRetailerSources"
         INNER JOIN "coreRetailers" ON ("coreRetailerSources"."coreRetailerId" = "coreRetailers".id)
WHERE "coreProductId" IN (960479, 1003038);
+---------------------+
|ean                  |
+---------------------+
|0100370052903        |
|Walmart_us_5375409444|
+---------------------+
+-------------+
|coreProductId|
+-------------+
|1222513      |
|1159136      |
+-------------+

SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" IN (960479, 1003038);

SELECT products.id AS "productId", "coreProductId", "sourceId", ean, products.load_id, status, date::date
FROM products
         INNER JOIN "productStatuses" ON products.id = "productStatuses"."productId"
WHERE "coreProductId" IN (960479, 1003038)
  AND "retailerId" = 1104
ORDER BY "dateId" DESC
LIMIT 100;

SELECT *
FROM migration.ms2_migration_product_status
WHERE "productId" IN (318549754,
                      316563519,
                      315869423
    );


SELECT "coreProductId", "sourceId", date::date
FROM products
WHERE "coreProductId" = 1003038
  AND "retailerId" = 1104
ORDER BY "dateId" DESC
LIMIT 10;

SELECT *
FROM staging.product_status_history
WHERE "coreProductId" IN (960479, 1003038)
  AND "retailerId" = 1104
ORDER BY date DESC;

SELECT dd_date
FROM staging.load
WHERE (dd_retailer).id = 1104;


