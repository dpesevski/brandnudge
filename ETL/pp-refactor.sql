SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

DROP TABLE IF EXISTS test.last_product_status;
DROP TABLE IF EXISTS test.dd_products;
DROP TABLE IF EXISTS test.tmp_product_pp;


--[2024-11-20 19:59:48] 182,135 rows affected in 16 s 150 ms
CREATE TABLE test.last_product_status AS
SELECT DISTINCT ON ("coreProductId") "coreProductId",
                                     date,
                                     status,
                                     "productId"
FROM staging.product_status_history
WHERE "retailerId" = 1
  AND date < '2024-11-17'
ORDER BY "coreProductId", date DESC;

/*  todo: split create tmp_product_pp, first till dd_products and then the rest  */
--[2024-11-20 20:21:36] 146,095 rows affected in 6 s 717 ms
CREATE TABLE test.dd_products AS
WITH load_data_ AS (SELECT fetched_data AS value
                    FROM staging.debug_errors
                    WHERE id = 100),
     tmp_daily_data_pp AS (SELECT '2024-11-17'::date                                    AS date,
                                  product."countryCode",
                                  product."currency",
                                  product."sourceId",
                                  product.ean,
                                  product."brand",
                                  product."title",
                                  fn_to_float(product."shelfPrice")                     AS "shelfPrice",
                                  fn_to_float(product."wasPrice")                       AS "wasPrice",
                                  fn_to_float(product."cardPrice")                      AS "cardPrice",
                                  fn_to_boolean(product."inStock")                      AS "inStock",
                                  fn_to_boolean(product."onPromo")                      AS "onPromo",
                                  COALESCE(product."promoData",
                                           ARRAY []::staging.t_promotion_pp[])          AS "promoData",
                                  COALESCE(product."skuURL", '')                        AS href,
                                  product."imageURL",

                                  product."newCoreImage",
                                  COALESCE(fn_to_boolean(product."bundled"), FALSE)     AS "bundled",
                                  COALESCE(fn_to_boolean(product."masterSku"), FALSE)   AS "productOptions",
                                  LEFT(shop, 255)                                       AS shop,
                                  LEFT("amazonShop", 255)                               AS "amazonShop",
                                  LEFT(choice, 255)                                     AS choice,
                                  LEFT("amazonChoice", 255)                             AS "amazonChoice",
                                  "lowStock",
                                  LEFT("sellParty", 255)                                AS "sellParty",
                                  LEFT("amazonSellParty", 255)                          AS "amazonSellParty",
                                  LEFT(sell, 255)                                       AS sell,
                                  LEFT("fulfilParty", 255)                              AS "fulfilParty",
                                  LEFT("amazonFulfilParty", 255)                        AS "amazonFulfilParty",
                                  LEFT("amazonSell", 255)                               AS "amazonSell",
                                  marketplace,
                                  "marketplaceData",
                                  "priceMatchDescription",
                                  "priceMatch",
                                  "priceLock",
                                  "isNpd",
                                  LEFT(product.size, 255)                               AS size,
                                  LEFT("sizeUnit", 255)                                 AS "sizeUnit",
                                  LEFT("pricePerWeight", 255)                           AS "pricePerWeight",
                                  ROW_NUMBER()
                                  OVER (PARTITION BY "sourceId" ORDER BY "skuURL" DESC) AS rownum -- use only the first sourceId record
                           FROM load_data_
                                    CROSS JOIN JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                                       value #> '{products}') AS product),
     dd_products AS (SELECT COALESCE("wasPrice", "shelfPrice")        AS "originalPrice",
                            "shelfPrice"                              AS "productPrice",
                            "shelfPrice",
                            COALESCE("brand", '')                     AS "productBrand",


                            COALESCE("title", '')                     AS "productTitle",
                            COALESCE("imageURL", '')                  AS "productImage",
                            COALESCE("newCoreImage", '')              AS "newCoreImage",

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
                            marketplace,
                            "marketplaceData",
                            "priceMatchDescription",
                            "priceMatch",
                            "priceLock",
                            "isNpd",
                            size,
                            "sizeUnit",
                            "pricePerWeight",
                            ROW_NUMBER() OVER ()                      AS index
                     FROM tmp_daily_data_pp
                     WHERE rownum = 1)
SELECT *
FROM dd_products;

--[2024-11-20 20:23:57] 146,095 rows affected in 4 s 13 ms
CREATE TABLE test.tmp_product_pp AS
WITH prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
     prod_barcode AS (SELECT barcode, "coreProductId" FROM "coreProductBarcodes"),
     prod_core AS (SELECT ean, id AS "coreProductId" FROM "coreProducts"),
     prod_retailersource AS (SELECT "sourceId", "coreProductId"
                             FROM "coreRetailerSources"
                                      INNER JOIN "coreRetailers"
                                                 ON (
                                                     "coreRetailers"."retailerId" = 1 AND
                                                     "coreRetailerSources"."coreRetailerId" = "coreRetailers".id
                                                     ))

SELECT NULL::integer                                                       AS id,
       'tesco'                                                             AS "sourceType",
       checkEAN.ean,
       -- COALESCE(ARRAY_LENGTH(trsf_promo.promotions, 1) > 0, FALSE)         AS products_promotions_flag,
       COALESCE(trsf_promo."promotionDescription", '')                     AS "promotionDescription",
       ''                                                                  AS features,
       dd_products.date,
       dd_products."sourceId",
       dd_products."productBrand",
       dd_products."productTitle",
       dd_products."productImage",
       dd_products."newCoreImage",

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
       COALESCE(prod_barcode."coreProductId",
                prod_core."coreProductId",
                prod_retailersource."coreProductId")                       AS "coreProductId",
       1                                                                   AS "retailerId",
       NOW()                                                               AS "createdAt",
       NOW()                                                               AS "updatedAt",
       NULL                                                                AS "imageId",
       dd_products.size,
       dd_products.href,
       ''                                                                  AS nutritional,
       dd_products."originalPrice"                                         AS "basePrice",
       dd_products."originalPrice"                                         AS "shelfPrice",
       dd_products."productTitle"                                          AS "productTitleDetail",
       dd_products."sizeUnit",
       29787                                                               AS "dateId",
       dd_products."countryCode",
       dd_products."currency",
       dd_products."cardPrice",
       dd_products."onPromo",
       dd_products."bundled",
       dd_products."originalPrice",
       dd_products."productPrice",
       'Newly'                                                             AS status,
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
       dd_products.marketplace,
       dd_products."marketplaceData",
       dd_products."priceMatchDescription",
       dd_products."priceMatch",
       dd_products."priceLock",
       TRUE                                                                AS "isNpd",
       checkEAN."eanIssues",
       ''                                                                  AS screenshot,
       prod_brand."brandId",
       trsf_ean."EANs",
       COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion_mb[]) AS promotions,
       dd_products."pricePerWeight",
       216                                                                 AS load_id
