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

    SELECT id
    INTO dd_date_id
    FROM dates
    WHERE date = dd_date AT TIME ZONE 'UTC';

    IF dd_date_id IS NULL THEN
        INSERT INTO dates (date) VALUES (dd_date) RETURNING id INTO dd_date_id;
    END IF;

    DROP TABLE IF EXISTS staging.tmp_daily_data_pp;
    CREATE TABLE staging.tmp_daily_data_pp AS
    WITH tmp_daily_data_pp AS (SELECT product.date,
                                      product."countryCode",
                                      product."currency",
                                      product."sourceId",
                                      product.ean,
                                      product."brand",
                                      product."title",
                                      fn_to_float(product."shelfPrice")  AS "shelfPrice",
                                      fn_to_float(product."wasPrice")    AS "wasPrice",
                                      fn_to_float(product."cardPrice")   AS "cardPrice",
                                      fn_to_boolean(product."inStock")   AS "inStock",
                                      fn_to_boolean(product."onPromo")   AS "onPromo",
                                      product."promoData",
                                      product."skuURL",
                                      product."imageURL",
                                      fn_to_boolean(product."bundled")   AS "bundled",
                                      fn_to_boolean(product."masterSku") AS "masterSku",
                                      ROW_NUMBER() OVER ()               AS index
                               FROM JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                            value #> '{products}') AS product)

    SELECT dd_products.date,
           dd_products."countryCode",
           dd_products."currency",
           dd_products."sourceId",
           trsf_ean."EANs"[1]                                               AS ean,

           trsf_ean."EANs",
           COALESCE(trsf_promo.promotions, ARRAY []::staging.t_promotion[]) AS promotions,
           row.promotions                                                   AS promotions_pp,
           dd_products."cardPrice",
           dd_products."onPromo",
           dd_products."bundled",

           row."productPrice",
           row."originalPrice",
           row."productBrand",
           row."productTitle",
           row."productTitleDetail",
           row."productInStock",

           row.href,
           row."productImage",
           row."productOptions",
           row."sourceType",
           row."promotionDescription",
           row."category",
           row."categoryType",
           row.screenshot,
           row.nutritional,
           row.size,
           row.productInfo,
           row.features,
           row.productDescription,
           row.secondaryImages,
           row.status,
           row."pageNumber",
           row."productRank",
           row."featuredRank"

    FROM tmp_daily_data_pp AS dd_products
             CROSS JOIN LATERAL (SELECT COALESCE("brand", '')                                     AS "productBrand",
                                        COALESCE("title", '')                                     AS "productTitle",
                                        COALESCE("title", '')                                     AS "productTitleDetail",
                                        COALESCE("inStock", TRUE)                                 AS "productInStock",
                                        COALESCE("promoData", ARRAY []::staging.t_promotion_pp[]) AS promotions,
                                        COALESCE("skuURL", '')                                    AS href,
                                        COALESCE("imageURL", '')                                  AS "productImage",
                                        COALESCE("bundled", FALSE)                                AS "bundled",
                                        COALESCE("masterSku", FALSE)                              AS "productOptions",
                                        value #> '{retailer,name}'                                AS "sourceType",
                                        "shelfPrice"                                              AS "productPrice",
                                        COALESCE("wasPrice", "shelfPrice")                        AS "originalPrice",
                                        ''                                                        AS "promotionDescription",
                                        ''                                                        AS "category",
                                        'taxonomy'                                                AS "categoryType",

                                        ''                                                        AS screenshot,
                                        ''                                                        AS nutritional,
                                        ''                                                        AS size,
                                        ''                                                        AS productInfo,
                                        ''                                                        AS features,
                                        ''                                                        AS productDescription,
                                        FALSE                                                     AS secondaryImages,
                                        'listing'                                                 AS status,

                                        1                                                         AS "pageNumber",
                                        INDEX                                                     AS "productRank",
                                        INDEX                                                     AS "featuredRank"
        ) AS ROW
             CROSS JOIN LATERAL
        (
        SELECT CASE
                   WHEN
                       ROW
                           .
                           "productOptions"
                       THEN
                       ARRAY [
                           ROW
                               .
                               "sourceType"
                               ||
                           '_'
                               ||
                           dd_products
                               .
                               "sourceId"]
                           ::
                           TEXT[]
                   ELSE
                       STRING_TO_ARRAY
                       (
                               dd_products
                                   .
                                   ean,
                               ','
                       ) END AS "EANs"
        ) AS trsf_ean
             CROSS JOIN LATERAL
        (
        SELECT ARRAY_AGG(
                       (
                        promo_id,-- AS "promoId",
                        NULL,--"retailerPromotionId"
                        NULL,-- AS "startDate",
                        NULL,--AS "endDate"
                        promo_description,--AS description,
                        promo_type--,-- AS mechanic,
                           --  multibuy_price-- AS "multibuyPrice"
                           )::staging.t_promotion) AS promotions
        FROM UNNEST
             (
                     promotions
             ) AS promo
                 (
                  promo_id,
                  promo_type,
                  promo_description,
                  multibuy_price
                     )
        ) AS trsf_promo;


    RETURN;
END ;
$$;

SELECT staging.load_retailer_data_pp(fetched_data)
FROM staging.retailer_daily_data
WHERE flag = 'create-products-pp'
LIMIT 1 OFFSET 8;


SELECT *
FROM staging.tmp_daily_data_pp
where array_length("EANs",1)>1