the product page:
https://www.tesco.com/groceries/en-GB/products/311954680
the ean(OR gtin) IN website = 4025500277239

SELECT DISTINCT ean, "coreProductId"
FROM "products"
WHERE "sourceId" = '311954680'
SELECT *
FROM "coreRetailers"
WHERE "productId" = '311954680'
LIMIT 1
SELECT *
FROM "coreProducts"
WHERE id = 142552
SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" = 142552 https://groceries.morrisons.com/products/sailor-jerry-spiced-rum-119527011
the ean(OR gtin) IN website = 5010327405223

SELECT *
FROM "products"
WHERE "sourceId" = '119527011'
LIMIT 1
SELECT *
FROM "coreRetailers"
WHERE "productId" = '119527011'
LIMIT 1
SELECT *
FROM "coreProducts"
WHERE id = 264336
SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" = 264336


/*
https://www.tesco.com/groceries/en-GB/products/311954680
the ean(OR gtin) IN website = 4025500277239
*/

SELECT DISTINCT ean, "coreProductId"
FROM "products"
WHERE "sourceId" = '311954680';
SELECT *
FROM "coreRetailers"
WHERE "productId" = '311954680';
SELECT *
FROM "coreProducts"
WHERE id = 142552;
SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" = 142552;

/*
https://groceries.morrisons.com/products/sailor-jerry-spiced-rum-119527011
the ean(or gtin) in website = 5010327405223
*/
SELECT DISTINCT ean, "coreProductId"
FROM "products"
WHERE "sourceId" = '119527011';
SELECT *
FROM "coreRetailers"
WHERE "productId" = '119527011';
SELECT *
FROM "coreProducts"
WHERE id = 264336;
SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" = 264336;

/*
    TO DO: Add foreign keys in products, coreProducts, coreProductBarcodes, coreRetailers

    There are no referential constraints in these tables enforcing the relationship between the
    - retailerId/sourceId,
    - ean(barcode), and
    - coreProductId

    a) coreRetailers (retailerId/sourceId) should relate many-to-1 with coreProductBarcodes (barcode)
       The current model(data) relates coreRetailers directly with coreProducts (coreProductId).
        TO DO: add the FK and migrate the data.

    b) coreProducts should relate 1-to-many with coreProductBarcodes as there can be more then one ean(barcode) for a specific coreProduct, e.g., same product but with different quantity/size.

1- coreProduct                      id=1
    1.1. coreProductBarcodes        coreProduct=1, barcode1: 1-A, barcode2:1-B
        1.1.1 coreRetailer          coreProduct=1, barcode1: 1-A,  retailerid=R1, sourceid=r1-1-A,       retailerid=R2, sourceid=r3-1-A
    */

WITH products AS (SELECT DISTINCT "coreProductId", ean, "retailerId", "sourceId"
                  FROM "products"
                  WHERE "coreProductId" = 142552
   -- WHERE "coreProductId" IN (142552, 777107)--, 50470)
),
     "coreProducts" AS (SELECT *
                        FROM "coreProducts"
                                 INNER JOIN (SELECT DISTINCT ean FROM products) AS products USING (ean)),
     "coreProductBarcodes" AS (SELECT DISTINCT "coreProductBarcodes".*
                               FROM "coreProductBarcodes"
                                        INNER JOIN (SELECT DISTINCT id, ean FROM "coreProducts") AS "coreProducts"
                                                   ON ("coreProductId" = "coreProducts".id OR ean = barcode)),
     "coreRetailers" AS (SELECT *
                         FROM "coreRetailers"
                                  INNER JOIN (SELECT DISTINCT "retailerId", products."sourceId" AS "productId"
                                              FROM products) AS products
                                             USING ("retailerId", "productId")),
     "coreRetailers_coreProductId" AS (SELECT DISTINCT "coreProductId"
                                       FROM "coreRetailers"),
     "missing_rec_in_coreProducts" AS (SELECT *
                                       FROM "coreRetailers_coreProductId"
                                                FULL OUTER JOIN "coreProducts" ON ("coreProductId" = "coreProducts".id)),
     "coreRetailers_w_coreProducts" AS (SELECT "coreRetailers".*,
                                               "coreProductId" = missing_coreProductId AS is_missing_in_core_products
                                        FROM "coreRetailers"
                                                 INNER JOIN (SELECT "retailerId",
                                                                    "productId",
                                                                    "coreProductId" AS missing_coreProductId
                                                             FROM "coreRetailers"
                                                                      INNER JOIN (SELECT "coreProductId"
                                                                                  FROM "missing_rec_in_coreProducts"
                                                                                  WHERE id IS NULL) AS missing_core_id
                                                                                 USING ("coreProductId")) "coreRetailers_w_missing_rec_in_coreProducts"
                                                            USING ("retailerId", "productId"))
SELECT *
FROM "coreRetailers_w_coreProducts";



SELECT *
FROM "coreProductBarcodes" where "coreProductId" in ('142552','777107');

SELECT *
FROM "coreProducts" where id in (50470);

SELECT *
FROM "coreRetailers" where "retailerId"=3 and "productId"='7553454';


SELECT DISTINCT "coreProductId", ean, "retailerId", "sourceId"
FROM public.products
WHERE "coreProductId" IN (777107)

SELECT DISTINCT "coreProductId", ean, "retailerId", "sourceId"
FROM products
WHERE ean IN ('4025500165413', '4025500277239', 'B09WZDDL53')

SELECT DISTINCT ean, "coreProductId", "sourceId", "retailerId", "productTitle"
FROM "products"
WHERE "coreProductId" IN ('50470', '142552', '777107')
   OR ean IN ('4025500165413', '4025500277239')

--WHERE "sourceId" = '311954680';