WITH load AS (SELECT data
              FROM staging.load
              WHERE id = 303)
SELECT product
FROM load
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(data -> 'products') AS product
WHERE product ->> 'sourceId' in ('3023057','3767780');

SELECT "coreProductId", *
FROM products
WHERE load_id = 303
  --  AND "sourceId" = '6611448'
  AND  "sourceId"  in ('3023057','3767780');



SELECT "coreProductId", *
FROM prod_fdw.products
WHERE "dateId" = 28792
  AND "sourceType" = 'coles'
-- AND "sourceId" = '6611448'
  AND  "sourceId"  in ('3023057','3767780')
ORDER BY "productTitle";

SELECT "coreProductId", "coreRetailerId", barcode, *
FROM "coreRetailerSources"
         INNER JOIN "coreRetailers" ON ("coreRetailers".id = "coreRetailerSources"."coreRetailerId")
         INNER JOIN "coreProductBarcodes" USING ("coreProductId")
WHERE "sourceId" in ('3023057','3767780');

SELECT "coreProductId", "coreRetailerId", barcode, *
FROM prod_fdw."coreRetailerSources"
         INNER JOIN prod_fdw."coreRetailers" ON ("coreRetailers".id = "coreRetailerSources"."coreRetailerId")
         INNER JOIN prod_fdw."coreProductBarcodes" USING ("coreProductId")
WHERE "sourceId"  in ('3023057','3767780');

SELECT *
FROM "coreProductBarcodes"
WHERE barcode  in ('Coles_3023057','Coles_3767780');
SELECT *
FROM "coreProducts"
WHERE ean  in ('Coles_3023057','Coles_3767780');
SELECT *
FROM "coreRetailerSources"
WHERE "sourceId" in ('3023057','3767780');

SELECT *
FROM prod_fdw."coreProductBarcodes"
WHERE barcode in ('Coles_3023057','Coles_3767780');
SELECT *
FROM prod_fdw."coreProducts"
WHERE ean  in ('Coles_3023057','Coles_3767780');
SELECT *
FROM prod_fdw."coreRetailerSources"
WHERE "sourceId"in ('3023057','3767780');
