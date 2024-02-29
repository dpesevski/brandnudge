/*
SELECT staging.load_retailer_data('{
  "retailer": "sainsburys",
  "products": [
    {
      "ean": "5000168208749",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-milk-chocolate-433g",
      "size": "435",
      "eposId": "7955636",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "45% Wheat and Wholemeal. No Hydrogenated Vegetable Oil. The Nation''s Favourite. No Artificial Colours or Flavours. Suitable for Vegetarians. The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955636",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[{\"key\":\"Energy (kJ)\",\"value\":\"2078\"},{\"key\":\"(kcal)\",\"value\":\"496\"},{\"key\":\"Fat\",\"value\":\"23.6g\"},{\"key\":\"of which Saturates\",\"value\":\"12.4g\"},{\"key\":\"Carbohydrate\",\"value\":\"62.5g\"},{\"key\":\"of which Sugars\",\"value\":\"28.5g\"},{\"key\":\"Fibre\",\"value\":\"3g\"},{\"key\":\"Protein\",\"value\":\"6.7g\"},{\"key\":\"Salt\",\"value\":\"0.94g\"},{\"key\":\"Typical number of biscuits per pack: 26\",\"value\":\"\"}]",
      "productInfo": "Flour (39%) (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Milk Chocolate (30%) [Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Dried Whey (Milk), Butter Oil (Milk), Vegetable Fats (Palm, Shea), Emulsifiers (Soya Lecithin, E476), Natural Flavouring], Vegetable Oil (Palm), Wholemeal Wheat Flour (9%), Sugar, Glucose-Fructose Syrup, Raising Agents (Sodium Bicarbonate, Malic Acid, Ammonium Bicarbonate), Salt",
      "productRank": 11,
      "categoryType": "search",
      "featuredRank": 11,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955636/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "reviewsCount": "26",
      "reviewsStars": "3.9231",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "Wheatmeal Biscuits Covered in Milk Chocolate",
      "productTitleDetail": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "promotionDescription": ""
    },
    {
      "ean": "5000168208763",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-dark-chocolate-433g",
      "size": "435",
      "eposId": "7955692",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955692",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[]",
      "productInfo": "",
      "productRank": 12,
      "categoryType": "search",
      "featuredRank": 12,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955692/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "reviewsCount": "14",
      "reviewsStars": "4.6429",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org. McVitie''s golden-baked, crunchy wheat biscuits, topped with a layer of smooth, dark chocolate. McVitie''s Chocolate Digestives are the nation''s favourite biscuits.. Enjoy a little break from the everyday, McVitie''s biscuits are too good not to share.. McVitie''s biscuits are Too Good Not to Share.. Find us at www.mcvities.co.ukwww.123healthybalance.co. By Appointment to Her Majesty The Queen Biscuit Manufacturers United Biscuits (UK) Limited, Hayes",
      "productTitleDetail": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "promotionDescription": ""
    }
  ]
}');
 */

