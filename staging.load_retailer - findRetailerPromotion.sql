/*
     I - promotionMechanic defaults

        if (!promo) {
         [mechanic] = await db.promotionMechanic.findOrCreate({
          where: { name: defaultMechanic },
          defaults: { name: defaultMechanic },
        });

      ...

        const obj = {
          retailerId: retailerId,
          promotionMechanicId: mechanic.id,
        };
        [promo] = await db.retailerPromotion.findOrCreate({
          where: obj,
          defaults: obj,
        });

     findRetailerPromotion function (possibly) creates records in two tables:
     - promotionMechanic with a defaultMechanic, and
     - retailerPromotion with retailerId and promotionMechanicId

     promotionMechanics contains 3 records including current defaultMechanic ("Other").

     retailerPromotion records manage "regexp", and these are recorded outside the daily load job.
     The only record which may be inserted in the retailerPromotion at the daily load job would have defaultMechanic (Other) for the promotionMechanicId.

     In case new defaultMechanic is set, the same should be added in the promotionMechanics.
     Also, in table retailerPromotion a record should be added for each retailerId with the promotionMechanic = defaultMechanic.
     This is better approach then to have to check the existence of the default records and then handle it in the code at the every day within the daily load job.

     II - comparePromotionWithPreviousProduct

     The "comparePromotionWithPreviousProduct" function checks for prevProduct using product's dateId. Every call to load_retailer_data creates a new dateId, so prevProduct can only be another record from the products list in this call.
     The products list contains also data for the ranking, effectively duplicating the part for the public.product record for each of the ranking.
     The staging.tmp_product has field "rownum" where only 1st value (rownum=-1) is considered for updating the public.products table.
     Similarly, only promotions from this record will be used to update public.promotions.
     This leads to calling comparePromotionWithPreviousProduct only once, so there won't be any prevProduct to compare to, so effectively it can be avoided.

*/

DROP FUNCTION IF EXISTS staging.calculateMultibuyPrice(text, float);
CREATE OR REPLACE FUNCTION staging.calculateMultibuyPrice(description text, price float) RETURNS text
    LANGUAGE plv8
AS
$$
function textToNumber(str) {
  const numMap = {
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
  };

  return Object.keys(numMap).reduce(
    (res, text) => res.replace(new RegExp(text, 'gi'), numMap[text]),
    str,
  );
}

function numPrice(price) {
  if (!price) return 1;
  if (!isNaN(price)) return price;
  if (price.includes('£')) return parseFloat(price.split('£')[1]).toFixed(2);
  else if (price.includes('p'))
    return parseFloat(price.split('p')[0] / 100).toFixed(2);
  return price;
}
 if (!description || !price) return price;
    let result = price;
    const desc = textToNumber(description.replace(',', '').toLowerCase());

    const isFloat = n => Number(n) === n && n % 1 !== 0;

    const countAndPrice = desc.match(/£?(\d+(.\d{1,2})?|\d+\/\d+)p?/g);
    if (!countAndPrice || !countAndPrice.length) return price;

    const [count, discountPrice = '£1'] = countAndPrice;
    const dp = numPrice(discountPrice);
    let sum = price * count;

    // "3 for 2" match
    const forMatch = desc.match(/(\d+) for (\d+)/i);

    if (forMatch) {
      // eslint-disable-next-line no-unused-vars
      const [match, totalCount, forCount] = forMatch;
      sum = price * forCount;
      result = sum / totalCount;
    } else if (desc.includes('save')) {
      const isPercent = desc.includes('%');
      const halfPrice = desc.includes('half price');
      // eslint-disable-next-line no-nested-ternary
      const discount = isPercent ? (sum / 100) * dp : halfPrice ? sum / 2 : dp;
      result = (sum - discount) / count;
    } else if (desc.includes('price of')) {
      result = (price * dp) / count;
    } else if (desc.includes('free')) {
      const freeCount = dp > count ? 1 : +dp;
      result = sum / (+count + freeCount);
    } else if (desc.includes('half price')) {
      sum += (price / 2) * dp;
      result = sum / (+count + +dp);
    } else {
      result = Math.round((dp * 100.0) / count) / 100;
    }

    result = isFloat(result) ? result.toFixed(2) : result;

    return result.toString();
