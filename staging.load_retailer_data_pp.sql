DROP TYPE IF EXISTS staging.t_promotion_mb CASCADE;
CREATE TYPE staging.t_promotion_mb AS
(
    "promoId"             text,
    "retailerPromotionId" integer,
    "startDate"           timestamp,
    "endDate"             timestamp,
    description           text,
    mechanic              text,
    "multibuyPrice"       float
);

DROP FUNCTION IF EXISTS staging.load_retailer_data_pp(jsonb);
CREATE OR REPLACE FUNCTION staging.load_retailer_data_pp(value json) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    dd_date               date;
    dd_source_type        text;
    dd_sourceCategoryType text;
    dd_date_id            integer;
    dd_retailer           retailers;
BEGIN


    dd_date := value #> '{products,0,date}';

    SELECT *
    INTO dd_retailer
    FROM JSON_POPULATE_RECORD(NULL::retailers,
                              value #> '{retailer}') AS retailer;

    SELECT id
    INTO dd_date_id
    FROM dates
    WHERE date = dd_date AT TIME ZONE 'UTC';

    IF dd_date_id IS NULL THEN
        INSERT INTO dates (date) VALUES (dd_date) RETURNING id INTO dd_date_id;
    END IF;

    DROP TABLE IF EXISTS staging.tmp_product_pp;
    CREATE TABLE staging.tmp_product_pp AS
    WITH prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands),
         tmp_daily_data_pp AS (SELECT product.date,
                                      product."countryCode",
                                      product."currency",
                                      product."sourceId",
                                      product.ean,
                                      product."brand",
                                      product."title",
                                      fn_to_float(product."shelfPrice")                                 AS "shelfPrice",
                                      fn_to_float(product."wasPrice")                                   AS "wasPrice",
                                      fn_to_float(product."cardPrice")                                  AS "cardPrice",
                                      fn_to_boolean(product."inStock")                                  AS "inStock",
                                      fn_to_boolean(product."onPromo")                                  AS "onPromo",
                                      COALESCE(product."promoData", ARRAY []::staging.t_promotion_pp[]) AS "promoData",
                                      COALESCE(product."skuURL", '')                                    AS href,
                                      product."imageURL",
                                      COALESCE(fn_to_boolean(product."bundled"), FALSE)                 AS "bundled",
                                      COALESCE(fn_to_boolean(product."masterSku"), FALSE)               AS "productOptions",
                                      ROW_NUMBER() OVER (PARTITION BY "sourceId")                       AS rownum -- use only the first sourceId record
                               FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                            value #> '{products}') AS product),
         dd_products AS (SELECT COALESCE("wasPrice", "shelfPrice") AS "originalPrice",
                                "shelfPrice"                       AS "productPrice",
                                "shelfPrice",
                                COALESCE("brand", '')              AS "productBrand",

                                'listing'                          AS status,

                                COALESCE("title", '')              AS "productTitle",
                                COALESCE("imageURL", '')           AS "productImage",
                                COALESCE("inStock", TRUE)          AS "productInStock",

                                date,
                                "countryCode",
                                "currency",
                                ean,
                                "brand",
                                "title",
                                href,

                                "sourceId",
                                "cardPrice",
                                "bundled",
                                "productOptions",
                                "promoData",
                                "onPromo",
                                ROW_NUMBER() OVER ()               AS index
                         FROM tmp_daily_data_pp

                         WHERE rownum = 1)

    SELECT NULL                                                                AS id,
           dd_retailer.name                                                    AS "sourceType",
           trsf_ean."EANs"[1]                                                  AS ean,
           COALESCE(ARRAY_LENGTH(trsf_promo.promotions, 1) > 0, FALSE)         AS products_promotions_flag,
           COALESCE(trsf_promo."promotionDescription", '')                     AS "promotionDescription",
           ''                                                                  AS features,
           dd_products.date,
           dd_products."sourceId",
           dd_products."productBrand",
           dd_products."productTitle",
           dd_products."productImage",
           FALSE                                                               AS secondaryImages,
           ''                                                                  AS "productDescription",
           ''                                                                  AS "productInfo",
           dd_products."originalPrice"                                         AS "promotedPrice",
           dd_products."productInStock",
           TRUE                                                                AS "productInListing",
           NULL                                                                AS "reviewsCount",
           NULL                                                                AS "reviewsStars",
           NULL                                                                AS "eposId",
           COALESCE(trsf_promo.is_multibuy, FALSE)                             AS multibuy,
           NULL                                                                AS "coreProductId",
           dd_retailer.id                                                      AS "retailerId",
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
           dd_date_id                                                          AS "dateId",

           dd_products."countryCode",
           dd_products."currency",
           dd_products."cardPrice",
           dd_products."onPromo",
           dd_products."bundled",
           dd_products."originalPrice",
           dd_products."productPrice",
           dd_products.status,

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
                   WHEN
                       dd_products."productOptions"
                       THEN ARRAY [ dd_retailer.name || '_' || dd_products."sourceId"] :: TEXT[]
                   ELSE
                       STRING_TO_ARRAY(dd_products.ean, ',') END AS "EANs"
        ) AS trsf_ean
             CROSS JOIN LATERAL ( SELECT ARRAY_AGG(
                                                 (
                                                  promo_id,-- AS "promoId",
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
             LEFT OUTER JOIN prod_brand USING ("productBrand");

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

                                  lat_promo_id."promoId",
                                  promo.description,
                                  promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.
                                  fn_to_float(promo."multibuyPrice")                      AS "multibuyPrice",

                                  COALESCE(ret_promo."retailerPromotionId",
                                           default_ret_promo."retailerPromotionId")       AS "retailerPromotionId",
                                  COALESCE(ret_promo.regexp, default_ret_promo.regexp)    AS regexp,
                                  COALESCE(ret_promo."promotionMechanicId",
                                           default_ret_promo."promotionMechanicId")       AS "promotionMechanicId",
                                  COALESCE(
                                          ret_promo."promotionMechanicName",
                                          default_ret_promo."promotionMechanicName")      AS "promotionMechanicName",
                                  ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx) AS rownum
                           FROM staging.tmp_product_pp AS product
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
                                                                        REPLACE(dd_retailer.id || '_' || "sourceId" ||
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
         upd_product_promo AS (SELECT "sourceId",
                                      MAX(description) FILTER (WHERE "promotionMechanicName" = 'Multibuy')     AS Multibuy_description,
                                      MAX("multibuyPrice") FILTER (WHERE "promotionMechanicName" = 'Multibuy') AS "multibuyPrice",
                                      ARRAY_AGG(("promoId",
                                                 "retailerPromotionId",
                                                 "startDate",
                                                 "endDate",
                                                 description,
                                                 "promotionMechanicName",
                                                 "multibuyPrice")::staging.t_promotion_mb
                                                ORDER BY promo_indx)                                           AS promotions
                               FROM product_promo
                               WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
                               GROUP BY 1)
    UPDATE staging.tmp_product_pp
    SET promotions=upd_product_promo.promotions,
        "promotedPrice" = CASE
                              WHEN tmp_product_pp.multibuy THEN
                                  COALESCE(upd_product_promo."multibuyPrice",
                                           staging.calculateMultibuyPrice(upd_product_promo.Multibuy_description,
                                                                          all_products."promotedPrice")
                                  )
                              ELSE all_products."productPrice"
            END,
        "shelfPrice" = CASE
                           WHEN tmp_product_pp.multibuy
                               THEN tmp_product_pp."shelfPrice"
                           ELSE
                               all_products."productPrice"
            END
    FROM staging.tmp_product_pp AS all_products
             LEFT OUTER JOIN upd_product_promo
                             ON all_products."sourceId" = upd_product_promo."sourceId"
    WHERE tmp_product_pp."sourceId" = all_products."sourceId";


    RETURN;
END ;
$$;

SELECT staging.load_retailer_data_pp(fetched_data)
FROM staging.retailer_daily_data
WHERE flag = 'create-products-pp'
  AND created_at = '2024-04-16 08:00:00.878527+00'
LIMIT 1 OFFSET 1;



SELECT *
FROM staging.tmp_product_pp
WHERE multibuy;


SELECT *
FROM staging.tests_daily_data_pp
WHERE "sourceId" = '153792'
  AND file_src = 'b&m__2024-04-16 08:00:00.878527+00';



SELECT brand, COUNT(*)
FROM staging.tests_daily_data_pp
GROUP BY brand;

SELECT DISTINCT file_src
FROM staging.tests_daily_data_pp
WHERE brand = 'Cadbury';

WHERE "sourceId" = '258640'
  AND file_src = 'b&m__2024-04-16 08:00:00.878527+00';


SELECT DISTINCT --"sourceId",
                promo_type,
                promo_description,
                multibuy_price
FROM staging.tests_daily_data_pp
         CROSS JOIN LATERAL UNNEST("promoData") AS promo
WHERE multibuy_price IS NOT NULL
  AND file_src = 'b&m__2024-04-16 08:00:00.878527+00';



SELECT file_src, "sourceId"
FROM staging.tests_daily_data_pp
GROUP BY 1, 2
HAVING COUNT(*) > 1;

SELECT id AS "brandId", name AS "productBrand"
FROM brands
WHERE name LIKE 'B&%';

WITH brands AS (SELECT id, name FROM brands),
     product_brands AS (SELECT brand, COUNT(*) AS rec_cnt
                        FROM staging.tests_daily_data_pp
                        WHERE brand != ''
                        GROUP BY brand),
     product_brands_unmatched AS (SELECT product_brands.brand
                                  FROM product_brands
                                           LEFT OUTER JOIN brands ON (brands.name = brand)
                                  WHERE brands.id IS NULL),
     prod_brand_possible_match AS (SELECT brand, STRING_AGG(brands_like.name, ',') AS similar_brands
                                   FROM product_brands_unmatched
                                            INNER JOIN brands AS brands_like
                                                       ON (brands_like.name LIKE brand || '%')
                                   GROUP BY brand)
SELECT *
FROM prod_brand_possible_match
         INNER JOIN product_brands USING (brand)
ORDER BY rec_cnt DESC;


SET pg_trgm.similarity_threshold = 0.8; -- Postgres 9.6 or later

WITH brands AS (SELECT id, name FROM brands),
     product_brands AS (SELECT brand, COUNT(*) AS rec_cnt
                        FROM staging.tests_daily_data_pp
                        WHERE brand != ''
                        GROUP BY brand),
     product_brands_unmatched AS (SELECT product_brands.brand
                                  FROM product_brands
                                           LEFT OUTER JOIN brands ON (brands.name = brand)
                                  WHERE brands.id IS NULL),
     prod_brand_possible_match AS (SELECT umbrands.brand, STRING_AGG(brands.name, ',') AS similar_brands
                                   FROM product_brands_unmatched umbrands
                                            JOIN brands ON LOWER(umbrands.brand) != LOWER(brands.name) AND
                                                           TO_TSVECTOR(umbrands.brand) @@ PLAINTO_TSQUERY(brands.name)
                                   --                    umbrands.brand % brands.name
                                   GROUP BY brand)
SELECT *
FROM prod_brand_possible_match
         INNER JOIN product_brands USING (brand)
ORDER BY rec_cnt DESC;



WITH brands AS (SELECT id, name FROM brands),
     product_brands AS (SELECT brand, COUNT(*) AS rec_cnt
                        FROM staging.tests_daily_data_pp
                        WHERE brand != ''
                        GROUP BY brand),
     product_brands_unmatched AS (SELECT product_brands.brand
                                  FROM product_brands
                                           LEFT OUTER JOIN brands ON (brands.name = brand)
                                  WHERE brands.id IS NULL),
     prod_brand_possible_match AS (SELECT umbrands.brand, STRING_AGG(brands.name, ',') AS similar_brands
                                   FROM product_brands_unmatched umbrands
                                            JOIN brands ON LOWER(umbrands.brand) != LOWER(brands.name) AND
                                                           umbrands.brand % brands.name
                                   GROUP BY brand)
SELECT *
FROM prod_brand_possible_match
         INNER JOIN product_brands USING (brand)
ORDER BY rec_cnt DESC;

WITH data_comp AS (SELECT id,
                          name
                   FROM "sourceCategories")
SELECT a.name, STRING_AGG(b.name, ',' ORDER BY similarity(a.name, b.name) DESC, b.name) AS similar_names
FROM data_comp a
         INNER JOIN data_comp b
                    ON a.name >
                       b.name
                        --AND a.name % b.name
                        AND a.name LIKE b.name || '%'
GROUP BY a.name;


WITH tmp_product_pp AS (SELECT * FROM staging.tmp_product_pp WHERE "sourceId" IN ('153792', '382203')),
     ret_promo AS (SELECT id AS "retailerPromotionId",
                          "retailerId",
                          "promotionMechanicId",
                          regexp,
                          "promotionMechanicName"
                   FROM "retailerPromotions"
                            INNER JOIN (SELECT id   AS "promotionMechanicId",
                                               name AS "promotionMechanicName"
                                        FROM "promotionMechanics") AS "promotionMechanics"
                                       USING ("promotionMechanicId")
                   WHERE "retailerId" = 114)
SELECT product."retailerId",
       "sourceId",
       promo_indx,

       promo.description,
       promo_desc_trsf.desc,
       promo.mechanic, -- Does not exists in the sample retailer data.  Is referenced in the nodejs model.

       LOWER(ret_promo."promotionMechanicName") =
       COALESCE(promo.mechanic, ''),
       ret_promo.regexp IS NULL OR LENGTH(ret_promo.regexp) = 0,
       LENGTH(ret_promo.regexp) = 0                            AS len0,
       ret_promo."promotionMechanicName" = 'Multibuy' AND
       promo_desc_trsf.desc ~ '(\d+\/\d+)',
       promo_desc_trsf.desc ~ ret_promo.regexp,

       fn_to_float(promo."multibuyPrice")                      AS "multibuyPrice",
       ret_promo."retailerPromotionId",
       ret_promo.regexp,
       ret_promo."promotionMechanicId",
       ret_promo."promotionMechanicName",
       ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx) AS rownum
FROM tmp_product_pp AS product
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
         LEFT OUTER JOIN ret_promo
                         ON (product."retailerId" = ret_promo."retailerId" AND
                             CASE
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
                             )
;

SELECT DISTINCT "sourceId",
                promo_type,
                promo_description,
                multibuy_price,
                promo_args.*,
                calculated_multibuy_price
FROM staging.tests_daily_data_pp
         CROSS JOIN LATERAL UNNEST("promoData") AS promo
         CROSS JOIN LATERAL REGEXP_MATCH(promo_description, '.*(\d+) FOR ([£$€]{0,1})(\d+[\.\d]*).*',
                                         'i') AS promo_regex
         CROSS JOIN LATERAL (SELECT promo_regex[1]::integer           AS promo_quantity,
                                    promo_regex[2]                    AS promo_currency,
                                    promo_regex[3]::float             AS promo_total,
                                    "wasPrice",
                                    "shelfPrice",
                                    COALESCE(
                                            "wasPrice", "shelfPrice") AS "productPrice") AS promo_args
         CROSS JOIN LATERAL (SELECT ROUND(
                                            (CASE
                                                 WHEN promo_currency = ''
                                                     THEN "productPrice" * promo_total
                                                 ELSE promo_total END / promo_quantity)::numeric,
                                            2) AS calculated_multibuy_price) AS calcs
WHERE promo_type = 'multibuy'
  AND calculated_multibuy_price != multibuy_price::float;


WHERE promo_description IN ('ANY 2 FOR £2.60',
                            'BUY 2 FOR £1.50',
                            'BUY 3 FOR £4.50',
                            'BUY ANY 2 FOR £1.50',
                            'BUY ANY 2 FOR £2.50',
                            'BUY ANY 2 FOR £3.25',
                            'BUY ANY 2 FOR £3.50',
                            'BUY ANY 3 FOR £1.20',
                            'BUY ANY 3 FOR £4.50');



SELECT "retailerId",
       "sourceId",
       "promotionDescription",
       "productPrice",

       "originalPrice",
       "promotedPrice",


       "basePrice",
       "shelfPrice",
       "cardPrice",
       promo.*
FROM staging.tmp_product_pp
         CROSS JOIN LATERAL UNNEST(promotions) AS promo
WHERE "sourceId" IN ('153792', '382203');
--WHERE multibuy;

WITH ret_promo AS (SELECT id AS "retailerPromotionId",
                          "retailerId",
                          "promotionMechanicId",
                          regexp,
                          "promotionMechanicName"
                   FROM "retailerPromotions"
                            INNER JOIN (SELECT id   AS "promotionMechanicId",
                                               name AS "promotionMechanicName"
                                        FROM "promotionMechanics") AS "promotionMechanics"
                                       USING ("promotionMechanicId"))
SELECT *
FROM ret_promo
WHERE "retailerId" = 114;


SELECT *, LENGTH(regexp)
FROM "retailerPromotions"
WHERE "retailerId" = 114;


UPDATE "retailerPromotions"
SET regexp=''
WHERE "retailerId" = 114;


