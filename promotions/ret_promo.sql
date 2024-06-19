WITH ret_promo AS (SELECT id AS "retailerPromotionId",
                          "retailerId",
                          "promotionMechanicId",
                          regexp,
                          "promotionMechanicName"
                   FROM "retailerPromotions"
                            INNER JOIN (SELECT id   AS "promotionMechanicId",
                                               name AS "promotionMechanicName"
                                        FROM "promotionMechanics") AS "promotionMechanics"
                                       USING ("promotionMechanicId")),
     product_promo AS (SELECT product."retailerId",
                              "sourceId",
                              promo_indx,
                              "promotedPrice",
                              "shelfPrice",
                              "productPrice",

                              promo.description,
                              promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.
                              promo."multibuyPrice"                                AS "multibuyPrice",

                              COALESCE(ret_promo."retailerPromotionId",
                                       default_ret_promo."retailerPromotionId")    AS "retailerPromotionId",
                              COALESCE(ret_promo.regexp, default_ret_promo.regexp) AS regexp,
                              COALESCE(ret_promo."promotionMechanicId",
                                       default_ret_promo."promotionMechanicId")    AS "promotionMechanicId",
                              COALESCE(
                                      ret_promo."promotionMechanicName",
                                      default_ret_promo."promotionMechanicName")   AS "promotionMechanicName",
                              ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx ORDER BY
                                  LOWER(ret_promo."promotionMechanicName") =
                                  COALESCE(promo.mechanic, '') DESC)               AS rownum
                       FROM test.tmp_product_pp AS product
                                CROSS JOIN LATERAL UNNEST(promotions) WITH ORDINALITY AS promo("promoId",
                                                                                               "retailerPromotionId",
                                                                                               "startDate",
                                                                                               "endDate",
                                                                                               description,
                                                                                               mechanic,
                                                                                               "multibuyPrice",
                                                                                               promo_indx)
                                CROSS JOIN LATERAL (
                           SELECT LOWER(multi_replace(promo.description,
                                                      'one', '1', 'two', '2', 'three', '3', 'four', '4', 'five',
                                                      '5',
                                                      'six', '6', 'seven', '7', 'eight', '8', 'nine', '9', 'ten',
                                                      '10',
                                                      ',', '')) AS desc
                           ) AS promo_desc_trsf
                                LEFT OUTER JOIN ret_promo AS default_ret_promo
                                                ON (product."retailerId" = default_ret_promo."retailerId" AND
                                                    default_ret_promo."promotionMechanicId" = 3)
                                LEFT OUTER JOIN ret_promo
                                                ON (product."retailerId" = ret_promo."retailerId" AND
                                                    CASE
                                                        WHEN ret_promo."promotionMechanicId" IS NULL THEN FALSE
                                                        WHEN LOWER(ret_promo."promotionMechanicName") =
                                                             COALESCE(promo.mechanic, '') THEN TRUE
                                                        WHEN ret_promo.regexp IS NULL OR LENGTH(ret_promo.regexp) = 0
                                                            THEN FALSE
                                                        WHEN ret_promo."promotionMechanicName" = 'Multibuy' AND
                                                             promo_desc_trsf.desc ~ '(\d+\/\d+)'
                                                            THEN FALSE
                                                        ELSE
                                                            promo_desc_trsf.desc ~ ret_promo.regexp
                                                        END
                                                    )),
     promo_price_calc AS (SELECT "sourceId",
                                 description,
                                 "multibuyPrice",
                                 1                                                                                               AS "promoId",
                                 "retailerPromotionId",
                                 NOW()                                                                                           AS "startDate",
                                 NOW()                                                                                           AS "endDate",
                                 "promotionMechanicName",
                                 promo_indx,
                                 price_calc."promotedPrice",
                                 price_calc."shelfPrice",
                                 ROW_NUMBER()
                                 OVER (PARTITION BY "sourceId" ORDER BY price_calc."promotedPrice", "multibuyPrice" NULLS LAST ) AS promo_price_order
                          FROM product_promo
                                   CROSS JOIN LATERAL (SELECT CASE
                                                                  WHEN "promotionMechanicName" = 'Multibuy' THEN
                                                                      COALESCE("multibuyPrice",
                                                                               calculateMultibuyPrice(
                                                                                       description,
                                                                                       "promotedPrice")
                                                                      )
                                                                  ELSE "productPrice"
                                                                  END AS "promotedPrice",
                                                              CASE
                                                                  WHEN "promotionMechanicName" = 'Multibuy' THEN
                                                                      "shelfPrice"
                                                                  ELSE
                                                                      "productPrice"
                                                                  END AS "shelfPrice") AS price_calc
                          WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
     ),
     upd_product_promo AS (SELECT "sourceId",
                                  MAX("promotedPrice") FILTER (WHERE promo_price_order = 1) AS "promotedPrice",
                                  MAX("shelfPrice") FILTER (WHERE promo_price_order = 1)    AS "shelfPrice",
                                  ARRAY_AGG(("promoId",
                                             "retailerPromotionId",
                                             "startDate",
                                             "endDate",
                                             description,
                                             "promotionMechanicName",
                                             "multibuyPrice")::staging.t_promotion_mb
                                            ORDER BY promo_indx)                            AS promotions
                           FROM promo_price_calc
                           GROUP BY 1)
SELECT *
FROM upd_product_promo
WHERE "sourceId" IN
      ('B0CSP4XRTK')

/*
+-------------------+----------+-------------------+--------------------+---------------------+
|retailerPromotionId|retailerId|promotionMechanicId|regexp              |promotionMechanicName|
+-------------------+----------+-------------------+--------------------+---------------------+
|74                 |4         |3                  |                    |Other                |
|27                 |4         |1                  |save: (.*) was: (.*)|Price Cut            |
|50                 |4         |2                  |save: (.*) rrp: (.*)|Multibuy             |
+-------------------+----------+-------------------+--------------------+---------------------+


*/