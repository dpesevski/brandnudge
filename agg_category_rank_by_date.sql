--CREATE TABLE staging.agg_category_rank_by_date AS
SELECT "productsData".category,
       "productsData"."categoryType",
       "product"."retailerId",
       "product".date,
       MAX("productRank")  AS "productRankCount",
       MAX("featuredRank") AS "featuredRankCount"
FROM staging.products AS "product"
         INNER JOIN staging."productsData" AS "productsData" ON "product"."id" = "productsData"."productId"
GROUP BY "productsData".category, "productsData"."categoryType", "product"."retailerId", date;