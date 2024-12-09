CREATE MATERIALIZED VIEW tesco_corrected_prices AS
WITH correct_prices AS (SELECT products."sourceId",
                               MAX(products.date)       AS last_date,
                               products."shelfPrice"    AS "correct_shelfPrice",
                               products."promotedPrice" AS "correct_promotedPrice"
                        FROM products
                        WHERE products.date::date = '2024-11-25'::date
                          AND products."retailerId" = 1
                        GROUP BY products."sourceId", products."shelfPrice", products."promotedPrice"),
     affected_records AS (SELECT products.id,
                                 products."sourceType",
                                 products.ean,
                                 products.promotions,
                                 products."promotionDescription",
                                 products.features,
                                 products.date,
                                 products."sourceId",
                                 products."productBrand",
                                 products."productTitle",
                                 products."productImage",
                                 products."secondaryImages",
                                 products."productDescription",
                                 products."productInfo",
                                 products."promotedPrice",
                                 products."productInStock",
                                 products."productInListing",
                                 products."reviewsCount",
                                 products."reviewsStars",
                                 products."eposId",
                                 products.multibuy,
                                 products."coreProductId",
                                 products."retailerId",
                                 products."createdAt",
                                 products."updatedAt",
                                 products."imageId",
                                 products.size,
                                 products."pricePerWeight",
                                 products.href,
                                 products.nutritional,
                                 products."basePrice",
                                 products."shelfPrice",
                                 products."productTitleDetail",
                                 products."sizeUnit",
                                 products."dateId",
                                 products.marketplace,
                                 products."marketplaceData",
                                 products."priceMatchDescription",
                                 products."priceMatch",
                                 products."priceLock",
                                 products."isNpd"
                          FROM products
                          WHERE products.date::date >= '2024-11-26'::date
                            AND products.date::date <= '2024-11-27'::date
                            AND products."promotionDescription" ~* 'save [0-9]+p'::text
                            AND products."retailerId" = 1)
SELECT a.id,
       a."sourceId",
       a.date,
       a."promotionDescription",
       a.ean,
       a."retailerId",
       a."sourceType",
       a."coreProductId",
       a."basePrice",
       a."shelfPrice"    AS "current_shelfPrice",
       a."promotedPrice" AS "current_promotedPrice",
       c."correct_shelfPrice",
       c."correct_promotedPrice",
       a.href
FROM affected_records a
         LEFT JOIN correct_prices c ON a."sourceId"::text = c."sourceId"::text;

ALTER MATERIALIZED VIEW tesco_corrected_prices OWNER TO postgres;

GRANT SELECT ON tesco_corrected_prices TO bn_ro;

GRANT SELECT ON tesco_corrected_prices TO dejan_user;

