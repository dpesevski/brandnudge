SELECT data AS value, dd_retailer AS retailer
FROM staging.debug_test_run
WHERE id = 106;

SELECT "sourceId",
       -- multibuy,
       "promotedPrice",
       "basePrice",
       "shelfPrice",
       *
FROM test.tmp_product_pp
ORDER BY "sourceId" DESC;

DROP TABLE IF EXISTS test.tmp_product_pp;
CREATE TABLE test.tmp_product_pp AS
WITH input_data AS (SELECT data AS value--, dd_retailer AS retailer
                    FROM staging.debug_test_run
                    WHERE id = 106),
     prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
     tmp_daily_data_pp AS (SELECT product.date,
                                  product."countryCode",
                                  product."currency",
                                  product."sourceId",
                                  product.ean,
                                  product."brand",
                                  product."title",
                                  fn_to_float(product."shelfPrice")                   AS "shelfPrice",
                                  fn_to_float(product."wasPrice")                     AS "wasPrice",
                                  fn_to_float(product."cardPrice")                    AS "cardPrice",
                                  fn_to_boolean(product."inStock")                    AS "inStock",
                                  fn_to_boolean(product."onPromo")                    AS "onPromo",
                                  COALESCE(product."promoData",
                                           ARRAY []::staging.t_promotion_pp[])        AS "promoData",
                                  COALESCE(product."skuURL", '')                      AS href,
                                  product."imageURL",
                                  COALESCE(fn_to_boolean(product."bundled"), FALSE)   AS "bundled",
                                  COALESCE(fn_to_boolean(product."masterSku"), FALSE) AS "productOptions",
                                  shop,
                                  "amazonShop",
                                  choice,
                                  "amazonChoice",
                                  "lowStock",
                                  "sellParty",
                                  "amazonSellParty",
                                  sell,
                                  "fulfilParty",
                                  "amazonFulfilParty",
                                  "amazonSell",
                                  ROW_NUMBER() OVER (PARTITION BY "sourceId")         AS rownum -- use only the first sourceId record
                           FROM input_data
                                    CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                                               value #> '{products}') AS product),
     dd_products AS (SELECT COALESCE("wasPrice", "shelfPrice")        AS "originalPrice",
                            "shelfPrice"                              AS "productPrice",
                            "shelfPrice",
                            COALESCE("brand", '')                     AS "productBrand",

                            'listing'                                 AS status,

                            COALESCE("title", '')                     AS "productTitle",
                            COALESCE("imageURL", '')                  AS "productImage",
                            COALESCE("inStock", TRUE)                 AS "productInStock",

                            date,
                            "countryCode",
                            "currency",
                            CASE WHEN ean = '' THEN NULL ELSE ean END AS ean,
                            "brand",
                            "title",
                            href,

                            "sourceId",
                            "cardPrice",
                            "bundled",
                            "productOptions",
                            "promoData",
                            "onPromo",

                            shop,
                            "amazonShop",
                            choice,
                            "amazonChoice",
                            "lowStock",
                            "sellParty",
                            "amazonSellParty",
                            sell,
                            "fulfilParty",
                            "amazonFulfilParty",
                            "amazonSell",

                            ROW_NUMBER() OVER ()                      AS index
                     FROM tmp_daily_data_pp

                     WHERE rownum = 1)

SELECT NULL::integer                                                       AS id,
       'amazon'                                                            AS "sourceType",
       checkEAN.ean,
       -- COALESCE(ARRAY_LENGTH(trsf_promo.promotions, 1) > 0, FALSE)         AS products_promotions_flag,
       COALESCE(trsf_promo."promotionDescription", '')                     AS "promotionDescription",
       ''                                                                  AS features,
       dd_products.date,
       dd_products."sourceId",
       dd_products."productBrand",
       dd_products."productTitle",
       dd_products."productImage",
       FALSE                                                               AS "secondaryImages",
       ''                                                                  AS "productDescription",
       ''                                                                  AS "productInfo",
       dd_products."originalPrice"                                         AS "promotedPrice",
       dd_products."productInStock",
       TRUE                                                                AS "productInListing",
       NULL::integer                                                       AS "reviewsCount",
       NULL::float                                                         AS "reviewsStars",
       NULL                                                                AS "eposId",
       COALESCE(trsf_promo.is_multibuy, FALSE)                             AS multibuy,
       NULL::integer                                                       AS "coreProductId",
       4                                                                   AS "retailerId",
       NOW()                                                               AS "createdAt",
       NOW()                                                               AS "updatedAt",
       NULL                                                                AS "imageId",
       ''                                                                     size,
       NULL                                                                AS "pricePerWeight",
       dd_products.href,
       ''                                                                  AS nutritional,
       dd_products."originalPrice"                                         AS "basePrice",
       dd_products."originalPrice"                                         AS "shelfPrice",
       dd_products."productTitle"                                          AS "productTitleDetail",
       NULL                                                                AS "sizeUnit",
       '2024-06-16'                                                        AS "dateId",

       dd_products."countryCode",
       dd_products."currency",
       dd_products."cardPrice",
       dd_products."onPromo",
       dd_products."bundled",
       dd_products."originalPrice",
       dd_products."productPrice",
       dd_products.status,
       dd_products."productOptions",

       dd_products.shop,
       dd_products."amazonShop",
       dd_products.choice,
       dd_products."amazonChoice",
       dd_products."lowStock",
       dd_products."sellParty",
       dd_products."amazonSellParty",
       dd_products.sell,
       dd_products."fulfilParty",
       dd_products."amazonFulfilParty",
       dd_products."amazonSell",

       checkEAN."eanIssues",
       dd_ranking.screenshot,
       prod_brand."brandId",
       dd_ranking::"productsData",
       trsf_ean."EANs",
       COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion_mb[]) AS promotions

