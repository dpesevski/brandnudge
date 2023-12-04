/*  1st batch:  some sample queries for your testing */

SELECT "product"."id",
       "product"."date",
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
       "product"."dateId",
       "product"."imageId",
       "product"."retailerId",
       "statusItem"."id"                          AS "statusItem.id",
       "statusItem"."productId"                   AS "statusItem.productId",
       "statusItem"."status"                      AS "statusItem.status",
       "statusItem"."screenshot"                  AS "statusItem.screenshot",
       "statusItem"."createdAt"                   AS "statusItem.createdAt",
       "statusItem"."updatedAt"                   AS "statusItem.updatedAt",
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
FROM "products" AS "product"
         INNER JOIN "productStatuses" AS "statusItem" ON "product"."id" = "statusItem"."productId"
         INNER JOIN "retailers" AS "retailer" ON "product"."retailerId" = "retailer"."id" AND
                                                 "retailer"."id" IN (E'1', E'8', E'2', E'3', E'9', E'10', E'81')
         INNER JOIN "coreProducts" AS "coreProduct" ON "product"."coreProductId" = "coreProduct"."id"
    AND "coreProduct"."productOptions" = FALSE
    AND "coreProduct"."id" IN
        ('2294', '2338', '2342', '2343', '2361', '2368', '2382', '2404', '2405', '2420', '2465', '2474', '2521', '2546',
         '2824', '2836', '2843', '2915', '2942', '2960', '2972', '7314', '7319', '7323', '7329', '7330', '7462', '7497',
         '7503', '7511', '7627', '7643', '8398', '8405', '8924', '11184', '15083', '19347', '19702', '26368', '45395',
         '45396', '49108', '58628', '62969', '66499', '92857', '102644', '104626', '136544', '136548', '136553',
         '136560', '142228', '260177', '260277', '332509', '463742', '463744', '506355', '778875')
         LEFT OUTER JOIN "coreProductCountryData" AS "coreProduct->countryData"
                         ON "coreProduct"."id" = "coreProduct->countryData"."coreProductId"
                             AND "coreProduct->countryData"."countryId" = 1
WHERE "product"."dateId" IN
      (5202, 5203, 5204, 5205, 5206, 5207, 5208, 5209, 5210, 5211, 5230, 5263, 5296, 5329, 5330, 5331, 5332, 5333, 5334,
       5335, 5362,
       5395, 5396, 5397, 5398, 5399, 5400, 5401, 5402, 5403, 5404, 5405, 5406, 5407, 5408, 5409, 5410, 5411, 5412, 5413,
       5414, 5415,
       5416, 5417, 5418, 5419, 5420, 5421, 5422, 5423, 5424, 5425, 5426, 5427, 5428, 5429, 5430, 5431, 5432, 5433, 5434,
       5435, 5461,
       5462, 5463, 5464, 5465, 5466, 5467, 5468, 5469, 5470, 5471, 5472, 5473, 5474, 5475, 5476, 5477, 5478, 5479, 5480,
       5494, 5527,
       5528, 5529, 5530, 5531, 5532, 5560, 5561, 5593, 5594, 5595, 5596, 5597, 5598, 5599, 5600, 5601, 5626, 5627, 5628,
       5629, 5630,
       5631, 5632, 5633, 5634, 5635, 5636, 5637, 5638, 5639, 5640, 5659, 5660, 5661, 5662, 5663, 5664, 5665, 5692, 5725,
       5726, 5727,
       5728, 5729, 5730, 5731, 5732, 5733, 5734, 5735, 5736, 5737, 5738, 5758, 5759, 5760, 5791, 5792, 5793, 5824, 5825,
       5857, 5890,
       5891, 5892, 5893, 5894, 5923, 5924, 5925, 5926, 5927, 5928, 5956, 5957, 5989, 6022, 6023, 6024, 6025, 6026, 6027,
       6055, 6056,
       6057, 6058, 6088, 6089, 6090, 6121, 6154, 6187, 6188, 6220, 6221, 6222, 6223, 6253, 6254, 6255, 6256, 6257, 6258,
       6259, 6286,
       6319, 6320, 6352, 6353, 6385, 6386, 6387, 6418, 6419, 6420, 6451, 6484, 6517, 6550, 6551, 6583, 6584, 6616, 6617,
       6649, 6682,
       6715, 6748, 6781, 6782, 6814, 6847, 6880, 6881, 6913, 6946, 6979, 7012, 7045, 7078, 7111, 7112, 7113, 7114, 7115,
       7116, 7117,
       7118, 7119, 7120, 7121, 7122, 7123, 7124, 7144, 7177, 7210, 7243, 7276, 7309, 7342, 7375, 7408, 7441, 7474, 7507,
       7540, 7573,
       7606, 7639, 7672, 7705, 7738, 7771, 7804, 7837, 7870, 7903, 7936, 7969, 8002, 8035, 8068, 8101, 8134, 8167, 8200,
       8233, 8266,
       8299, 8332, 8365, 8398, 8431, 8464, 8497, 8530, 8563, 8596, 8629, 8662, 8695, 8728, 8761, 8794, 8827, 8860, 8893,
       8926, 8959,
       8992, 9025, 9058, 9091, 9124, 9157, 9190, 9223, 9256, 9289, 9322, 9355, 9388, 9421, 9454, 9487, 9520, 9553, 9586,
       9619, 9652,
       9685, 9718, 9751, 9784, 9817, 9850, 9883, 9916, 9949, 9982, 10015, 10048, 10081, 10114, 10147, 10180, 10213,
       10246, 10279, 10312, 10345);

