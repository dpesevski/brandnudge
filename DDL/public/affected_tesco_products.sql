CREATE MATERIALIZED VIEW AFFECTED_TESCO_PRODUCTS AS
SELECT products.id,
       products."sourceId",
       products."promotionDescription",
       products.ean,
       products.date,
       products."retailerId",
       products."sourceType",
       products."coreProductId",
       products."basePrice",
       products."shelfPrice",
       products."promotedPrice",
       products.href
FROM products
WHERE products.date::date >= '2024-11-21'::date
  AND products."promotionDescription" ~~* '%1/3 club%'::text
  AND products."retailerId" = 1;

ALTER MATERIALIZED VIEW AFFECTED_TESCO_PRODUCTS OWNER TO POSTGRES;

GRANT SELECT ON AFFECTED_TESCO_PRODUCTS TO BN_RO;

GRANT SELECT ON AFFECTED_TESCO_PRODUCTS TO DEJAN_USER;

