WITH query AS (SELECT "coreProductId",
                      "retailerId",
                      "sourceType",
                      ean,
                      promotions,
                      date,
                      "sourceId",
                      "productBrand",
                      "productTitle",
                      "promotedPrice",
                      "productInStock",
                      "productInListing",
                      "reviewsCount",
                      "reviewsStars",
                      "eposId",
                      multibuy,
                      "createdAt",
                      "updatedAt",
                      "basePrice",
                      "shelfPrice",
                      "promotionDescription",
                      features,
                      "productImage",
                      "secondaryImages",
                      "productDescription",
                      "productInfo",
                      "imageId",
                      size,
                      "pricePerWeight",
                      href,
                      nutritional,
                      "productTitleDetail",
                      "sizeUnit",
                      is_delisted
               FROM "coreProductsRetailers"
               WHERE "coreProductId" = '44'
                 AND "retailerId" = 8
                 AND NOT is_delisted)
SELECT JSON_AGG(query) AS results
FROM query;


WITH query AS (SELECT "product"."date",
                      "product"."sourceType",
                      "product"."ean",
                      "product"."sourceId",
                      "product"."productBrand",
                      "product"."productTitle",
                      "product"."productTitleDetail",
                      "product"."productImage",
                      "product"."productDescription",
                      "product"."productInfo",
                      "product"."basePrice",
                      "product"."shelfPrice",
                      "product"."promotedPrice",
                      "product"."productInStock",
                      "product"."productInListing",
                      "product"."reviewsCount",
                      "product"."reviewsStars",
                      "product"."promotions",
                      "product"."promotionDescription",
                      "product"."secondaryImages",
                      "product"."eposId",
                      "product"."multibuy",
                      "product"."features",
                      "product"."size",
                      "product"."sizeUnit",
                      "product"."pricePerWeight",
                      "product"."nutritional",
                      "product"."href",
                      "product"."createdAt",
                      "product"."updatedAt",
                      "product"."coreProductId",
                      "product"."imageId",
                      "product"."retailerId",

                      is_delisted,

                      "retailer"."id"                            AS "retailer.id",
                      "retailer"."name"                          AS "retailer.name",
                      "retailer"."color"                         AS "retailer.color",
                      "retailer"."logo"                          AS "retailer.logo",
                      "retailer"."countryId"                     AS "retailer.countryId",
                      "retailer"."createdAt"                     AS "retailer.createdAt",
                      "retailer"."updatedAt"                     AS "retailer.updatedAt",
                      "coreProduct"."id"                         AS "coreProduct.id",
                      "coreProduct"."ean"                        AS "coreProduct.ean",
                      "coreProduct"."title"                      AS "coreProduct.title",
                      "coreProduct"."image"                      AS "coreProduct.image",
                      "coreProduct"."secondaryImages"            AS "coreProduct.secondaryImages",
                      "coreProduct"."bundled"                    AS "coreProduct.bundled",
                      "coreProduct"."description"                AS "coreProduct.description",
                      "coreProduct"."features"                   AS "coreProduct.features",
                      "coreProduct"."ingredients"                AS "coreProduct.ingredients",
                      "coreProduct"."disabled"                   AS "coreProduct.disabled",
                      "coreProduct"."eanIssues"                  AS "coreProduct.eanIssues",
                      "coreProduct"."productOptions"             AS "coreProduct.productOptions",
                      "coreProduct"."specification"              AS "coreProduct.specification",
                      "coreProduct"."size"                       AS "coreProduct.size",
                      "coreProduct"."reviewed"                   AS "coreProduct.reviewed",
                      "coreProduct"."createdAt"                  AS "coreProduct.createdAt",
                      "coreProduct"."updatedAt"                  AS "coreProduct.updatedAt",
                      "coreProduct"."brandId"                    AS "coreProduct.brandId",
                      "coreProduct"."categoryId"                 AS "coreProduct.categoryId",
                      "coreProduct->countryData"."id"            AS "coreProduct.countryData.id",
                      "coreProduct->countryData"."coreProductId" AS "coreProduct.countryData.coreProductId",
                      "coreProduct->countryData"."countryId"     AS "coreProduct.countryData.countryId",
                      "coreProduct->countryData"."title"         AS "coreProduct.countryData.title",
                      "coreProduct->countryData"."image"         AS "coreProduct.countryData.image",
                      "coreProduct->countryData"."description"   AS "coreProduct.countryData.description",
                      "coreProduct->countryData"."features"      AS "coreProduct.countryData.features",
                      "coreProduct->countryData"."ingredients"   AS "coreProduct.countryData.ingredients",
                      "coreProduct->countryData"."specification" AS "coreProduct.countryData.specification",
                      "coreProduct->countryData"."createdAt"     AS "coreProduct.countryData.createdAt",
                      "coreProduct->countryData"."updatedAt"     AS "coreProduct.countryData.updatedAt"
               FROM "coreProductsRetailers" "product"

                        INNER JOIN "retailers" AS "retailer" ON "product"."retailerId" = "retailer"."id" AND
                                                                "retailer"."id" IN
                                                                (E'1', E'8', E'2', E'3', E'9', E'10', E'81')
                        INNER JOIN "coreProducts" AS "coreProduct" ON "product"."coreProductId" = "coreProduct"."id"
                   AND "coreProduct"."productOptions" = FALSE
                   AND "coreProduct"."id" IN
                       ('2294', '2338', '2342', '2343', '2361', '2368', '2382', '2404', '2405', '2420', '2465', '2474',
                        '2521', '2546',
                        '2824', '2836', '2843', '2915', '2942', '2960', '2972', '7314', '7319', '7323', '7329', '7330',
                        '7462', '7497',
                        '7503', '7511', '7627', '7643', '8398', '8405', '8924', '11184', '15083', '19347', '19702',
                        '26368', '45395',
                        '45396', '49108', '58628', '62969', '66499', '92857', '102644', '104626', '136544', '136548',
                        '136553',
                        '136560', '142228', '260177', '260277', '332509', '463742', '463744', '506355', '778875')
                        LEFT OUTER JOIN "coreProductCountryData" AS "coreProduct->countryData"
                                        ON "coreProduct"."id" = "coreProduct->countryData"."coreProductId"
                                            AND "coreProduct->countryData"."countryId" = 1)
SELECT JSON_AGG(query) AS results
FROM query;

SELECT JSON_AGG("coreProductsRetailers") AS results
FROM "coreProductsRetailers"
WHERE "coreProductId" = '44'
  AND "retailerId" = 8
  AND NOT is_delisted