SELECT "coreProductId", "sourceCategoryId", "createdAt", "updatedAt"
FROM "coreProductSourceCategories" AS "coreProductSourceCategory"
WHERE "coreProductSourceCategory"."coreProductId" = $1
  AND "coreProductSourceCategory"."sourceCategoryId" = $2;
SELECT "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt"
FROM "coreRetailerTaxonomies" AS "coreRetailerTaxonomy"
WHERE "coreRetailerTaxonomy"."coreRetailerId" = $1
  AND "coreRetailerTaxonomy"."retailerTaxonomyId" = $2;
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
WHERE "product"."ean" = $1
  AND "product"."retailerId" = $2
  AND "product"."dateId" = $3
LIMIT $4;
SELECT "id",
       "coreProductId",
       "countryId",
       "title",
       "image",
       "description",
       "features",
       "ingredients",
       "specification",
       "createdAt",
       "updatedAt"
FROM "coreProductCountryData" AS "coreProductCountryData"
WHERE "coreProductCountryData"."coreProductId" = $1
  AND "coreProductCountryData"."countryId" = $2
LIMIT $3;
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
       "countryData"."id"            AS "countryData.id",
       "countryData"."coreProductId" AS "countryData.coreProductId",
       "countryData"."countryId"     AS "countryData.countryId",
       "countryData"."title"         AS "countryData.title",
       "countryData"."image"         AS "countryData.image",
       "countryData"."description"   AS "countryData.description",
       "countryData"."features"      AS "countryData.features",
       "countryData"."ingredients"   AS "countryData.ingredients",
       "countryData"."specification" AS "countryData.specification",
       "countryData"."createdAt"     AS "countryData.createdAt",
       "countryData"."updatedAt"     AS "countryData.updatedAt"
FROM "coreProducts" AS "coreProduct"
         LEFT OUTER JOIN "coreProductCountryData" AS "countryData"
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = $1
WHERE "coreProduct"."productOptions" IN ($2, $3)
  AND "coreProduct"."id" = $4;


/* 2nd batch: some top SQL for your reference:    */
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
WHERE "coreProductCountryData"."coreProductId" = ?
  AND "coreProductCountryData"."countryId" = ?
LIMIT ?;

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
WHERE "product"."sourceId" = '313512653'
  AND "product"."retailerId" = 1
  AND "product"."dateId" = 18067
LIMIT 1;

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
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = 1
WHERE "coreProduct"."productOptions" IN (TRUE, FALSE)
  AND "coreProduct"."id" = 16760;
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
WHERE "productsData"."productId" = 153467306
  AND "productsData"."category" = 'Pringles'
  AND "productsData"."categoryType" = 'search'
  AND "productsData"."featured" = FALSE
  AND "productsData"."featuredRank" = 14
  AND "productsData"."productRank" = 14
  AND "productsData"."parentCategory" = ''
  AND "productsData"."pageNumber" = '1'
  AND "productsData"."screenshot" = ''
  AND "productsData"."taxonomyId" = 23230
  AND "productsData"."sourceCategoryId" = 731
LIMIT 1;




/*  3rd batch: */
SELECT "product"."id",
       "product"."coreProductId",
       "product"."basePrice",
       "product"."shelfPrice",
       "product"."promotedPrice",
       "product"."sourceType",
       "product"."retailerId",
       "product"."date",
       "product"."promotions",
       "product"."promotionDescription"