--DROP FUNCTION IF EXISTS staging.load_retailer_data(jsonb);
CREATE OR REPLACE FUNCTION staging.load_retailer_data(value jsonb) RETURNS void
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
    /*
    INSERT INTO staging.retailer_daily_data (fetched_data)
    VALUES (value);
    */
    DROP TABLE IF EXISTS staging.tmp_daily_data;
    CREATE TABLE staging.tmp_daily_data AS
    SELECT product.*
    FROM staging.retailer_daily_data
             CROSS JOIN LATERAL JSONB_POPULATE_RECORDSET(NULL::staging.retailer_data,
                                                         fetched_data -> 'products') AS product;

    SELECT date, "sourceType", CASE WHEN "categoryType" = 'search' THEN 'search' ELSE 'taxonomy' END
    INTO dd_date, dd_source_type, dd_sourceCategoryType
    FROM staging.tmp_daily_data
    LIMIT 1;

    /*  ProductService.getCreateProductCommonData  */
    /*  dates.findOrCreate  */
    SELECT id
    INTO dd_date_id
    FROM dates
    WHERE date = dd_date AT TIME ZONE 'UTC';
    IF dd_date_id IS NULL THEN
        INSERT INTO dates (date) VALUES (dd_date) RETURNING id INTO dd_date_id;
    END IF;

    /*  RetailerService.getRetailerByName   */
    SELECT *
    INTO dd_retailer
    FROM retailers
    WHERE name = dd_source_type;

    IF dd_retailer IS NULL THEN
        INSERT INTO retailers (name, "countryId") VALUES (dd_source_type, 'GB') RETURNING * INTO dd_retailer;
    END IF;

    /*  create the new categories   */
    WITH product_categ AS (SELECT DISTINCT category              AS name,
                                           dd_sourceCategoryType AS type
                           FROM staging.tmp_product)
    INSERT
    INTO "sourceCategories"(name, type, "createdAt", "updatedAt")
    SELECT name, type, NOW(), NOW()
    FROM product_categ
             LEFT OUTER JOIN "sourceCategories"
                             USING (name, type)
    WHERE "sourceCategories".id IS NULL;

    DROP TABLE IF EXISTS staging.tmp_product;
    CREATE TABLE staging.tmp_product AS
    WITH prod_categ AS (SELECT id AS "sourceCategoryId", name AS category
                        FROM "sourceCategories"
                        WHERE type = dd_sourceCategoryType),
         prod_brand AS (SELECT id AS "brandId", name AS "productBrand" FROM brands)
    SELECT NULL                                             AS id,
           COALESCE(ARRAY_LENGTH(promotions, 1) > 0, FALSE) AS promotions,
           COALESCE(promotions[0].description, '')          AS "promotionDescription",
           "originalPrice"                                  AS "basePrice",
           "originalPrice"                                  AS "shelfPrice",
           "originalPrice"                                  AS "promotedPrice",
           dd_retailer.id                                   AS "retailerId",
           dd_date_id                                       AS "dateId",
           NOT (NOT featured)                               AS featured,
           "bundled",
           "category",
           "categoryType",
           "date",
           "ean",
           "eposId",
           --"featured",
           "featuredRank",
           "features",
           "href",
           "inTaxonomy",
           "isFeatured",
           "multibuy",
           "nutritional",
           "pageNumber",
           "pricePerWeight",
           "productBrand",
           "productDescription",
           "productImage",
           "productInStock",
           "productInfo",
           "productRank",
           "productTitle",
           "productTitleDetail",
           --"promotions",
           "reviewsCount",
           "reviewsStars",
           "screenshot",
           "secondaryImages",
           "size",
           "sizeUnit",
           "sourceId",
           "sourceType",
           "taxonomyId",
           "sourceCategoryId",
           "brandId",
           "productOptions",
           checkEAN.re_matches IS NULL                      AS "eanIssues",
           shop,
           "amazonShop",
           choice,
           "amazonChoice",
           "lowStock",
           "sellParty",
           "amazonSellParty",
           "amazonSell",
           sell,
           "fulfilParty",
           "amazonFulfilParty",
           ROW_NUMBER() OVER (PARTITION BY ean)             AS rownum
    /*
    TO DO
        if (
          product.sourceType === 'waitrose' &&
          !CompareUtil.checkEAN(product.ean)
        ) {
          const waitroseEAN = await ProductService.fetchWaitroseProductEAN(
            product.sourceId,
          );
          if (waitroseEAN) product.ean = waitroseEAN;
        }

    */
    FROM staging.tmp_daily_data
             INNER JOIN prod_categ USING (category)
             LEFT OUTER JOIN prod_brand USING ("productBrand")
        /*  CompareUtil.checkEAN    */
             LEFT OUTER JOIN LATERAL (SELECT (REGEXP_MATCHES(ean,
                                                             '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$|\S+_[\d\-_]+$', -- strict === true then '^M?([0-9]{13}|[0-9]{8})(,([0-9]{13}|[0-9]{8}))*S?$'
                                                             'g')) AS re_matches) AS checkEAN ON (TRUE);

    /*  create the new coreProduct   */
    /*
    TO DO:
        const img = product.image;
        product.image = await AWSUtil.uploadImage({
          bucket: 'coreImages',
          key: product.ean,

          link: img,
        });
    */

    /*  findCreateProductCore

        - creates a coreProduct and coreProductBarcode if missing, otherwise
        - updates disabled=true in coreProduct

        logic on selecting coreProductId relating to coreProductBarcode, coreRetailer....
    */
    /*  createCoreBy    */
    DROP TABLE IF EXISTS staging.tmp_coreProducts;
    CREATE TABLE staging.tmp_coreProducts AS
    WITH coreProductData AS (SELECT ean,
                                    "productTitle"                    AS title,
                                    "productImage"                    AS image,
                                    "brandId",
                                    bundled,
                                    "secondaryImages",
                                    "productDescription"              AS description,
                                    features,
                                    "productInfo"                     AS ingredients,
                                    size,
                                    nutritional                       AS specification,
                                    COALESCE("productOptions", FALSE) AS "productOptions",
                                    "eanIssues" --!CompareUtil.checkEAN(product.ean)
                             FROM staging.tmp_product
                             WHERE rownum = 1),
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
                                      "productOptions")
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
                            "productOptions"
                     FROM coreProductData
                     ON CONFLICT (ean) DO UPDATE
                         SET disabled = FALSE,
                             "productOptions" = excluded."productOptions"
                     RETURNING *)
    SELECT *
    FROM ins_coreProducts;

    INSERT
    INTO "coreProductBarcodes" ("coreProductId", barcode, "createdAt", "updatedAt")
    SELECT id, ean, NOW(), NOW()
    FROM staging.tmp_coreProducts
    ON CONFLICT (barcode) DO NOTHING;


    /*  createProductCountryData    */
    INSERT INTO "coreProductCountryData" ("coreProductId",
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
                                          reviewed)
    SELECT id AS "coreProductId",
           dd_retailer."countryId",
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
           reviewed
    --"ownLabelManufacturerId",
