-- do we need all the attributes?

with results as (SELECT "product"."id",
       "product"."productTitle",
       "product"."promotedPrice",
       "product"."basePrice",
       "product"."coreProductId",
       "product"."date",
       "product"."promotionDescription",
       "product"."sourceId",
       "product"."sourceType"                                                AS "retailerId",
       "retailer"."id"                                                       AS "retailer.id",
       "retailer"."name"                                                     AS "retailer.name",
       "retailer"."color"                                                    AS "retailer.color",
       "retailer"."logo"                                                     AS "retailer.logo",
       "retailer"."countryId"                                                AS "retailer.countryId",
       "retailer"."createdAt"                                                AS "retailer.createdAt",
       "retailer"."updatedAt"                                                AS "retailer.updatedAt",
       "productPromotions"."id"                                              AS "productPromotions.id",
       "productPromotions"."retailerPromotionId"                             AS "productPromotions.retailerPromotionId",
       "productPromotions"."productId"                                       AS "productPromotions.productId",
       "productPromotions"."promoId"                                         AS "productPromotions.promoId",
       "productPromotions"."description"                                     AS "productPromotions.description",
       "productPromotions"."startDate"                                       AS "productPromotions.startDate",
       "productPromotions"."endDate"                                         AS "productPromotions.endDate",
       "productPromotions"."createdAt"                                       AS "productPromotions.createdAt",
       "productPromotions"."updatedAt"                                       AS "productPromotions.updatedAt",
       "productPromotions->retailerPromotion"."id"                           AS "productPromotions.retailerPromotion.id",
       "productPromotions->retailerPromotion"."retailerId"                   AS "productPromotions.retailerPromotion.retailerId",
       "productPromotions->retailerPromotion"."promotionMechanicId"          AS "productPromotions.retailerPromotion.promotionMechanicId",
       "productPromotions->retailerPromotion"."regexp"                       AS "productPromotions.retailerPromotion.regexp",
       "productPromotions->retailerPromotion"."createdAt"                    AS "productPromotions.retailerPromotion.createdAt",
       "productPromotions->retailerPromotion"."updatedAt"                    AS "productPromotions.retailerPromotion.updatedAt",
       "productPromotions->retailerPromotion->promotionMechanic"."id"        AS "productPromotions.retailerPromotion.promotionMechanic.id",
       "productPromotions->retailerPromotion->promotionMechanic"."name"      AS "productPromotions.retailerPromotion.promotionMechanic.name",
       "productPromotions->retailerPromotion->promotionMechanic"."createdAt" AS "productPromotions.retailerPromotion.promotionMechanic.createdAt",
       "productPromotions->retailerPromotion->promotionMechanic"."updatedAt" AS "productPromotions.retailerPromotion.promotionMechanic.updatedAt",
       "coreProduct"."id"                                                    AS "coreProduct.id",
       "coreProduct"."ean"                                                   AS "coreProduct.ean",
       "coreProduct"."title"                                                 AS "coreProduct.title",
       "coreProduct"."image"                                                 AS "coreProduct.image",
       "coreProduct"."secondaryImages"                                       AS "coreProduct.secondaryImages",
       "coreProduct"."bundled"                                               AS "coreProduct.bundled",
       "coreProduct"."description"                                           AS "coreProduct.description",
       "coreProduct"."features"                                              AS "coreProduct.features",
       "coreProduct"."ingredients"                                           AS "coreProduct.ingredients",
       "coreProduct"."disabled"                                              AS "coreProduct.disabled",
       "coreProduct"."eanIssues"                                             AS "coreProduct.eanIssues",
       "coreProduct"."productOptions"                                        AS "coreProduct.productOptions",
       "coreProduct"."specification"                                         AS "coreProduct.specification",
       "coreProduct"."size"                                                  AS "coreProduct.size",
       "coreProduct"."reviewed"                                              AS "coreProduct.reviewed",
       "coreProduct"."createdAt"                                             AS "coreProduct.createdAt",
       "coreProduct"."updatedAt"                                             AS "coreProduct.updatedAt",
       "coreProduct"."brandId"                                               AS "coreProduct.brandId",
       "coreProduct"."categoryId"                                            AS "coreProduct.categoryId",
       "coreProduct->countryData"."id"                                       AS "coreProduct.countryData.id",
       "coreProduct->countryData"."coreProductId"                            AS "coreProduct.countryData.coreProductId",
       "coreProduct->countryData"."countryId"                                AS "coreProduct.countryData.countryId",
       "coreProduct->countryData"."title"                                    AS "coreProduct.countryData.title",
       "coreProduct->countryData"."image"                                    AS "coreProduct.countryData.image",
       "coreProduct->countryData"."description"                              AS "coreProduct.countryData.description",
       "coreProduct->countryData"."features"                                 AS "coreProduct.countryData.features",
       "coreProduct->countryData"."ingredients"                              AS "coreProduct.countryData.ingredients",
       "coreProduct->countryData"."specification"                            AS "coreProduct.countryData.specification",
       "coreProduct->countryData"."secondaryImages"                          AS "coreProduct.countryData.secondaryImages",
       "coreProduct->countryData"."bundled"                                  AS "coreProduct.countryData.bundled",
       "coreProduct->countryData"."disabled"                                 AS "coreProduct.countryData.disabled",
       "coreProduct->countryData"."reviewed"                                 AS "coreProduct.countryData.reviewed",
       "coreProduct->countryData"."ownLabelManufacturerId"                   AS "coreProduct.countryData.ownLabelManufacturerId",
       "coreProduct->countryData"."brandbankManaged"                         AS "coreProduct.countryData.brandbankManaged",
       "coreProduct->countryData"."createdAt"                                AS "coreProduct.countryData.createdAt",
       "coreProduct->countryData"."updatedAt"                                AS "coreProduct.countryData.updatedAt",
       "coreProduct->productBrand"."id"                                      AS "coreProduct.productBrand.id",
       "coreProduct->productBrand"."name"                                    AS "coreProduct.productBrand.name",
       "coreProduct->productBrand"."checkList"                               AS "coreProduct.productBrand.checkList",
       "coreProduct->productBrand"."color"                                   AS "coreProduct.productBrand.color",
       "coreProduct->productBrand"."createdAt"                               AS "coreProduct.productBrand.createdAt",
       "coreProduct->productBrand"."updatedAt"                               AS "coreProduct.productBrand.updatedAt",
       "coreProduct->productBrand"."manufacturerId"                          AS "coreProduct.productBrand.manufacturerId",
       "coreProduct->productBrand"."brandId"                                 AS "coreProduct.productBrand.brandId"
FROM "products" AS "product"
         LEFT OUTER JOIN "retailers" AS "retailer" ON "product"."retailerId" = "retailer"."id"
         INNER JOIN "promotions" AS "productPromotions" ON "product"."id" = "productPromotions"."productId"
         INNER JOIN "retailerPromotions" AS "productPromotions->retailerPromotion"
                    ON "productPromotions"."retailerPromotionId" = "productPromotions->retailerPromotion"."id"
         INNER JOIN "promotionMechanics" AS "productPromotions->retailerPromotion->promotionMechanic"
                    ON "productPromotions->retailerPromotion"."promotionMechanicId" =
                       "productPromotions->retailerPromotion->promotionMechanic"."id"
         INNER JOIN "coreProducts" AS "coreProduct"
                    ON "product"."coreProductId" = "coreProduct"."id" AND "coreProduct"."productOptions" = FALSE
         LEFT OUTER JOIN "coreProductCountryData" AS "coreProduct->countryData"
                         ON "coreProduct"."id" = "coreProduct->countryData"."coreProductId" AND
                            "coreProduct->countryData"."countryId" = 1
         INNER JOIN "brands" AS "coreProduct->productBrand"
                    ON "coreProduct"."brandId" = "coreProduct->productBrand"."id"
WHERE "product"."coreProductId" IN
      ('1754', '4064', '4298', '4299', '4300', '4304', '4331', '4364', '4372', '4373', '4377', '4483', '4572', '4657',
       '4691', '5015', '11317', '11564', '11566', '11579', '14398', '16546', '16547', '16548', '16936', '19032',
       '20084', '20581', '20598', '21753', '21806', '22836', '24269', '24923', '26148', '26155', '26349', '37606',
       '38006', '42148', '42763', '43008', '44825', '45525', '45750', '45912', '48006', '52635', '62359', '62361',
       '63173', '63192', '64020', '69967', '82042', '82046', '120284', '120336', '240260', '240264', '277565', '311911',
       '317558', '317560', '317562', '364807', '364818', '442818', '486859', '496581', '541845', '541846', '542649',
       '543683', '547213', '547214', '561431', '561432', '566211', '641051', '729377', '729379', '731701', '737617',
       '737618', '737619', '739687', '739689', '739703', '739705', '739709', '765926', '780436', '781601', '784964',
       '784965', '790677', '793114', '849813', '863968', '879772', '879773')
  --AND "product"."dateId" IN      (18628, 18661, 18694, 18727, 18760, 18793, 18826, 18859, 18892, 18925, 18958, 18991, 19024, 19057, 19090)
  AND "product".date BETWEEN '2023-11-01' and '2023-11-15'
  AND "product"."retailerId" IN ('81', '1', '2', '3', '9', '11', '8', '10'))
