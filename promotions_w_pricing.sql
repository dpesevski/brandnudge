DROP TYPE IF EXISTS public.product_promo_pricing CASCADE;
CREATE TYPE public.product_promo_pricing AS
(
    "coreProductId" integer,
    period          daterange,
    "shelfPrice"    float,
    "basePrice"     float,
    "promotedPrice" float
);


CREATE TABLE tests.promotions_w_pricing AS
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
                                MAX(products.date))               AS pricing_period,

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
       DATERANGE(MIN("startDate"), MIN("endDate"))                  AS promotion_period,
       ARRAY_AGG(DISTINCT ("coreProductId",
                           pricing_period,
                           "shelfPrice",
                           "basePrice",
                           "promotedPrice")::product_promo_pricing) AS pricing
FROM agg_1
GROUP BY "retailerId",
         "promoId";

SELECT *
FROM tests.promotions_w_pricing