--"brandbankManaged"
    FROM staging.tmp_coreProducts
    ON CONFLICT ("coreProductId", "countryId") DO NOTHING;

    /*  createProductBy    */


    --RAISE NOTICE 'dd_sourceCategoryType : %', dd_sourceCategoryType;

    RETURN;
END ;

$$;
/*
ALTER TABLE staging.retailer_data
    ADD "productOptions" boolean DEFAULT FALSE;

CREATE INDEX products_sourceId_dateId_retailerId_index
    ON products ("sourceId", "dateId", "retailerId");

 */

/*  remove coreProductCountryData duplicate records and add UQ constraint on "coreProductId", "countryId" */
CREATE TABLE staging.fix_dup_coreProductCountryData_deleted_rec AS
WITH coreProductCountryData_ext AS (SELECT *,
                                           ROW_NUMBER()
                                           OVER (PARTITION BY "coreProductId", "countryId" ORDER BY "createdAt" ASC ) AS rownum
                                    FROM "coreProductCountryData"),
     deleted AS (
         DELETE
             FROM "coreProductCountryData"
                 USING coreProductCountryData_ext
                 WHERE "coreProductCountryData".id = coreProductCountryData_ext.id AND rownum > 1
                 RETURNING "coreProductCountryData".*)
SELECT *
FROM deleted;

ALTER TABLE "coreProductCountryData"
    ADD CONSTRAINT coreProductCountryData_pk
        UNIQUE ("coreProductId", "countryId");

/*  remove products duplicate records and add UQ constraint on  "sourceId", "retailerId", "dateId"
TO DO:
CREATE TABLE staging.fix_dup_products_deleted_rec AS
WITH products_ext AS (SELECT *,
                             ROW_NUMBER()
                             OVER (PARTITION BY "sourceId", "retailerId", "dateId" ORDER BY "createdAt" ASC ) AS rownum
                      FROM products),
     deleted AS (
         DELETE
             FROM products
                 USING products_ext
                 WHERE products.id = products_ext.id AND rownum > 1
                 RETURNING products.*)
SELECT *
FROM deleted;

ALTER TABLE products
ADD CONSTRAINT products_pk
    UNIQUE ("sourceId", "retailerId", "dateId");

*/

