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

ALTER TABLE tests.promotions_v2
    ADD CONSTRAINT promotions_v2_pk
        PRIMARY KEY ("retailerId", "promoId");

CREATE INDEX IF NOT EXISTS promotions_v2_retailerid_promotion_period_index
    ON tests.promotions_v2 ("retailerId", promotion_period);

CREATE INDEX IF NOT EXISTS promotions_v2_coreproductid_index
    ON tests.promotions_v2 USING gin ("coreProductId");
