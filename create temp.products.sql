/*
CREATE TYPE temp."productsData" AS
(
    category           varchar(255),
    "categoryType"     varchar(255),
    "parentCategory"   varchar(255),
    "productRank"      integer,
    "pageNumber"       varchar(255),
    screenshot         varchar(255),
    "sourceCategoryId" integer,
    featured           boolean,
    "featuredRank"     integer,
    "taxonomyId"       integer
);
CREATE TYPE temp."productStatuses" AS
(
    status      varchar(255),
    screenshot  varchar(255),
    "createdAt" timestamp WITH TIME ZONE
);
 */
SET work_mem TO '2GB'; --5463728KB
SHOW WORK_MEM;

CREATE TABLE temp.products_base AS
SELECT id                                           AS "productId",
       "sourceType",
       ean,
       promotions,
       date,
       "sourceId",
       "productBrand",
       "productTitle",
       REPLACE("promotedPrice", 'Nan', NULL)::money AS "promotedPrice",
       "productInStock",
       "productInListing",
       "reviewsCount"::integer,
       "reviewsStars"::double precision,
       "eposId",
       multibuy,
       "coreProductId",
       "retailerId",
       "createdAt",
       "updatedAt",
       REPLACE("basePrice", 'Nan', NULL)::money     AS "basePrice",
       REPLACE("shelfPrice", 'Nan', NULL)::money    AS "shelfPrice"
FROM products;

CREATE TABLE temp."t_productsData" AS
SELECT "productId", ARRAY_AGG(pd:: temp."productsData") AS "productsData"
FROM public."productsData"
         CROSS JOIN LATERAL (SELECT category,
                                    "categoryType",
                                    "parentCategory",
                                    "productRank",
                                    "pageNumber",
                                    screenshot,
                                    "sourceCategoryId",
                                    featured,
                                    "featuredRank",
                                    "taxonomyId") pd
GROUP BY "productId";

CREATE TABLE temp."t_productStatuses" AS
SELECT "productId",
       ARRAY_AGG(ps::temp."productStatuses" ORDER BY ps."createdAt" ASC) AS "productStatuses"
FROM public."productStatuses"
         CROSS JOIN LATERAL (SELECT status,
                                    screenshot,
                                    "createdAt") AS ps
GROUP BY "productId";

CREATE TABLE temp.products AS
SELECT *
FROM temp.products_base
         LEFT OUTER JOIN temp."t_productsData" USING ("productId")
         LEFT OUTER JOIN temp."t_productStatuses" USING ("productId");

VACUUM FULL;

SELECT COUNT(*)
FROM public."productStatuses"; --   146.696.755
SELECT COUNT(*)
FROM public."productsData";--       335.937.414

SELECT *
FROM temp.products
LIMIT 10;

SELECT PG_TERMINATE_BACKEND(3090);

TRUNCATE temp.products_base;
TRUNCATE temp."t_productsData";
TRUNCATE temp."t_productStatuses";

CREATE TABLE temp.products AS
WITH products AS (SELECT id                                           AS "productId",
                         "sourceType",
                         ean,
                         promotions,
                         date,
                         "sourceId",
                         "productBrand",
                         "productTitle",
                         REPLACE("promotedPrice", 'Nan', NULL)::money AS "promotedPrice",
                         "productInStock",
                         "productInListing",
                         "reviewsCount"::integer,
                         "reviewsStars"::double precision,
                         "eposId",
                         multibuy,
                         "coreProductId",
                         "retailerId",
                         "createdAt",
                         "updatedAt",
                         REPLACE("basePrice", 'Nan', NULL)::money     AS "basePrice",
                         REPLACE("shelfPrice", 'Nan', NULL)::money    AS "shelfPrice"
                  FROM products),
     pd AS (SELECT "productId", ARRAY_AGG(pd:: temp."productsData") AS "productsData"
            FROM "productsData"
                     CROSS JOIN LATERAL (SELECT category,
                                                "categoryType",
                                                "parentCategory",
                                                "productRank",
                                                "pageNumber",
                                                screenshot,
                                                "sourceCategoryId",
                                                featured,
                                                "featuredRank",
                                                "taxonomyId") pd
            GROUP BY "productId"),
     ps AS (SELECT "productId",
                   ARRAY_AGG(ps::temp."productStatuses" ORDER BY ps."createdAt" ASC) AS "productStatuses"
            FROM "productStatuses"
                     CROSS JOIN LATERAL (SELECT status,
                                                screenshot,
                                                "createdAt") AS ps
            GROUP BY "productId")
SELECT *
FROM products
         LEFT OUTER JOIN pd USING ("productId")
         LEFT OUTER JOIN ps USING ("productId");


SELECT "productId" --0
FROM "productStatuses"
         CROSS JOIN LATERAL (SELECT status,
                                    screenshot,
                                    "createdAt") AS ps
GROUP BY "productId"
HAVING count(*) >1