$$;

CREATE OR REPLACE FUNCTION multi_replace(value text, VARIADIC arr text[]) RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    e         text;
    find_text text;
BEGIN
    BEGIN
        FOREACH e IN ARRAY arr
            LOOP
                IF find_text IS NULL THEN
                    find_text := e;
                ELSE
                    value := REPLACE(value, find_text, e);
                    find_text := NULL;
                END IF;
            END LOOP;

        RETURN value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

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


                              COALESCE(ret_promo."retailerPromotionId",
                                       default_ret_promo."retailerPromotionId")       AS "retailerPromotionId",
                              COALESCE(ret_promo.regexp, default_ret_promo.regexp)    AS regexp,
                              COALESCE(ret_promo."promotionMechanicId",
                                       default_ret_promo."promotionMechanicId")       AS "promotionMechanicId",
                              COALESCE(
                                      ret_promo."promotionMechanicName",
                                      default_ret_promo."promotionMechanicName")      AS "promotionMechanicName",
                              ROW_NUMBER() OVER (PARTITION BY "sourceId", promo_indx) AS rownum
                       FROM staging.tmp_product AS product
                                CROSS JOIN LATERAL UNNEST(promotions) WITH ORDINALITY AS promo("promoId",
                                                                                               "retailerPromotionId",
                                                                                               "startDate",
                                                                                               "endDate",
                                                                                               description,
                                                                                               mechanic,
                                                                                               promo_indx)
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."startDate", product.date) AS "startDate",
                                                           COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."promoId",
                                                                    REPLACE("retailerId" || '_' || "sourceId" || '_' ||
                                                                            description || '_' ||
                                                                            lat_dates."startDate", ' ',
                                                                            '_')) AS "promoId") AS lat_promo_id
                                CROSS JOIN LATERAL (
                           SELECT LOWER(multi_replace(promo.description,
                                                      'one', '1', 'two', '2', 'three', '3', 'four', '4', 'five', '5',
                                                      'six', '6', 'seven', '7', 'eight', '8', 'nine', '9', 'ten', '10',
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
                                  ARRAY_AGG(("promoId",
                                             "retailerPromotionId",
                                             "startDate",
                                             "endDate",
                                             description,
                                             "promotionMechanicName")::staging.t_promotion
                                            ORDER BY promo_indx) AS promotions
/*
       "dateId",
       "coreProductId",
       "retailerId",
       "sourceId",
       regexp,
       "promotionMechanicId",
       "promotionMechanicName"
*/
                           FROM product_promo
                           WHERE rownum = 1 -- use only the first record, as "let promo = retailerPromotions.find()" would return only the first one
                           GROUP BY 1)
UPDATE staging.tmp_product
SET promotions=upd_product_promo.promotions
FROM staging.tmp_product AS all_products
         LEFT OUTER JOIN upd_product_promo
                         ON all_products."sourceId" = upd_product_promo."sourceId"
WHERE tmp_product."sourceId" = all_products."sourceId";

WITH product_promo AS (SELECT "retailerId",
                              "sourceId",
                              product.id         AS "productId",
                              product."dateId",
                              product."coreProductId",
                              lat_dates."startDate",
                              lat_dates."endDate",

                              lat_promo_id."promoId",
                              promo.description,
                              promo.mechanic,

                              textToNumber.value AS trsf_desc
                       FROM (SELECT tmp_product.*, tmp_coreproducts.id AS "coreProductId"
                             FROM staging.tmp_product
                                      INNER JOIN staging.tmp_coreproducts USING (ean)) AS product
                                CROSS JOIN LATERAL UNNEST(promotions) AS promo
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."startDate", product.date) AS "startDate",
                                                           COALESCE(promo."endDate", product.date)   AS "endDate") AS lat_dates
                                CROSS JOIN LATERAL (SELECT COALESCE(promo."promoId",
                                                                    REPLACE("retailerId" || '_' || "sourceId" || '_' ||
                                                                            description || '_' ||
                                                                            lat_dates."startDate", ' ',
                                                                            '_')) AS "promoId") AS lat_promo_id
                                CROSS JOIN LATERAL (
                           SELECT LOWER(multi_replace(promo.description,
                                                      'one', '1', 'two', '2', 'three', '3', 'four', '4', 'five', '5',
                                                      'six', '6', 'seven', '7', 'eight', '8', 'nine', '9', 'ten', '10',
                                                      ',', '')) AS value
                           ) AS textToNumber),
     promo AS (SELECT product_promo."retailerId",
                      product_promo."sourceId",
                      "productId",
                      "dateId",
                      "coreProductId",
                      product_promo."promoId",
                      product_promo."startDate",
                      product_promo."endDate",

                      product_promo.description,
                      product_promo.mechanic,

                      COALESCE(ret_promo."retailerPromotionId",
                               default_ret_promo."retailerPromotionId")    AS "retailerPromotionId",
                      COALESCE(ret_promo.regexp, default_ret_promo.regexp) AS regexp,
                      COALESCE(ret_promo."promotionMechanicId",
                               default_ret_promo."promotionMechanicId")    AS "promotionMechanicId",
                      COALESCE(
                              ret_promo."promotionMechanicName",
                              default_ret_promo."promotionMechanicName")   AS "promotionMechanicName",
                      ROW_NUMBER() OVER (PARTITION BY "sourceId")          AS rownum
               FROM product_promo
                        LEFT OUTER JOIN(SELECT id AS "retailerPromotionId",
                                               "retailerId",
                                               "promotionMechanicId",
                                               regexp,
                                               "promotionMechanicName"
                                        FROM "retailerPromotions"
                                                 INNER JOIN (SELECT id   AS "promotionMechanicId",
                                                                    name AS "promotionMechanicName"
                                                             FROM "promotionMechanics"
                                                             WHERE id = 3) AS "promotionMechanics"
                                                            USING ("promotionMechanicId")) AS default_ret_promo
                                       USING ("retailerId")
                        LEFT OUTER JOIN(SELECT id AS "retailerPromotionId",
                                               "retailerId",
                                               "promotionMechanicId",
                                               regexp,
                                               "promotionMechanicName"
                                        FROM "retailerPromotions"
                                                 INNER JOIN (SELECT id   AS "promotionMechanicId",
                                                                    name AS "promotionMechanicName"
                                                             FROM "promotionMechanics") AS "promotionMechanics"
                                                            USING ("promotionMechanicId")) AS ret_promo
                                       ON (product_promo."retailerId" = ret_promo."retailerId" AND
                                           CASE
                                               WHEN ret_promo."promotionMechanicId" IS NULL THEN FALSE
                                               WHEN LOWER(ret_promo."promotionMechanicName") =
                                                    COALESCE(product_promo.mechanic, '') THEN TRUE
                                               WHEN ret_promo.regexp IS NULL OR LENGTH(ret_promo.regexp) = 0
                                                   THEN FALSE
                                               WHEN ret_promo."promotionMechanicName" = 'Multibuy' AND
                                                    product_promo.trsf_desc ~ '(\d+\/\d+)'
                                                   THEN FALSE
                                               ELSE
                                                   product_promo.trsf_desc ~ ret_promo.regexp
                                               END
                                           )),
     ins_promo AS (
         INSERT
             INTO promotions ("retailerPromotionId",
                              "productId",
                              description,
                              "startDate",
                              "endDate",
                              "promoId",
                              "createdAt",
                              "updatedAt")
                 SELECT "retailerPromotionId",
                        "productId",
                        description,
                        "startDate",
                        "endDate",
                        "promoId",
                        NOW(),
                        NOW()
/*
       "dateId",
       "coreProductId",
       "retailerId",
       "sourceId",
       regexp,
       "promotionMechanicId",
       "promotionMechanicName"
*/
                 FROM promo
                 WHERE rownum = 1 -- use only the first record "let promo = retailerPromotions.find()"
                 ON CONFLICT ("productId")
                     WHERE "createdAt" >= '2024-02-29'
                     DO
                         UPDATE
                         SET "updatedAt" = NOW(),
                             "endDate" = excluded."endDate"
                 RETURNING *)
SELECT *
FROM ins_promo;

