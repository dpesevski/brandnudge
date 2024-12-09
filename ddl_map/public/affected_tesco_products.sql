CREATE MATERIALIZED VIEW affected_tesco_products AS
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

ALTER MATERIALIZED VIEW affected_tesco_products OWNER TO postgres;

GRANT SELECT ON affected_tesco_products TO bn_ro;

GRANT SELECT ON affected_tesco_products TO dejan_user;

