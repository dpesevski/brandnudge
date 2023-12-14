SELECT *
FROM temp.products_base
         INNER JOIN temp."t_productsData" USING ("productId")
LIMIT 10000;


ALTER TABLE temp.products_base
    ADD "productsData" temp."productsData"[];

ALTER TABLE temp.products_base
    ADD "productStatuses" temp."productStatuses"[];



UPDATE temp.products_base
SET "productsData"= upd."productsData"
FROM temp."t_productsData" upd
WHERE products_base."productId" = upd."productId";

SELECT PG_TERMINATE_BACKEND(5018);


DROP TABLE IF EXISTS temp.products;
CREATE TABLE temp.products AS
SELECT *
FROM temp.products_base
         LEFT OUTER JOIN temp."t_productsData" USING ("productId")
         LEFT OUTER JOIN temp."t_productStatuses" USING ("productId");


SELECT DBLINK_CONNECT('test_conn', 'dbname=brandnudge-dev user=postgres password=fPQWtdGp2zMe4NNr');
SELECT DBLINK_EXEC('test_conn', 'SET work_mem TO ''2GB'';');
SELECT DBLINK_SEND_QUERY('test_conn', 'CREATE TABLE temp.products AS
WITH products AS (SELECT id AS "productId",
                         "sourceType",
                         ean,
                         promotions,
                         date,
                         "sourceId",
                         "productBrand",
                         "productTitle",
                         "promotedPrice"::money,
                         "productInStock",
                         "productInListing",
                         "reviewsCount"::integer,
                         "reviewsStars"::numeric,
                         "eposId",
                         multibuy,
                         "coreProductId",
                         "retailerId",
                         "createdAt",
                         "updatedAt",
                         "basePrice"::money,
                         "shelfPrice"::money
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
         LEFT OUTER JOIN ps USING ("productId");');

select * from dblink_get_connections();
SELECT * from dblink_is_busy('test_conn');

SELECT * from dblink_get_result('test_conn');

SELECT * FROM dblink('test_conn', 'select proname, prosrc from pg_proc')  AS t1(proname name, prosrc text) WHERE proname LIKE 'bytea%';

SELECT *
FROM pg_stat_activity
WHERE pid = 644;

SELECT DBLINK_DISCONNECT('test_conn');