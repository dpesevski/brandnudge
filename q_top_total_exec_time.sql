SELECT "coreProductId", "sourceCategoryId", "createdAt", "updatedAt"
FROM "coreProductSourceCategories" AS "coreProductSourceCategory"
WHERE "coreProductSourceCategory"."coreProductId" = $1
  AND "coreProductSourceCategory"."sourceCategoryId" = $2;
/*
calls	total_time
 4,498 	 1,859,199
count:  1,775,958


1) missing index on "coreProductId", "sourceCategoryId". This should be primary/cluster index.
2) 3180 duplicate records on "coreProductId", "sourceCategoryId".
    Two occurences:
        createdAt
        2022-10-07 12:43:34.805000 +00:00
        2021-01-14 18:04:57.480609 +00:00
*/


SELECT "id",
       "coreProductId",
       "countryId",
       "title",
       "image",
       "description",
       "features",
       "ingredients",
       "specification",
       "secondaryImages",
       "bundled",
       "disabled",
       "reviewed",
       "ownLabelManufacturerId",
       "createdAt",
       "updatedAt"
FROM "coreProductCountryData" AS "coreProductCountryData"
WHERE "coreProductCountryData"."coreProductId" = $1
  AND "coreProductCountryData"."countryId" = $2
LIMIT $3;

/*
calls	total_time
 9,003 	 1,667,868
count:  377,589


1) missing index on  "coreProductId","countryId". This should be primary/cluster index.
2) 3180 duplicate records on "coreProductId", "sourceCategoryId".
    Two occurences:
        createdAt
        2022-10-07 12:43:34.805000 +00:00
        2021-01-14 18:04:57.480609 +00:00
*/



SELECT "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt"
FROM "coreRetailerTaxonomies" AS "coreRetailerTaxonomy"
WHERE "coreRetailerTaxonomy"."coreRetailerId" = $1
  AND "coreRetailerTaxonomy"."retailerTaxonomyId" = $2;
SELECT "coreProduct"."id",
       "coreProduct"."ean",
       "coreProduct"."title",
       "coreProduct"."image",
       "coreProduct"."secondaryImages",
       "coreProduct"."bundled",
       "coreProduct"."description",
       "coreProduct"."features",
       "coreProduct"."ingredients",
       "coreProduct"."disabled",
       "coreProduct"."eanIssues",
       "coreProduct"."productOptions",
       "coreProduct"."specification",
       "coreProduct"."size",
       "coreProduct"."reviewed",
       "coreProduct"."createdAt",
       "coreProduct"."updatedAt",
       "coreProduct"."brandId",
       "coreProduct"."categoryId",
       "countryData"."id"                     AS "countryData.id",
       "countryData"."coreProductId"          AS "countryData.coreProductId",
       "countryData"."countryId"              AS "countryData.countryId",
       "countryData"."title"                  AS "countryData.title",
       "countryData"."image"                  AS "countryData.image",
       "countryData"."description"            AS "countryData.description",
       "countryData"."features"               AS "countryData.features",
       "countryData"."ingredients"            AS "countryData.ingredients",
       "countryData"."specification"          AS "countryData.specification",
       "countryData"."secondaryImages"        AS "countryData.secondaryImages",
       "countryData"."bundled"                AS "countryData.bundled",
       "countryData"."disabled"               AS "countryData.disabled",
       "countryData"."reviewed"               AS "countryData.reviewed",
       "countryData"."ownLabelManufacturerId" AS "countryData.ownLabelManufacturerId",
       "countryData"."createdAt"              AS "countryData.createdAt",
       "countryData"."updatedAt"              AS "countryData.updatedAt"
FROM "coreProducts" AS "coreProduct"
         LEFT OUTER JOIN "coreProductCountryData" AS "countryData"
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = $1
WHERE "coreProduct"."productOptions" IN ($2, $3)
  AND "coreProduct"."id" = $4;
SELECT "id",
       "date",
       "sourceType",
       "ean",
       "sourceId",
       "productBrand",
       "productTitle",
       "productTitleDetail",
       "productImage",
       "productDescription",
       "productInfo",
       "basePrice",
       "shelfPrice",
       "promotedPrice",
       "productInStock",
       "productInListing",
       "reviewsCount",
       "reviewsStars",
       "promotions",
       "promotionDescription",
       "secondaryImages",
       "eposId",
       "multibuy",
       "features",
       "size",
       "sizeUnit",
       "pricePerWeight",
       "nutritional",
       "href",
       "createdAt",
       "updatedAt",
       "coreProductId",
       "dateId",
       "imageId",
       "retailerId"
FROM "products" AS "product"
WHERE "product"."sourceId" = $1
  AND "product"."retailerId" = $2
  AND "product"."dateId" = $3
LIMIT $4;
SELECT "id",
       "productId",
       "category",
       "categoryType",
       "parentCategory",
       "featured",
       "featuredRank",
       "productRank",
       "pageNumber",
       "screenshot",
       "sourceCategoryId",
       "taxonomyId"
FROM "productsData" AS "productsData"
WHERE "productsData"."productId" = $1
  AND "productsData"."category" = $2
  AND "productsData"."categoryType" = $3
  AND "productsData"."featured" = $4
  AND "productsData"."featuredRank" = $5
  AND "productsData"."productRank" = $6
  AND "productsData"."parentCategory" = $7
  AND "productsData"."pageNumber" = $8
  AND "productsData"."screenshot" = $9
  AND "productsData"."taxonomyId" = $10
  AND "productsData"."sourceCategoryId" = $11
LIMIT $12;