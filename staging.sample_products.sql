SET work_mem TO '4GB'; --5463728KB

CREATE TABLE staging.tmp_prod2 AS
WITH data AS (SELECT fetched_data #> '{retailer}' AS "retailer",
                     product.*
              FROM staging.retailer_daily_data11
                       CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(fetched_data #> '{products}') AS product_json
                       CROSS JOIN LATERAL (
                  SELECT product_json #>> '{ean}'                               AS "ean",
                         (product_json #>> '{date}')::date                      AS "date",
                         product_json #>> '{href}'                              AS "href",
                         product_json #>> '{size}'                              AS "size",
                         product_json #>> '{eposId}'                            AS "eposId",
                         product_json #>> '{status}'                            AS "status",       --'listed','newly',
                         (product_json #>> '{bundled}')::boolean                AS "bundled",
                         product_json #>> '{category}'                          AS "category",
                         (product_json #>> '{featured}')::boolean               AS "featured",
                         product_json #>> '{features}'                          AS "features",
                         (product_json #>> '{multibuy}')::boolean               AS "multibuy",
                         product_json #>> '{sizeUnit}'                          AS "sizeUnit",
                         product_json #>> '{sourceId}'                          AS "sourceId",
                         (product_json #>> '{inTaxonomy}')::boolean             AS "inTaxonomy",
                         (product_json #>> '{isFeatured}')::boolean             AS "isFeatured",
                         product_json #>> '{pageNumber}'                        AS "pageNumber",
                         product_json #>> '{promotions}'                        AS "promotions",
                         product_json #>> '{screenshot}'                        AS "screenshot",
                         product_json #>> '{sourceType}'                        AS "sourceType",
                         (product_json #>> '{taxonomyId}')::integer             AS "taxonomyId",
                         product_json #>> '{nutritional}'                       AS "nutritional",
                         product_json #>> '{productInfo}'                       AS "productInfo",
                         (product_json #>> '{productRank}')::integer            AS "productRank",
                         product_json #>> '{categoryType}'                      AS "categoryType", --'search','aisle','shelf',
                         (product_json #>> '{featuredRank}')::integer           AS "featuredRank",
                         product_json #>> '{productBrand}'                      AS "productBrand",
                         product_json #>> '{productImage}'                      AS "productImage",
                         (product_json #>> '{productPrice}')::double precision  AS "productPrice",
                         product_json #>> '{productTitle}'                      AS "productTitle",
                         (product_json #>> '{reviewsCount}')::integer           AS "reviewsCount",
                         (product_json #>> '{reviewsStars}')::double precision  AS "reviewsStars",
                         (product_json #>> '{originalPrice}')::double precision AS "originalPrice",
                         product_json #>> '{pricePerWeight}'                    AS "pricePerWeight",
                         (product_json #>> '{productInStock}')::boolean         AS "productInStock",
                         (product_json #>> '{secondaryImages}')::boolean        AS "secondaryImages",
                         product_json #>> '{productDescription}'                AS "productDescription",
                         product_json #>> '{productTitleDetail}'                AS "productTitleDetail",
                         product_json #>> '{promotionDescription}'              AS "promotionDescription"
                  ) AS product)
SELECT *
FROM data;



CREATE TABLE staging.tmp_prod2 AS
WITH data AS (SELECT fetched_data #> '{retailer}' AS "retailer",
                     product
              FROM staging.retailer_daily_data11
                       CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(fetched_data #> '{products}') AS product)
SELECT *
FROM data;


CREATE TABLE staging.tmp_prod3 AS
WITH data AS (SELECT fetched_data #> '{retailer}' AS "retailer",
                     product.ean,
                     product.date,
                     product.href,
                     product.size,
                     product."eposId",
                     product.status,
                     product.bundled,
                     product.category,
                     product.featured,
                     product.features,
                     product.multibuy,
                     product."sizeUnit",
                     product."sourceId",
                     product."inTaxonomy",
                     product."isFeatured",
                     product."pageNumber",
                     product.promotions,
                     product.screenshot,
                     product."sourceType",
                     product."taxonomyId",
                     product.nutritional,
                     product."productInfo",
                     product."productRank",
                     product."categoryType",
                     product."featuredRank",
                     product."productBrand",
                     product."productImage",
                     product."productPrice",
                     product."productTitle",
                     product."reviewsCount",
                     product."reviewsStars",
                     product."originalPrice",
                     product."pricePerWeight",
                     product."productInStock",
                     product."secondaryImages",
                     product."productDescription",
                     product."productTitleDetail",
                     product."promotionDescription"
              FROM staging.retailer_daily_data11
                       CROSS JOIN LATERAL JSONB_POPULATE_RECORDSET(NULL::staging.tmp_prod,
                                                                   fetched_data #> '{products}') AS product)
SELECT *
FROM data;



SELECT ARRAY_AGG(tmp_prod) AS products
FROM staging.tmp_prod

