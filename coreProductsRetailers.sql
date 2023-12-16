--[2023-12-15 23:33:07] 498,111 rows affected in 2 h 50 m 29 s 912 ms
CREATE TABLE temp."coreProductsRetailers" AS
WITH products AS (SELECT "sourceId",

                         "sourceType",
                         "coreProductId",
                         "retailerId",

                         "productId",
                         ean,
                         promotions,
                         date,
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
                         "productsData",
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

                         ("productStatuses")[1].status = 'de-listed' AS is_delisted,

                         ROW_NUMBER() OVER (PARTITION BY "coreProductId",
                             "retailerId" ORDER BY DATE DESC)        AS row_num
                  FROM TEMP.products)
SELECT row_num,
       "productId",
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
       "coreProductId",
       "retailerId",
       "createdAt",
       "updatedAt",
       "basePrice",
       "shelfPrice",
       "productsData",
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
FROM products
WHERE row_num = 1