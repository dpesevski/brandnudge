DROP TYPE IF EXISTS public.product_promo_pricing CASCADE;
CREATE TYPE public.product_promo_pricing AS
(
    "coreProductId" integer,
    period          daterange,
    "shelfPrice"    float, -- maybe keep it everywhere as an array to avoid to array transformation
    "basePrice"     float,
    "promotedPrice" float
);

DROP TYPE IF EXISTS public.product_promo_pricing_period CASCADE;
CREATE TYPE public.product_promo_pricing_period AS
(
    period   daterange,
    pricings integer[]
);

DROP TYPE IF EXISTS public.product_promo_pricing_v2 CASCADE;
CREATE TYPE public.product_promo_pricing_v2 AS
(
    "coreProductId" integer,
    periods         public.product_promo_pricing_period[]
);


CREATE TABLE tests.promotions_v2 AS
WITH products AS (SELECT id                           AS "productId",
                         date::date,
                         "coreProductId",
                         fn_to_float("shelfPrice")    AS "shelfPrice",
                         fn_to_float("basePrice")     AS "basePrice",
                         fn_to_float("promotedPrice") AS "promotedPrice"
                  FROM products),
     agg_1 AS (SELECT "retailerId",
                      "promoId",
                      products."coreProductId",
                      MIN("promotionMechanicId")                  AS "promotionMechanicId",
                      MIN(description)                            AS description,

                      COALESCE(fn_to_date(MIN(promotions."startDate")),
                               MIN(promotions."createdAt")::date) AS "startDate",
                      COALESCE(fn_to_date(MAX(promotions."endDate")),
                               MAX(promotions."updatedAt")::date) AS "endDate",
                      DATERANGE(MIN(products.date),
                                MAX(products.date), '[]')         AS pricing_period,

                      products."shelfPrice",
                      products."basePrice",
                      products."promotedPrice"

               FROM promotions
                        INNER JOIN "retailerPromotions" ON ("retailerPromotionId" = "retailerPromotions".id)
                        INNER JOIN products USING ("productId")
               WHERE NOT ("promoId" IS NULL
                   OR description = ''
                   OR "endDate" < "startDate")
               GROUP BY "retailerId",
                        "promoId",
                        products."coreProductId",
                        products."shelfPrice",
                        products."basePrice",
                        products."promotedPrice")
SELECT "retailerId",
       "promoId",
       ARRAY_AGG(DISTINCT "coreProductId")                          AS "coreProductId",
       MIN("promotionMechanicId")                                   AS "promotionMechanicId",
       MIN(description)                                             AS description,
       DATERANGE(MIN("startDate"), MAX("endDate"), '[]')            AS promotion_period,
       ARRAY_AGG(DISTINCT ("coreProductId",
                           pricing_period,
                           "shelfPrice",
                           "basePrice",
                           "promotedPrice")::product_promo_pricing) AS pricing
FROM agg_1
WHERE NOT ("endDate" < "startDate")
GROUP BY "retailerId",
         "promoId";

WITH params(selected_products,
            selected_retailers,
            selected_promotion_period)
         AS (VALUES (ARRAY [1754, 4064, 4298, 4299, 4300, 4304, 4331, 4364, 4372, 4373, 4377, 4483, 4572, 4657,
                         4691, 5015, 11317, 11564, 11566, 11579, 14398, 16546, 16547, 16548, 16936, 19032,
                         20084, 20581, 20598, 21753, 21806, 22836, 24269, 24923, 26148, 26155, 26349, 37606,
                         38006, 42148, 42763, 43008, 44825, 45525, 45750, 45912, 48006, 52635, 62359, 62361,
                         63173, 63192, 64020, 69967, 82042, 82046, 120284, 120336, 240260, 240264, 277565, 311911,
                         317558, 317560, 317562, 364807, 364818, 442818, 486859, 496581, 541845, 541846, 542649,
                         543683, 547213, 547214, 561431, 561432, 566211, 641051, 729377, 729379, 731701, 737617,
                         737618, 737619, 739687, 739689, 739703, 739705, 739709, 765926, 780436, 781601, 784964,
                         784965, 790677, 793114, 849813, 863968, 879772, 879773],
                     ARRAY [1, 2, 3, 9, 11, 8, 10],
                     DATERANGE('2023-11-01', '2023-11-15')))
SELECT JSONB_AGG(results) AS results
FROM tests.promotions_w_pricing prom
         INNER JOIN params ON (
    "retailerId" = ANY (selected_retailers)
        AND promotion_period && selected_promotion_period
        AND prom."coreProductId" && selected_products
    )
    /*
         CROSS JOIN LATERAL ( SELECT ARRAY_AGG(pr) AS products
                              FROM UNNEST(pricing) AS pr
                              WHERE params.selected_products @> ARRAY [pr."coreProductId"]
                                AND pr.period && selected_promotion_period
    ) AS pr
 */
         CROSS JOIN LATERAL ( WITH agg_period AS (SELECT "coreProductId",
                                                         JSONB_AGG(JSONB_BUILD_OBJECT(period,
                                                                                      ARRAY [ "shelfPrice", "basePrice", "promotedPrice"])) AS pricing_period
                                                  FROM UNNEST(pricing) AS pr
                                                  WHERE params.selected_products @> ARRAY [pr."coreProductId"]
                                                    AND pr.period && selected_promotion_period
                                                  GROUP BY "coreProductId")

                              SELECT JSONB_AGG(JSONB_BUILD_OBJECT('coreProductId', "coreProducts".id,
                                                                  'title', "coreProducts"."title",
                                                                  'image', "coreProducts"."image",
                                                                  'brandId', "coreProducts"."brandId",
                                                                  'categoryId', "coreProducts"."categoryId",
                                                                  'productGroupId', "coreProducts"."productGroupId",
                                                                  'pricing', pricing_period)) AS products
                              FROM agg_period
                                       INNER JOIN "coreProducts" ON "coreProductId" = "coreProducts".id

    --SELECT JSONB_AGG(JSONB_BUILD_OBJECT("coreProductId", pricing_period)) AS products                              FROM agg_period

    ) AS pr

         CROSS JOIN LATERAL (SELECT "retailerId",
                                    "promoId",
                                    "promotionMechanicId",
                                    description,
                                    promotion_period,
                                    pr.products
    ) AS results
WHERE pr.products IS NOT NULL;
