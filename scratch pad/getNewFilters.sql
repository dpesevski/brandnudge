/*  getNewFilters:
    const availableProductGroups = await ProductGroupService.cacheUserProductGroups  */
SELECT id,
       name,
       "userId",
       "companyId",
       color,
       "coreProductsIds"
FROM "productGroups"
         LEFT OUTER JOIN (SELECT "productGroupId",
                                 ARRAY_AGG("coreProductId") FILTER (WHERE "coreProductId" IS NOT NULL) AS "coreProductsIds" --JSON_AGG
                          FROM "productGroupCoreProducts"
                          GROUP BY "productGroupId") AS "productGroupCoreProducts"
                         ON ("productGroupCoreProducts"."productGroupId" = "productGroups".id);
--WHERE "userId" = p_userId OR "companyId" = p_companyId;


/*  getNewFilters:
    const categoryIds = await db.companyCoreCategory.findAll    */
SELECT "categoryId"
FROM "companyCoreCategories";
/*
WHERE "companyId" = p_companyId
                    (p_categories = 'All' OR
                     "categoryId" = ANY (STRING_TO_ARRAY(p_categories)))
 */

/*  getNewFilters:
    const ownLabelManufacturerIds = await db.sequelize.query    */
SELECT "manufacturers"."id"
FROM "companyManufacturers"
         INNER JOIN "manufacturers" ON "manufacturers"."id" = "companyManufacturers"."manufacturerId"
WHERE "isOwnLabelManufacturer";
--AND "companyId" = ${companyId}

/*  makeFiltersRequests:
    const companyCategoriesCoreProducts = db.coreProduct.findAll
*/
SELECT id
FROM "coreProducts"
/*
WHERE p_getAllProducts
   OR "categoryId" = ANY (STRING_TO_ARRAY(p_categoryId))
 */


/*  makeFiltersRequests:
    const companyTaxonomiesCoreRetailers = db.coreRetailer.findAll

    25 companyId, with:
    - COUNT("retailerTaxonomyId") from 1 till 661
    - COUNT("coreProductId") from 5k till 30M
*/
SELECT "companyTaxonomies"."companyId", COUNT("coreProductId")
FROM "coreRetailers"
         INNER JOIN "retailerTaxonomies" USING ("retailerId")
         INNER JOIN "companyTaxonomies" ON ("retailerTaxonomies".id = "companyTaxonomies"."retailerTaxonomyId")
GROUP BY "companyId";
--WHERE "companyTaxonomies"."companyId" = p_companyId;
/*
WHERE p_getAllProducts
   OR "categoryId" = ANY (STRING_TO_ARRAY(p_categoryId))
 */


SELECT "companyTaxonomies"."companyId", COUNT("retailerId")
FROM "retailerTaxonomies"
         INNER JOIN "companyTaxonomies" ON ("retailerTaxonomies".id = "companyTaxonomies"."retailerTaxonomyId")
GROUP BY "companyId";

SELECT *
FROM "coreRetailers";

SELECT "companyId", COUNT(*)
FROM "coreRetailers"

         INNER JOIN "coreRetailerTaxonomies" ON ("coreRetailerTaxonomies"."coreRetailerId" = "coreRetailers".id)
         INNER JOIN "retailerTaxonomies" USING ("retailerId")
         INNER JOIN "productsData" USING ("productId")
         INNER JOIN "companyTaxonomies" ON ("retailerTaxonomies".id = "companyTaxonomies"."retailerTaxonomyId")
GROUP BY "companyId";


SELECT "coreRetailers"."coreProductId",
       "retailerTaxonomies".id
FROM "coreRetailers"
         INNER JOIN "coreRetailerTaxonomies" ON ("coreRetailerTaxonomies"."coreRetailerId" = "coreRetailers".id)
         INNER JOIN "retailerTaxonomies" USING ("retailerId")
         INNER JOIN "companyTaxonomies" ON ("retailerTaxonomies".id = "companyTaxonomies"."retailerTaxonomyId")
WHERE "companyTaxonomies"."companyId" = p_company_id;


SELECT "retailerId"
FROM "companyRetailers";

SELECT "coreProductId"
FROM "coreProductCountryData"
--WHERE "ownLabelManufacturerId" = ANY (p_ownLabelManufacturerIds)  AND "countryId" = p_countryId;

CREATE TABLE tests."coreProductRetailerTaxonomies" AS
SELECT "coreProductId",
       "taxonomyId" AS "retailerTaxonomyId",
       COUNT(*)     AS products_data_occurences
FROM products
         INNER JOIN "productsData" ON (products.id = "productsData"."productId")
GROUP BY "coreProductId", "taxonomyId";


CREATE INDEX coreProductRetailerTaxonomies_retailerTaxonomyId_index
    ON tests."coreProductRetailerTaxonomies" ("retailerTaxonomyId");


SELECT "coreProductRetailerTaxonomies"."coreProductId",
       "coreProductRetailerTaxonomies"."retailerTaxonomyId"
FROM tests."coreProductRetailerTaxonomies"
         INNER JOIN "companyTaxonomies" USING ("retailerTaxonomyId")
WHERE "companyTaxonomies"."companyId" = p_company_id;


SELECT "coreProductId",
       "retailerTaxonomies".id AS "retailerTaxonomyId",
       COUNT(*)                AS products_data_occurences
FROM "coreRetailers"
         INNER JOIN (SELECT "productId"::text,
                            "taxonomyId"
                     FROM "productsData") AS "productsData" USING ("productId")
         INNER JOIN "retailerTaxonomies" USING ("retailerId")
GROUP BY 1, 2;