SELECT MAX(id)
FROM dates;
/*  temporary solution for fix_dup_products_deleted_rec */
CREATE UNIQUE INDEX products_sourceId_retailerId_dateId_key
    ON products ("sourceId", "retailerId", "dateId")
    WHERE "createdAt" >= '2024-02-29';-- WHERE  "dateId">18166;


SELECT staging.load_retailer_data(fetched_data)
FROM staging.retailer_daily_data;

SELECT *
FROM staging.tmp_coreProducts;


WITH ins_products AS (
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
                          "dateId")
        SELECT "sourceType",
               ean,
               promotions,
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
               NOW() AS "createdAt",
               NOW() AS "updatedAt",
               -- "imageId",
               size,
               "pricePerWeight",
               href,
               nutritional,
               "basePrice",
               "shelfPrice",
               "productTitleDetail",
               "sizeUnit",
               "dateId"
        FROM staging.tmp_product
                 INNER JOIN (SELECT ean,
                                    id AS "coreProductId"
                             FROM staging.tmp_coreproducts) AS core_product USING (ean)
                 CROSS JOIN LATERAL (SELECT CASE
                                                WHEN "sourceType" = 'sainsburys' THEN
                                                    REPLACE(
                                                            REPLACE(
                                                                    'https://www.sainsburys.co.uk' || "productImage",
                                                                    'https://www.sainsburys.co.ukhttps://www.sainsburys.co.uk',
                                                                    'https://www.sainsburys.co.uk'),
                                                            'https://www.sainsburys.co.ukhttps://assets.sainsburys-groceries.co.uk',
                                                            'https://assets.sainsburys-groceries.co.uk')
                                                WHEN "sourceType" = 'ocado' THEN REPLACE(
                                                        'https://www.ocado.com' || "productImage",
                                                        'https://www.ocado.comhttps://ocado.com',
                                                        'https://www.ocado.com')
                                                WHEN "sourceType" = 'morrisons' THEN
                                                    'https://groceries.morrisons.com' || "productImage"
                                                END AS "productImage"

            ) AS new_img
        ON CONFLICT ("sourceId", "retailerId", "dateId")
            WHERE "createdAt" >= '2024-02-29'
            DO UPDATE
                SET "updatedAt" = NOW()
        RETURNING products.*)
UPDATE staging.tmp_product
SET id=ins_products.id
FROM ins_products
WHERE tmp_product."sourceId" = ins_products."sourceId"
  AND tmp_product."retailerId" = ins_products."retailerId"
  AND tmp_product."dateId" = ins_products."dateId";


WITH prod AS (SELECT "sourceType",
                     ean,
                     promotions,
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
                     NOW() AS "createdAt",
                     NOW() AS "updatedAt",
                     -- "imageId",
                     size,
                     "pricePerWeight",
                     href,
                     nutritional,
                     "basePrice",
                     "shelfPrice",
                     "productTitleDetail",
                     "sizeUnit",
                     "dateId"
              FROM staging.tmp_product
                       INNER JOIN (SELECT ean,
                                          id AS "coreProductId"
                                   FROM staging.tmp_coreproducts) AS core_product USING (ean)
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
                                                      WHEN "sourceType" = 'ocado' THEN REPLACE(
                                                              'https://www.ocado.com' || "productImage",
                                                              'https://www.ocado.comhttps://ocado.com',
                                                              'https://www.ocado.com')
                                                      WHEN "sourceType" = 'morrisons' THEN
                                                          'https://groceries.morrisons.com' || "productImage"
                                                      END AS "productImage"

                  ) AS new_img)
SELECT "sourceId",-- "retailerId", "dateId",
       COUNT(*)
FROM staging.tmp_daily_data
GROUP BY 1--, 2, 3
HAVING COUNT(*) > 1