FROM test.dd_products
         CROSS JOIN LATERAL ( SELECT CASE
                                         /*
                                             Matt (5/13/2024) :https://brand-nudge-group.slack.com/archives/C068Y51TS6L/p1715604955904309?thread_ts=1715603977.153229&cid=C068Y51TS6L
                                             if ean is NULL or “” then we will send either <sourceId> as <ean> or <retailer>_<sourceId> as <ean>.
                                         */
                                         WHEN dd_products.ean IS NULL THEN ARRAY [dd_products."sourceId"]:: TEXT[]
                                         WHEN
                                             dd_products."productOptions"
                                             THEN ARRAY [ 'tesco' || '_' || dd_products."sourceId"] :: TEXT[]
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
         LEFT OUTER JOIN prod_barcode ON (prod_barcode.barcode = checkEAN.ean)
         LEFT OUTER JOIN prod_core ON (prod_core.ean = checkEAN.ean)
         LEFT OUTER JOIN prod_retailersource USING ("sourceId");

--[2024-11-20 20:28:38] completed in 124 ms
/*  createCoreBy    */
WITH coreProductData AS (SELECT ean,
                                "productTitle"                       AS title,
                                "newCoreImage"                       AS image,
                                "brandId",
                                bundled,
                                "secondaryImages",
                                "productDescription"                 AS description,
                                features,
                                "productInfo"                        AS ingredients,
                                LEFT(size, 255)                      AS size,
                                nutritional                          AS specification,
                                COALESCE("productOptions", FALSE)    AS "productOptions",
                                "eanIssues",
                                ROW_NUMBER() OVER (PARTITION BY ean) AS row_num
                         FROM test.tmp_product_pp
                         WHERE "coreProductId" IS NULL),
     ins_coreProducts AS (
         INSERT
             INTO "coreProducts" (ean,
                                  title,
                                  image,
                                  "secondaryImages",
                                  description,
                                  features,
                                  ingredients,
                                  "brandId",
                 --"categoryId",
                 --"productGroupId",
                                  "createdAt",
                                  "updatedAt",
                                  bundled,
                                  disabled,
                                  "eanIssues",
                                  specification,
                                  size,
                 --reviewed,
                                  "productOptions",
                                  load_id)
                 SELECT ean,
                        title,
                        image,
                        "secondaryImages",
                        description,
                        features,
                        ingredients,
                        "brandId",
                        --"categoryId",
                        --"productGroupId",
                        NOW() AS "createdAt",
                        NOW() AS "updatedAt",
                        bundled,
                        FALSE    disabled,
                        "eanIssues",
                        specification,
                        size,
                        --reviewed,
                        "productOptions",
                        216
                 FROM coreProductData
                 WHERE row_num = 1
                 ON CONFLICT (ean) DO UPDATE
                     SET disabled = FALSE,
                         "productOptions" = excluded."productOptions",
                         "updatedAt" = excluded."updatedAt"
                 RETURNING "coreProducts".*),
     debug_ins_coreProducts AS (
         INSERT INTO staging.debug_coreProducts
             SELECT * FROM ins_coreProducts),
    /*  createProductCountryData    */
     ins_prod_country_data AS (INSERT INTO "coreProductCountryData" ("coreProductId",
                                                                     "countryId",
                                                                     title,
                                                                     image,
                                                                     description,
                                                                     features,
                                                                     ingredients,
                                                                     specification,
                                                                     "createdAt",
                                                                     "updatedAt",
                                                                     "secondaryImages",
                                                                     bundled,
                                                                     disabled,
                                                                     reviewed, load_id)
         SELECT id AS "coreProductId",
                1  AS "countryId",
                title,
                image,
                description,
                features,
                ingredients,
                specification,
                NOW(),
                NOW(),
                "secondaryImages",
                bundled,
                disabled,
                reviewed,
                216
         --"ownLabelManufacturerId",
         --"brandbankManaged"
         FROM ins_coreProducts
         --WHERE "updatedAt" != "createdAt"
         WHERE "updatedAt" >= NOW()::date
         ON CONFLICT ("coreProductId", "countryId")
             WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
             DO UPDATE
                 SET "updatedAt" = excluded."updatedAt"
         RETURNING "coreProductCountryData".*),
     debug_ins_coreProductCountryData AS (
         INSERT INTO staging.debug_coreProductCountryData
             SELECT * FROM ins_prod_country_data),
     ins_coreProductBarcodes AS (
         INSERT
             INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt", load_id)
                 SELECT id, ean, NOW(), NOW(), 216
                 FROM ins_coreProducts
                 WHERE "updatedAt" >= NOW()::date
                 ON CONFLICT (barcode)
                     DO UPDATE
                         SET "updatedAt" = excluded."updatedAt"
                 RETURNING "coreProductBarcodes".*),
     debug_ins_coreProductBarcodes AS (
         INSERT INTO staging.debug_coreProductBarcodes
             SELECT * FROM ins_coreProductBarcodes)
UPDATE test.tmp_product_pp AS tmp_product_pp
SET "coreProductId"=ins_coreProducts.id
FROM ins_coreProducts
WHERE tmp_product_pp.ean = ins_coreProducts.ean;

--[2024-11-20 20:29:41] completed in 1 s 234 ms
WITH ins_coreProductBarcodes AS (
    INSERT
        INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt", load_id)
            SELECT "coreProductId", ean, NOW(), NOW(), 216
            FROM test.tmp_product_pp
            ON CONFLICT (barcode)
                DO NOTHING
            RETURNING "coreProductBarcodes".*)
INSERT
INTO staging.debug_coreProductBarcodes
SELECT *
FROM ins_coreProductBarcodes;

--[2024-11-20 20:32:09] 11,820 rows affected in 1 s 584 ms
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
                              "coreProductId",
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
                                                           COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates_base
                                CROSS JOIN LATERAL (SELECT DATE_PART('month', lat_dates_base."startDate"::date) ||
                                                           '/' ||
                                                           DATE_PART('day', lat_dates_base."startDate"::date) ||
                                                           '/' ||
                                                           DATE_PART('year', lat_dates_base."startDate"::date) AS "startDate",

                                                           DATE_PART('month', lat_dates_base."endDate"::date) ||
                                                           '/' ||
                                                           DATE_PART('day', lat_dates_base."endDate"::date) ||
                                                           '/' ||
                                                           DATE_PART('year', lat_dates_base."endDate"::date)   AS "endDate"

                           ) AS lat_dates
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."promoId",
                                                                    REPLACE(1 || '_' || "sourceId" ||
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
                                 "coreProductId",
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
     prod_prev_promo AS (SELECT *
                         FROM test.last_product_status
                                  INNER JOIN promotions USING ("productId")),
     upd_product_promo AS (SELECT promo."sourceId",
                                  MAX(promo."promotedPrice") FILTER (WHERE promo.promo_price_order = 1) AS "promotedPrice",
                                  MAX(promo."shelfPrice") FILTER (WHERE promo.promo_price_order = 1)    AS "shelfPrice",
                                  ARRAY_AGG((COALESCE(prev_promo."promoId", promo."promoId"),
                                             promo."retailerPromotionId",
                                             COALESCE(prev_promo."startDate", promo."startDate"),
                                             promo."endDate",
                                             promo.description,
                                             promo."promotionMechanicName",
                                             promo."multibuyPrice")::staging.t_promotion_mb
                                            ORDER BY promo.promo_indx)                                  AS promotions
                           FROM promo_price_calc AS promo
                                    LEFT OUTER JOIN prod_prev_promo AS prev_promo
                                                    ON (prev_promo."coreProductId" = promo."coreProductId" AND
                                                        prev_promo.description = promo.description)
                           GROUP BY 1)
UPDATE test.tmp_product_pp
SET promotions      = upd_product_promo.promotions,
    "promotedPrice" = upd_product_promo."promotedPrice",
    "shelfPrice"    = upd_product_promo."shelfPrice"
FROM upd_product_promo
WHERE tmp_product_pp."sourceId" = upd_product_promo."sourceId";

--[2024-11-20 20:32:44] 145,015 rows affected in 2 s 513 ms
UPDATE test.tmp_product_pp
SET status=CASE
               WHEN '2024-11-17' = last_product_status.date + '1 day'::interval THEN 'Listed'
               ELSE 'Re-listed'
    END,
    "isNpd"= FALSE
FROM test.last_product_status
WHERE last_product_status."coreProductId" = tmp_product_pp."coreProductId";


--[2024-11-20 20:36:51] 373 rows affected in 350 ms
WITH delisted_ids AS (SELECT last_product_status."productId" AS id
                      FROM test.last_product_status
                               LEFT OUTER JOIN test.tmp_product_pp USING ("coreProductId")
                      WHERE tmp_product_pp."coreProductId" IS NULL
                        AND last_product_status.status != 'De-listed'),
     delisted_product AS (SELECT *
                          FROM products
                                   INNER JOIN delisted_ids USING (id)
                                   LEFT OUTER JOIN (SELECT "sourceId" FROM test.tmp_product_pp) AS tmp_product_pp
                                                   USING ("sourceId")
                          WHERE tmp_product_pp."sourceId" IS NULL)
INSERT
INTO test.tmp_product_pp ("sourceType",
                          ean,
    -- promotions,
                          "promotionDescription",
                          features,
                          date,
                          "sourceId",
                          "productBrand",
                          "productTitle",
                          "productImage",
                          "secondaryImages",
                          "productDescription",
                          "productInfo",
    -- "promotedPrice",
                          "productInStock",
                          "productInListing",
    -- "reviewsCount",
    -- "reviewsStars",
                          "eposId",
                          multibuy,
                          "coreProductId",
                          "retailerId",
                          "createdAt",
                          "updatedAt",
                          "imageId",
                          size,
                          "pricePerWeight",
                          href,
                          nutritional,
    --"basePrice",
    --"shelfPrice",
                          "productTitleDetail",
                          "sizeUnit",
                          "dateId",
                          marketplace,
                          "marketplaceData",
                          "priceMatchDescription",
                          "priceMatch",
                          "priceLock",
                          "isNpd",
                          load_id,
                          status)
SELECT "sourceType",
       ean,
       --promotions,
       "promotionDescription",
       features,
       '2024-11-17' AS "date",
       "sourceId",
       "productBrand",
       "productTitle",
       "productImage",
       "secondaryImages",
       "productDescription",
       "productInfo",
       --"promotedPrice",
       "productInStock",
       "productInListing",
       --"reviewsCount",
       --"reviewsStars",
       "eposId",
       multibuy,
       "coreProductId",
       "retailerId",
       "createdAt",
       "updatedAt",
       "imageId",
       size,
       "pricePerWeight",
       href,
       nutritional,
       --"basePrice",
       --"shelfPrice",
       "productTitleDetail",
       "sizeUnit",
       29787        AS "dateId",
       marketplace,
       "marketplaceData",
       "priceMatchDescription",
       "priceMatch",
       "priceLock",
       FALSE        AS "isNpd",
       NULL         AS load_id,
       'De-listed'  AS status
FROM delisted_product;

--[2024-11-20 21:36:02] 146,467 rows affected in 1 m 14 s 27 ms
/*  createProductBy    */
INSERT INTO products ("sourceType",
                      ean,
                      promotions,
                      "promotionDescription",
                      features,
                      date,
                      "sourceId",
                      "productBrand",
                      "productTitle",
                      "productImage",
                      "secondaryImages",
                      "productDescription",
                      "productInfo",
                      "promotedPrice",
                      "productInStock",
                      "reviewsCount",
                      "reviewsStars",
                      "eposId",
                      multibuy,
                      "coreProductId",
                      "retailerId",
                      "createdAt",
                      "updatedAt",
                      size,
                      "pricePerWeight",
                      href,
                      nutritional,
                      "basePrice",
                      "shelfPrice",
                      "productTitleDetail",
                      "sizeUnit",
                      "dateId",
                      marketplace,
                      "marketplaceData",
                      "priceMatchDescription",
                      "priceMatch",
                      "priceLock",
                      "isNpd",
                      load_id)
SELECT "sourceType",
       ean,
       COALESCE(ARRAY_LENGTH(promotions, 1) > 0, FALSE) AS promotions,
       "promotionDescription",
       features,
       date,
       "sourceId",
       "productBrand",
       "productTitle",
       new_img."productImage",
       "secondaryImages",
       "productDescription",
       "productInfo",
       "promotedPrice",
       "productInStock",
       --  "productInListing",
       "reviewsCount",
       "reviewsStars",
       "eposId",
       multibuy,
       "coreProductId",
       "retailerId",
       NOW()                                            AS "createdAt",
       NOW()                                            AS "updatedAt",
       -- "imageId",
       size,
       "pricePerWeight",
       href,
       nutritional,
       "basePrice",
       "shelfPrice",
       "productTitleDetail",
       "sizeUnit",
       "dateId",
       marketplace,
       "marketplaceData",
       "priceMatchDescription",
       "priceMatch",
       "priceLock",
       "isNpd",
       216
FROM test.tmp_product_pp
         CROSS JOIN LATERAL (SELECT CASE
                                        WHEN "sourceType" = 'sainsburys' THEN
                                            REPLACE(
                                                    REPLACE(
                                                            'https://www.sainsburys.co.uk' ||
                                                            "productImage",
                                                            'https://www.sainsburys.co.ukhttps://www.sainsburys.co.uk',
                                                            'https://www.sainsburys.co.uk'),
                                                    'https://www.sainsburys.co.ukhttps://assets.sainsburys-groceries.co.uk',
                                                    'https://assets.sainsburys-groceries.co.uk')
                                        WHEN "sourceType" = 'ocado' THEN REPLACE(REPLACE(
                                                                                         "productImage",
                                                                                         'https://ocado.com',
                                                                                         'https://www.ocado.com'),
                                                                                 'https://www.ocado.comhttps://www.ocado.com',
                                                                                 'https://www.ocado.com')
                                        WHEN "sourceType" = 'morrisons' THEN
                                            REPLACE("productImage",
                                                    'https://groceries.morrisons.comhttps://groceries.morrisons.com',
                                                    'https://groceries.morrisons.com')
                                        END AS "productImage"
    ) AS new_img

ON CONFLICT ("sourceId", "retailerId", "dateId")
WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
    DO
UPDATE
SET "updatedAt"      = excluded."updatedAt",
    "productInStock" = excluded."productInStock",
    "productBrand"   = excluded."productBrand",
    "reviewsCount"   = excluded."reviewsCount",
    "reviewsStars"   = excluded."reviewsStars",
    load_id          = excluded.load_id;

INSERT INTO staging.product_status_history("retailerId", "coreProductId", date, "productId", status)
--SELECT "retailerId", "coreProductId", date, id AS "productId", status
SELECT "retailerId", "coreProductId", date, MAX(id) AS "productId", status
FROM test.tmp_product_pp
GROUP BY "retailerId", "coreProductId", date, status
ON CONFLICT ("retailerId", "coreProductId", date)
    DO UPDATE
    SET status=excluded.status;

INSERT INTO staging.debug_tmp_product_pp (load_id,
                                          id,
                                          "sourceType",
                                          ean,
                                          "promotionDescription",
                                          features,
                                          date,
                                          "sourceId",
                                          "productBrand",
                                          "productTitle",
                                          "productImage",
                                          "newCoreImage",
                                          "secondaryImages",
                                          "productDescription",
                                          "productInfo",
                                          "promotedPrice",
                                          "productInStock",
                                          "productInListing",
                                          "reviewsCount",
                                          "reviewsStars",
                                          "eposId",
                                          multibuy,
                                          "coreProductId",
                                          "retailerId",
                                          "createdAt",
                                          "updatedAt",
                                          "imageId",
                                          size,
                                          "pricePerWeight",
                                          href,
                                          nutritional,
                                          "basePrice",
                                          "shelfPrice",
                                          "productTitleDetail",
                                          "sizeUnit",
                                          "dateId",
                                          "countryCode",
                                          currency,
                                          "cardPrice",
                                          "onPromo",
                                          bundled,
                                          "originalPrice",
                                          "productPrice",
                                          status,
                                          "productOptions",
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
                                          marketplace,
                                          "marketplaceData",
                                          "priceMatchDescription",
                                          "priceMatch",
                                          "priceLock",
                                          "isNpd",
                                          "eanIssues",
                                          screenshot,
                                          "brandId",
                                          "EANs",
                                          promotions)
SELECT tmp_product_pp.load_id,
       id,
       "sourceType",
       ean,
       "promotionDescription",
       features,
       date,
       "sourceId",
       "productBrand",
       "productTitle",
       "productImage",
       "newCoreImage",
       "secondaryImages",
       "productDescription",
       "productInfo",
       "promotedPrice",
       "productInStock",
       "productInListing",
       "reviewsCount",
       "reviewsStars",
       "eposId",
       multibuy,
       "coreProductId",
       "retailerId",
       "createdAt",
       "updatedAt",
       "imageId",
       size,
       "pricePerWeight",
       href,
       nutritional,
       "basePrice",
       "shelfPrice",
       "productTitleDetail",
       "sizeUnit",
       "dateId",
       "countryCode",
       currency,
       "cardPrice",
       "onPromo",
       bundled,
       "originalPrice",
       "productPrice",
       status,
       "productOptions",
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
       marketplace,
       "marketplaceData",
       "priceMatchDescription",
       "priceMatch",
       "priceLock",
       "isNpd",
       "eanIssues",
       screenshot,
       "brandId",
       "EANs",
       promotions
FROM test.tmp_product_pp;

/*  createAmazonProduct */
/*
   TO DO: set UQ constrain in amazonProducts on productId?.
 */
WITH debug_ins_amz AS (INSERT INTO "amazonProducts" ("productId",
                                                     shop,
                                                     choice,
                                                     "lowStock",
                                                     "sellParty",
                                                     sell,
                                                     "fulfilParty",
                                                     "createdAt",
                                                     "updatedAt", load_id)
    SELECT id                                                                         AS "productId",
           COALESCE(COALESCE(product."amazonShop", product.shop), '')                 AS shop,
           COALESCE(COALESCE(product."amazonChoice", product.choice), '')             AS choice,
           COALESCE(product."lowStock", FALSE)                                        AS "lowStock",
           COALESCE(COALESCE(product."amazonSellParty", product."sellParty"), '')     AS "sellParty",
           COALESCE(COALESCE(product."amazonSell", product."sell"), '')               AS "sell",
           COALESCE(COALESCE(product."amazonFulfilParty", product."fulfilParty"), '') AS "fulfilParty",
           NOW(),
           NOW(),
           216
    FROM test.tmp_product_pp AS product
    WHERE LOWER("sourceType") LIKE '%amazon%'
    RETURNING "amazonProducts".*)
INSERT
INTO staging.debug_amazonproducts
SELECT *
FROM debug_ins_amz;


/*  setCoreRetailer */
DROP TABLE IF EXISTS tmp_coreRetailer;
CREATE TEMPORARY TABLE tmp_coreRetailer ON COMMIT DROP AS
WITH ins_coreRetailers AS (
    INSERT INTO "coreRetailers" ("coreProductId",
                                 "retailerId",
                                 "createdAt",
                                 "updatedAt", load_id)
        SELECT DISTINCT product."coreProductId",
                        1,
                        NOW() AS "createdAt",
                        NOW() AS "updatedAt",
                        216
        FROM test.tmp_product_pp AS product
        ON CONFLICT ("coreProductId",
            "retailerId") DO UPDATE SET "updatedAt" = excluded."updatedAt"
        RETURNING "coreRetailers".*)
SELECT DISTINCT ins_coreRetailers.id,
                "coreProductId",
                ins_coreRetailers."retailerId",
                product."sourceId",
                ins_coreRetailers."createdAt",
                ins_coreRetailers."updatedAt"
FROM ins_coreRetailers
         INNER JOIN test.tmp_product_pp AS product USING ("coreProductId");

INSERT
INTO staging.debug_coreRetailers (load_id, "sourceId", id, "coreProductId", "retailerId", "createdAt",
                                  "updatedAt")
SELECT 216, "sourceId", id, "coreProductId", "retailerId", "createdAt", "updatedAt"
FROM tmp_coreRetailer;


/*  coreRetailerSources */
INSERT INTO "coreRetailerSources"("coreRetailerId", "retailerId", "sourceId", "createdAt", "updatedAt", load_id)
SELECT id, "retailerId", "sourceId", "createdAt", "updatedAt", 216
FROM tmp_coreRetailer
ON CONFLICT DO NOTHING;


/*  saveProductStatus   */
WITH debug_productStatuses AS ( INSERT INTO "productStatuses" ("productId",
                                                               status,
                                                               screenshot,
                                                               "createdAt",
                                                               "updatedAt", load_id)
    SELECT id AS "productId",
           status,
           screenshot,
           NOW(),
           NOW(),
           216
    FROM tmp_product_pp
    ON CONFLICT ("productId")
        DO NOTHING
    RETURNING "productStatuses".*)
INSERT
INTO staging.debug_productStatuses
SELECT *
FROM debug_productStatuses;

--  UPDATE SET "updatedAt" = excluded."updatedAt";

/*  PromotionService.processProductPromotions, part 2 insert promotions  */
WITH debug_ins_promotions AS (
    INSERT INTO promotions ("retailerPromotionId",
                            "productId",
                            description,
                            "startDate",
                            "endDate",
                            "createdAt",
                            "updatedAt",
                            "promoId", load_id)
        SELECT DISTINCT "retailerPromotionId",
                        id    AS "productId",
                        description,
                        "startDate",
                        "endDate",
                        NOW() AS "createdAt",
                        NOW() AS "updatedAt",
                        "promoId",
                        216
        FROM tmp_product_pp
                 CROSS JOIN LATERAL UNNEST(promotions) AS promo
        ON CONFLICT ("productId", "promoId", "retailerPromotionId", "description", "startDate", "endDate")
            WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
            DO
                UPDATE
                SET "updatedAt" = excluded."updatedAt"
        RETURNING promotions.*)
INSERT
INTO staging.debug_promotions
SELECT *
FROM debug_ins_promotions;

/*  aggregatedProducts  */
WITH debug_ins_aggregatedProducts AS (
    INSERT INTO "aggregatedProducts" ("titleMatch",
                                      "productId",
                                      "createdAt",
                                      "updatedAt", load_id
        /*
        TO DO:
        Handle the rest of the "match" scores:
            features,
            specification,
            size,
            description,
            ingredients,
            "imageMatch"
         */
        )
        SELECT compareTwoStrings("titleParent", "productTitle") AS "titleMatch",
               id                                               AS "productId",
               NOW()                                            AS "createdAt",
               NOW()                                               "updatedAt",
               216
        FROM tmp_product_pp
                 INNER JOIN (SELECT "coreProductId", title AS "titleParent"
                             FROM "coreProductCountryData"
                             WHERE "countryId" = dd_retailer."countryId") AS parentProdCountryData
                            USING ("coreProductId")
        ON CONFLICT ("productId")
            WHERE "createdAt" >= '2024-05-31 20:21:46.840963+00'
            DO NOTHING
        RETURNING "aggregatedProducts".*)
INSERT
INTO staging.debug_aggregatedProducts
SELECT *
FROM debug_ins_aggregatedProducts;

--  UPDATE SET "updatedAt" = excluded."updatedAt";

/*  coreRetailerDates */
WITH debug_coreRetailerDates AS ( INSERT INTO "coreRetailerDates" ("coreRetailerId",
                                                                   "dateId",
                                                                   "createdAt",
                                                                   "updatedAt", load_id)
    SELECT tmp_coreRetailer.id AS "coreRetailerId",
           '2024-11-17'_id AS "dateId", NOW(),
           NOW(),
           216
    FROM tmp_coreRetailer
    ON CONFLICT ("coreRetailerId",
        "dateId")
        DO NOTHING
    RETURNING "coreRetailerDates".*)
INSERT
INTO staging.debug_coreRetailerDates
SELECT *
FROM debug_coreRetailerDates;

DROP TABLE IF EXISTS last_product_status;
--  UPDATE SET "updatedAt" = excluded."updatedAt";

RETURN;
END;
$$;
