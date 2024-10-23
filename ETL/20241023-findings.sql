WITH load AS (SELECT data
              FROM staging.load
              WHERE id = 299)
SELECT product
FROM load
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(data -> 'products') AS product
WHERE product ->> 'sourceId' = '6611448';

SELECT "coreProductId", *
FROM products
WHERE load_id = 299
  --  AND "sourceId" = '6611448'
  AND "productBrand" = '1000 Hour';


SELECT "coreProductId", *
FROM prod_fdw.products
WHERE "dateId" = 28759
  AND "sourceType" = 'coles'
-- AND "sourceId" = '6611448'
  AND "productBrand" = '1000 Hour'
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

SELECT *
FROM "coreProductBarcodes"
WHERE barcode = 'Coles_6611448';
SELECT *
FROM "coreProducts"
WHERE ean = 'Coles_6611448';
SELECT *
FROM "coreRetailerSources"
WHERE "sourceId" = '6611448';

SELECT *
FROM prod_fdw."coreProductBarcodes"
WHERE barcode = 'Coles_6611448';
SELECT *
FROM prod_fdw."coreProducts"
WHERE ean = 'Coles_6611448';
SELECT *
FROM prod_fdw."coreRetailerSources"
WHERE "sourceId" = '6611448';
