SELECT *
FROM staging."coreProductsRetailers"
         CROSS JOIN LATERAL UNNEST("productsData")
WHERE "coreProductId" = '44'
  AND "retailerId" = 8;

SELECT JSON_AGG("coreProductsRetailers") AS results
FROM staging."coreProductsRetailers"
WHERE "coreProductId" = '44'
  AND "retailerId" = 8;

ALTER TYPE staging.product_ranking SET SCHEMA public;

SELECT PG_TERMINATE_BACKEND(31495);


SELECT "coreProductId",
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