FROM dd_products

         CROSS JOIN LATERAL (SELECT NULL              AS id,
                                    NULL              AS "productId",
                                    ''                AS category,
                                    'taxonomy'           "categoryType",
                                    NULL              AS "parentCategory",
                                    dd_products.index AS "productRank",
                                    1                 AS "pageNumber",
                                    ''                AS screenshot,
                                    NULL              AS "sourceCategoryId",

                                    FALSE             AS featured, -- has a featuredRank but  if (!product.featured) product.featured = false;
                                    dd_products.index AS "featuredRank",

                                    NULL              AS "taxonomyId"
    ) AS dd_ranking
         CROSS JOIN LATERAL
    (
    SELECT CASE
               /*
                   Matt (5/13/2024) :https://brand-nudge-group.slack.com/archives/C068Y51TS6L/p1715604955904309?thread_ts=1715603977.153229&cid=C068Y51TS6L
                   if ean is NULL or “” then we will send either <sourceId> as <ean> or <retailer>_<sourceId> as <ean>.
               */
               WHEN dd_products.ean IS NULL THEN ARRAY [dd_products."sourceId"]:: TEXT[]
               WHEN
                   dd_products."productOptions"
                   THEN ARRAY [ 'amazon' || '_' || dd_products."sourceId"] :: TEXT[]
               ELSE
                   STRING_TO_ARRAY(dd_products.ean, ',') END AS "EANs"
    ) AS trsf_ean
         CROSS JOIN LATERAL ( SELECT trsf_ean."EANs"[1]         AS ean,
                                     CASE
                                         WHEN dd_products.ean IS NULL THEN TRUE
                                         ELSE
                                             COALESCE(trsf_ean."EANs"[1] !~
                                                      '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$',
                                                      TRUE) END AS "eanIssues"
    ) AS checkEAN
         CROSS JOIN LATERAL ( SELECT ARRAY_AGG(
                                             (
                                              CASE WHEN promo_id = '' THEN NULL ELSE promo_id END,-- AS "promoId",
                                              NULL,--"retailerPromotionId"
                                              NULL,-- AS "startDate",
                                              NULL,--AS "endDate"
                                              promo_description,--AS description,
                                              promo_type,-- AS mechanic,
                                              fn_to_float(multibuy_price)-- AS "multibuyPrice"
                                                 )::staging.t_promotion_mb)       AS promotions,
                                     STRING_AGG(promo_description, ';')           AS "promotionDescription",
                                     SUM(fn_to_float(multibuy_price)) IS NOT NULL AS is_multibuy
                              FROM UNNEST(COALESCE("promoData", ARRAY []::staging.t_promotion_pp[])) AS promo (promo_id,
                                                                                                               promo_type,
                                                                                                               promo_description,
                                                                                                               multibuy_price)
    ) AS trsf_promo
    --   LEFT OUTER JOIN prod_brand ON (ARRAY ["productBrand"] && brand_names);
         LEFT OUTER JOIN prod_brand USING ("productBrand")
