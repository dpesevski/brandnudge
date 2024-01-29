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
FROM "coreRetailers"