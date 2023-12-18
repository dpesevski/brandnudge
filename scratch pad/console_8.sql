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

SELECT JSON_AGG("coreProductsRetailers") AS results
FROM "coreProductsRetailers"
WHERE "coreProductId" = '44'
  AND "retailerId" = 8
  AND NOT is_delisted