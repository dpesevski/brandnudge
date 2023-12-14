WITH q AS (SELECT queryid,
                  query,
                  calls,
                  total_time,
                  min_time,
                  max_time,
                  mean_time,
                  rows
           FROM pg_stat_statements
           WHERE dbid = 16400
             AND userid = 16399
           ORDER BY total_time DESC)
SELECT *
FROM q;


INSERT INTO "productsData" ("id", "productId", "category", "categoryType", "parentCategory", "featured", "featuredRank",
                            "productRank", "pageNumber", "screenshot", "sourceCategoryId", "taxonomyId")
VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING *;

INSERT INTO "products" ("id", "date", "sourceType", "ean", "sourceId", "productBrand", "productTitle",
                        "productTitleDetail", "productImage", "productDescription", "productInfo", "basePrice",
                        "shelfPrice", "promotedPrice", "productInStock", "reviewsCount", "reviewsStars", "promotions",
                        "promotionDescription", "secondaryImages", "eposId", "multibuy", "features", "size", "sizeUnit",
                        "pricePerWeight", "nutritional", "href", "createdAt", "updatedAt", "coreProductId", "dateId",
                        "retailerId")
VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22,
        $23, $24, $25, $26, $27, $28, $29, $30, $31, $32)
RETURNING *;
INSERT INTO "products" ("id", "date", "sourceType", "ean", "sourceId", "productBrand", "productTitle",
                        "productTitleDetail", "productImage", "productDescription", "productInfo", "basePrice",
                        "shelfPrice", "promotedPrice", "productInStock", "promotions", "promotionDescription",
                        "secondaryImages", "multibuy", "features", "size", "nutritional", "href", "createdAt",
                        "updatedAt", "coreProductId", "dateId", "retailerId")
VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22,
        $23, $24, $25, $26, $27)
RETURNING *;
INSERT INTO "aggregatedProducts" ("id", "titleMatch", "features", "specification", "size", "description", "ingredients",
                                  "createdAt", "updatedAt", "productId")
VALUES (DEFAULT, $1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;
INSERT INTO "productStatuses" ("id", "productId", "status", "screenshot", "createdAt", "updatedAt")
VALUES (DEFAULT, $1, $2, $3, $4, $5)
RETURNING *;

SELECT "reviewsCount"
FROM products AS P1
         INNER JOIN dates AS D1 ON P1."dateId" = D1.id
WHERE "sourceType" = $1
  AND "sourceId" = $2
  AND DATE_TRUNC($3, D1."date") = $4::date;

SELECT "id", "name", "type", "createdAt", "updatedAt"
FROM "sourceCategories" AS "sourceCategory"
WHERE "sourceCategory"."name" = $1
  AND "sourceCategory"."type" = $2
LIMIT $3;

UPDATE "products"
SET "shelfPrice"=$1,
    "promotedPrice"=$2,
    "updatedAt"=$3
WHERE "id" = $4;

UPDATE "products"
SET "promotedPrice"=$1,
    "updatedAt"=$2
WHERE "id" = $3;

UPDATE "coreProducts"
SET "categoryId"=$1,
    "updatedAt"=$2
WHERE "id" = $3