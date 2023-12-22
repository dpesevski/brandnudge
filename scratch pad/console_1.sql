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
                         "productStatuses",
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
                  FROM staging.productsFull
                  WHERE "coreProductId" = 208
                    AND "retailerId" = 2)
SELECT "sourceType",
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
WHERE row_num = 1;

CREATE TYPE public.product_ranking AS
(
	date date,
	category character varying(255),
	"categoryType" character varying(255),
	"parentCategory" character varying(255),
	"productRank" integer,
	"sourceCategoryId" integer,
	featured boolean,
	"featuredRank" integer,
	"taxonomyId" integer
);

CREATE TABLE staging.coreProductsRetailers_product_ranking AS
SELECT "coreProductId",
       "retailerId",
       ARRAY_AGG((
                  date,
                  category,
                  "categoryType",
                  "parentCategory",
                  "productRank",
                  "sourceCategoryId",
                  featured,
                  "featuredRank",
                  "taxonomyId"
                     )::staging.product_ranking ORDER BY date DESC
           ) AS ranking
FROM products
         INNER JOIN "productsData" ON (products.id = "productId")
GROUP BY "coreProductId",
         "retailerId";

SELECT JSON_AGG(coreProductsRetailers_product_ranking)
FROM staging.coreProductsRetailers_product_ranking
WHERE "coreProductId" = '44'
  AND "retailerId" = 8;

SELECT COUNT(*)
FROM staging.coreProductsRetailers_product_ranking;
SELECT COUNT(*)
FROM staging."coreProductsRetailers";

drop table "coreProductsRetailers" ;
CREATE TABLE "coreProductsRetailers" AS
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
       is_delisted,
       ranking
FROM staging."coreProductsRetailers"