FROM "products" AS "product"
         INNER JOIN "productStatuses" AS "status"
                    ON "product"."id" = "status"."productId" AND "status"."status" != 'de-listed'
WHERE "product"."coreProductId" IN
      ('2294', '2338', '2342', '2343', '2361', '2368', '2382', '2404', '2405', '2420', '2465', '2474', '2521', '2546',
       '2824', '2836', '2843', '2915', '2942', '2960', '2972', '7314', '7319', '7323', '7329', '7330', '7462', '7497',
       '7503', '7511', '7627', '7643', '8398', '8405', '8924', '11184', '15083', '19347', '19702', '26368', '45395',
       '45396', '49108', '58628', '62969', '66499', '92857', '102644', '104626', '136544', '136548', '136553', '136560',
       '142228', '260177', '260277', '332509', '463742', '463744', '506355', '778875')
  AND "product"."dateId" IN
      (5202, 5203, 5204, 5205, 5206, 5207, 5208, 5209, 5210, 5211, 5230, 5263, 5296, 5329, 5330, 5331, 5332, 5333, 5334,
       5335, 5362, 5395, 5396, 5397, 5398, 5399, 5400, 5401, 5402, 5403, 5404, 5405, 5406, 5407, 5408, 5409, 5410, 5411,
       5412, 5413, 5414, 5415, 5416, 5417, 5418, 5419, 5420, 5421, 5422, 5423, 5424, 5425, 5426, 5427, 5428, 5429, 5430,
       5431, 5432, 5433, 5434, 5435, 5461, 5462, 5463, 5464, 5465, 5466, 5467, 5468, 5469, 5470, 5471, 5472, 5473, 5474,
       5475, 5476, 5477, 5478, 5479, 5480, 5494, 5527, 5528, 5529, 5530, 5531, 5532, 5560, 5561, 5593, 5594, 5595, 5596,
       5597, 5598, 5599, 5600, 5601, 5626, 5627, 5628, 5629, 5630, 5631, 5632, 5633, 5634, 5635, 5636, 5637, 5638, 5639,
       5640, 5659, 5660, 5661, 5662, 5663, 5664, 5665, 5692, 5725, 5726, 5727, 5728, 5729, 5730, 5731, 5732, 5733, 5734,
       5735, 5736, 5737, 5738, 5758, 5759, 5760, 5791, 5792, 5793, 5824, 5825, 5857, 5890, 5891, 5892, 5893, 5894, 5923,
       5924, 5925, 5926, 5927, 5928, 5956, 5957, 5989, 6022, 6023, 6024, 6025, 6026, 6027, 6055, 6056, 6057, 6058, 6088,
       6089, 6090, 6121, 6154, 6187, 6188, 6220, 6221, 6222, 6223, 6253, 6254, 6255, 6256, 6257, 6258, 6259, 6286, 6319,
       6320, 6352, 6353, 6385, 6386, 6387, 6418, 6419, 6420, 6451, 6484, 6517, 6550, 6551, 6583, 6584, 6616, 6617, 6649,
       6682, 6715, 6748, 6781, 6782, 6814, 6847, 6880, 6881, 6913, 6946, 6979, 7012, 7045, 7078, 7111, 7112, 7113, 7114,
       7115, 7116, 7117, 7118, 7119, 7120, 7121, 7122, 7123, 7124, 7144, 7177, 7210, 7243, 7276, 7309, 7342, 7375, 7408,
       7441, 7474, 7507, 7540, 7573, 7606, 7639, 7672, 7705, 7738, 7771, 7804, 7837, 7870, 7903, 7936, 7969, 8002, 8035,
       8068, 8101, 8134, 8167, 8200, 8233, 8266, 8299, 8332, 8365, 8398, 8431, 8464, 8497, 8530, 8563, 8596, 8629, 8662,
       8695, 8728, 8761, 8794, 8827, 8860, 8893, 8926, 8959, 8992, 9025, 9058, 9091, 9124, 9157, 9190, 9223, 9256, 9289,
       9322, 9355, 9388, 9421, 9454, 9487, 9520, 9553, 9586, 9619, 9652, 9685, 9718, 9751, 9784, 9817, 9850, 9883, 9916,
       9949, 9982, 10015, 10048, 10081, 10114, 10147, 10180, 10213, 10246, 10279, 10312, 10345)
  AND "product"."retailerId" IN ('1', '8', '2', '3', '9', '10', '81');