select json_agg(results)
from results;


-- with less attributes executes in 1s
with results as (SELECT
       "product"."promotedPrice",
       "product"."basePrice",
       "product"."coreProductId",
       "product"."date",
       "productPromotions"."promoId"                                         AS "productPromotions.promoId",
       "productPromotions"."description"                                     AS "productPromotions.description",
       "productPromotions"."startDate"                                       AS "productPromotions.startDate",
       "productPromotions"."endDate"                                         AS "productPromotions.endDate",
       "productPromotions->retailerPromotion"."promotionMechanicId"          AS "productPromotions.retailerPromotion.promotionMechanicId",
       "coreProduct"."title"                                                 AS "coreProduct.title",
       "coreProduct"."image"                                                 AS "coreProduct.image",
       "coreProduct"."brandId"                                               AS "coreProduct.brandId",
       "coreProduct"."categoryId"                                            AS "coreProduct.categoryId"
FROM "products" AS "product"
         INNER JOIN "promotions" AS "productPromotions" ON "product"."id" = "productPromotions"."productId"
         INNER JOIN "retailerPromotions" AS "productPromotions->retailerPromotion"
                    ON "productPromotions"."retailerPromotionId" = "productPromotions->retailerPromotion"."id"
         INNER JOIN "coreProducts" AS "coreProduct"
                    ON "product"."coreProductId" = "coreProduct"."id" AND "coreProduct"."productOptions" = FALSE
WHERE "product"."coreProductId" IN
      ('1754', '4064', '4298', '4299', '4300', '4304', '4331', '4364', '4372', '4373', '4377', '4483', '4572', '4657',
       '4691', '5015', '11317', '11564', '11566', '11579', '14398', '16546', '16547', '16548', '16936', '19032',
       '20084', '20581', '20598', '21753', '21806', '22836', '24269', '24923', '26148', '26155', '26349', '37606',
       '38006', '42148', '42763', '43008', '44825', '45525', '45750', '45912', '48006', '52635', '62359', '62361',
       '63173', '63192', '64020', '69967', '82042', '82046', '120284', '120336', '240260', '240264', '277565', '311911',
       '317558', '317560', '317562', '364807', '364818', '442818', '486859', '496581', '541845', '541846', '542649',
       '543683', '547213', '547214', '561431', '561432', '566211', '641051', '729377', '729379', '731701', '737617',
       '737618', '737619', '739687', '739689', '739703', '739705', '739709', '765926', '780436', '781601', '784964',
       '784965', '790677', '793114', '849813', '863968', '879772', '879773')
  --AND "product"."dateId" IN      (18628, 18661, 18694, 18727, 18760, 18793, 18826, 18859, 18892, 18925, 18958, 18991, 19024, 19057, 19090)
  AND "product".date BETWEEN '2023-11-01' and '2023-11-15'
  AND "product"."retailerId" IN ('81', '1', '2', '3', '9', '11', '8', '10'))
select  json_agg(results)
from results