;

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
                              lat_dates."startDate",
                              lat_dates."endDate",

                              "promotedPrice",
                              "shelfPrice",
                              "productPrice",

                              lat_promo_id."promoId",
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
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."startDate", product.date) AS "startDate",
                                                           COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."promoId",
                                                                    REPLACE(4 || '_' || "sourceId" ||
                                                                            '_' ||
                                                                            description || '_' ||
                                                                            lat_dates."startDate", ' ',
                                                                            '_')) AS "promoId") AS lat_promo_id
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
                                 "promoId",
                                 "retailerPromotionId",
                                 "startDate",
                                 "endDate",
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
      ('B09B8GFMB7', 'B001A34BE2', 'B005VBOH70', 'B09TTTRVQJ', 'B06XX4C1BG', 'B0046ZLBQW', 'B00A689BFQ', 'B010FPPSCE',
       'B08C8L4GJ7', 'B07Y5L7MVS', 'B098B4C2G9', 'B001MZV0V0', 'B092WK7KP5', 'B09P41G9LT', 'B089MY5RJS', 'B09YMJ9LH4',
       'B008BDSZFK', 'B00D1VTQ0U', 'B08CN3G4N9', 'B0080PACF0', 'B09YMLN11X', 'B00YSW1YCE', 'B08BFDQLJG', 'B08PX36QCQ',
       'B09KVDLL5C', 'B089MXSYF2', 'B0877B86K9', 'B09BW5SJBD', 'B00WMBM8BE', 'B009LGTA00', 'B088KQK6VR', 'B01H508536',
       'B07GGBXYRX', 'B0833MJFKL', 'B0BFFQD43H', 'B000XFY2JM', 'B07YX4GM9L', 'B004R114DU', 'B07TD5T5J7', 'B09C2FNHND',
       'B076DBGHJJ', 'B096GVM27R', 'B00CDHAC9C', 'B09B8B73JL', 'B084GLQ5CT', 'B08BJVMF6F', 'B09PQJDG12', 'B00E5DK1O8',
       'B0BS1BXM4N', 'B00ZVUZVFI', 'B008MJ0X3U', 'B0089WX83C', 'B0BQ3Z16HM', 'B01LWPIMHA', 'B099KNH1VX', 'B01I507G4Y',
       'B01H507HUS', 'B09CDT23ZV', 'B00ZHB6N1M', 'B09TL6XXNJ', 'B000PECIXS', 'B00008W5MI', 'B0BS64622B', 'B003ZGE5SY',
       'B008A3TEA6', 'B008A3TE8I', 'B000FQCIU4', 'B07H5VK5WW', 'B08KWJVWSW', 'B08P39M3T2', 'B091TVV5ZF', 'B0BQNCPL21',
       'B000B5M3EA', 'B00MC9D65S', 'B004D37Z4O', 'B00YIM4UN4', 'B07Z6Z227S', 'B089MWJFX2', 'B09G9W79KC', 'B08LHGWF83',
       'B000DZA6K6', 'B00YSW1YTM', 'B017NJ2CMO', 'B0849697NV', 'B08ZT3235D', 'B00WFUGH5A', 'B087VHVHCV', 'B00A7MI7XS',
       'B085817XZH', 'B0CJC7QSYQ', 'B01E7CPIJ4', 'B07BB17MNF', 'B09NND18SK', 'B01AY03E94', 'B002SPRZQW', 'B004FG87G4',
       'B07YCKW7S1', 'B000GQ80TQ', 'B00008WX67', 'B01IN7AIQC', 'B005VBOUV8', 'B092WK746T', 'B091TWLYZK', 'B008P6Z1QO',
       'B08TJ25VVS', 'B00OBCUUWG', 'B078GQPS1Q', 'B01MU1E45S', 'B076DBPCWY', 'B07RNKRKLB', 'B08H8S78T4', 'B09Q9CVYQY',
       'B084GMQT1X', 'B07YF8YP5G', 'B086FC83H5', 'B09TTTYLZX', 'B008LQZP6E', 'B01K9TR3GU', 'B089MXCR71', 'B08BLSVNFQ',
       'B0B94LH5RN', 'B0C5NZ99SL', 'B01727R0MO', 'B076VTXSNL', 'B0BX7166HT', 'B000FNG12S', 'B07Y5KYLYJ', 'B07X5D1MCZ',
       'B07Q2KWHD2', 'B07TWCG9TN', 'B077BBDLJF', 'B092WGYGQM', 'B08WLCYWXT', 'B06XJBDDM9', 'B09C2HZ3B2', 'B09TLBRCR3',
       'B0CC5VPZZ1', 'B000W9KPD6', 'B01BNKHHTC', 'B089MY5D3N', 'B084GLS2G7', 'B004K89266', 'B0BCK4K9ZC', 'B07X2YWQF5',
       'B0089VWQZY', 'B010HL5AX8', 'B07QD9WHHN', 'B07Y5KYLYD', 'B0015QBFZC', 'B09B2GWJX9', 'B09GRL544S', 'B07JJF3Q2D',
       'B01J5Q6ZBW', 'B0CKB7RP6J', 'B0887DYL7M', 'B09B7SWJBP', 'B004ULOYCA', 'B0B974T1Z9', 'B0BWMSYDVD', 'B07BCSHLF4',
       'B004HJT4HK', 'B08BL8NPYH', 'B07KBNPXHD', 'B082FRKNH6', 'B0074JZ84I', 'B0002566II', 'B003F14NZE', 'B09GB1F84Q',
       'B00MHZTKXY', 'B07N8T2MYY', 'B09GB3LS4R', 'B084FFVV92', 'B09CLJR919', 'B086R8BHGX', 'B09SHXBGJQ', 'B07R3WZ7DH',
       'B0016OSC72', 'B083G3YF51', 'B08X73BYML', 'B09PRN92Z2', 'B0BX71S1TP', 'B000LVOEPK', 'B008KW4PQA', 'B08LHGJYGT',
       'B09B2HSQP9', 'B09YCWGP1Q', 'B003ZHVAJK', 'B0CGJQSBQ7', 'B006OMBQE2', 'B08JDZZ9H7', 'B086WY959G', 'B08LHG4VNG',
       'B08KFZ5BLV', 'B06XWTTPNS', 'B084V7DJQP', 'B00TYJVETO', 'B08496D42V', 'B003LSU2ZG', 'B002ISD8M4', 'B08QMDZ86J',
       'B008KW4MFY', 'B0812552CW', 'B076W8Y687', 'B0BZQ5NPVX', 'B07QNZ7W47', 'B08TMRMSWK', 'B079GV6RX7', 'B07Q6GT98V',
       'B07NDY6G5C', 'B0B15HT8F7', 'B07Z2LMZ12', 'B004FM8YLQ', 'B09N3QS3J5', 'B07R9N6C41', 'B076D9QLWR', 'B079JSSL9S',
       'B00CDHA4RM', 'B004FGCUDK', 'B00DREVSQG', 'B013QSSGLM', 'B0CSP4XRTK', 'B00OMP88EY', 'B07BFD6LHZ', 'B07Y5L9TT5',
       'B099SKL4W6', '5010102243705', 'B0002ASNAM', 'B09MD69Z35', 'B01I507RNO', 'B01A84QZR4', 'B003QXN33O',
       'B000NTDDL6', 'B09BZMX4WK', 'B0BQBMVRBT', 'B06XXDMQH4', 'B084GM29DF', 'B0CGVV82C1', 'B08R1LF3NT', 'B09ZVM6MHT',
       'B07PQDW44P', 'B06W57X25S', 'B003OQVDBC', 'B07RMXTCBX', 'B07Y3KDL7R', 'B0079SZ0KG', 'B003ZGIB1Q', 'B076D98CZZ',
       'B083V96Q9G', 'B000BV7PMY', 'B00307I8C2', 'B07B96BQM6', 'B01MFX5M4U', 'B094VKGWMY', 'B01IHRLMAE', 'B01ICU1OZ4',
       'B08758PGTR', 'B09XF7NKV5', 'B00YSW1YWY', 'B089F7N4XF', 'B09C2HK3JN', 'B08XC51P9Z', 'B07YF9Y74S', 'B0849615MD',
       'B0BWJW8HTL', 'B000ER3QM8', 'B0BWSDQ9WT', 'B00CXMZTI6', 'B08NR2VNYB', 'B089TP5N63', 'B005FVBEJA')
ORDER BY "sourceId" DESC;

