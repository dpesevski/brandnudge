CREATE MATERIALIZED VIEW RANKING_VIEW AS
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

ALTER MATERIALIZED VIEW RANKING_VIEW OWNER TO POSTGRES;

GRANT SELECT ON RANKING_VIEW TO BN_RO;

GRANT SELECT ON RANKING_VIEW TO DEJAN_USER;

