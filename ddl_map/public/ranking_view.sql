CREATE MATERIALIZED VIEW ranking_view AS
SELECT "productsData".category,
       "productsData"."categoryType",
       product."retailerId",
       product."dateId",
       MAX("productsData"."productRank")  AS "productRankCount",
       MAX("productsData"."featuredRank") AS "featuredRankCount"
FROM products product
         JOIN "productsData" "productsData" ON product.id = "productsData"."productId" AND
                                               ("productsData"."featuredRank" <= 20 OR "productsData"."productRank" <= 20)
GROUP BY "productsData".category, "productsData"."categoryType", product."retailerId", product."dateId";

ALTER MATERIALIZED VIEW ranking_view OWNER TO postgres;

GRANT SELECT ON ranking_view TO bn_ro;

GRANT SELECT ON ranking_view TO dejan_user;

