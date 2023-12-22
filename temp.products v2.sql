SELECT *
FROM staging.products_base
         INNER JOIN staging."t_productsData" USING ("productId")
LIMIT 10000;


ALTER TABLE staging.products_base
    ADD "productsData" staging.t_productsData[];

ALTER TABLE staging.products_base
    ADD "productStatuses" staging."productStatuses"[];



UPDATE staging.products_base
SET "productsData"= upd."productsData"
FROM staging."t_productsData" upd
WHERE products_base."productId" = upd."productId";

SELECT PG_TERMINATE_BACKEND(5018);


DROP TABLE IF EXISTS staging.productsFull;
CREATE TABLE staging.products AS
SELECT *
FROM staging.products_base
         LEFT OUTER JOIN staging."t_productsData" USING ("productId")
         LEFT OUTER JOIN staging."t_productStatuses" USING ("productId");


SELECT DBLINK_CONNECT('test_conn', 'dbname=brandnudge-dev user=postgres password=fPQWtdGp2zMe4NNr');
SELECT DBLINK_EXEC('test_conn', 'SET work_mem TO ''2GB'';');
SELECT DBLINK_SEND_QUERY('test_conn', 'CREATE TABLE staging.products AS
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
     pd AS (SELECT "productId", ARRAY_AGG(pd:: staging.t_productsData) AS "productsData"
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
                   ARRAY_AGG(ps::staging."productStatuses" ORDER BY ps."createdAt" ASC) AS "productStatuses"
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