SET WORK_MEM = '4GB';

DROP TABLE IF EXISTS data_corr.fix_title_match_products;
CREATE TABLE data_corr.fix_title_match_products AS
SELECT products.id AS "productId",
       "coreProductId",
       retailers."countryId",
       "productTitle"
FROM products
         INNER JOIN retailers ON products."retailerId" = retailers.id
WHERE products.id >= 312647266
  AND products.load_id IS NOT NULL;
--[2024-12-16 18:26:52] 9,647,297 rows affected in 5 m 4 s 139 ms
--[2024-12-16 18:34:02] 2,337,507 rows affected in 2 m 22 s 165 ms
--[2024-12-16 19:07:09] 6,595,539 rows affected in 48 s 739 ms

CREATE INDEX fix_title_match_products_countryId_coreProductId_index
    ON data_corr.fix_title_match_products ("countryId", "coreProductId");


CREATE TABLE data_corr.fix_title_match_products_updated AS
WITH parentProdCountryData AS (SELECT "countryId", "coreProductId", title AS "titleParent"
                               FROM "coreProductCountryData")
SELECT "productId",
       compareTwoStrings("titleParent", "productTitle")::text AS "titleMatch"
FROM data_corr.fix_title_match_products products
         INNER JOIN parentProdCountryData USING ("coreProductId", "countryId");

CREATE INDEX fix_title_match_products_updated_productId_index
    ON data_corr.fix_title_match_products_updated ("productId");

UPDATE "aggregatedProducts"
SET "titleMatch"=updated."titleMatch"
FROM data_corr.fix_title_match_products_updated AS updated
WHERE "aggregatedProducts"."productId" = updated."productId"
  AND "aggregatedProducts"."titleMatch" != updated."titleMatch";
[2024-12-16 19:10:56] 1,337,749 ROWS affected IN 1 M 50 S 931 MS
--[2024-12-16 18:39:50] 520,345 rows affected in 3 m 14 s 939 ms



SET WORK_MEM = '4GB';

WITH tmp_product_pp AS (SELECT "products".id, "products"."coreProductId", retailers."countryId", "productTitle"
                        FROM "products"
                                 INNER JOIN retailers ON products."retailerId" = retailers.id
                        WHERE "retailerId" IN (2, 3, 8, 10, 13)
                          AND "dateId" IN (30112, 30079, 30013, 29980))
INSERT
INTO "aggregatedProducts" ("titleMatch",
                           "productId",
                           "createdAt",
                           "updatedAt")
SELECT compareTwoStrings("titleParent", "productTitle") AS "titleMatch",
       id                                               AS "productId",
       NOW()                                            AS "createdAt",
       NOW()                                               "updatedAt"
FROM tmp_product_pp
         INNER JOIN (SELECT "coreProductId", title AS "titleParent", "countryId"
                     FROM "coreProductCountryData") AS parentProdCountryData
                    USING ("coreProductId", "countryId")
ON CONFLICT ("productId")
WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
    DO NOTHING;