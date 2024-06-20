/*
TRUNCATE staging.retailer_daily_data;
TRUNCATE staging.debug_errors;
TRUNCATE staging.debug_test_run;

SELECT staging.load_retailer_data(fetched_data, flag)
--SELECT *
FROM staging.debug_errors



UPDATE products
SET "dateId"=24436
WHERE "dateId" > 24436;
UPDATE "coreRetailerDates"
SET "dateId"=24436
WHERE "dateId" > 24436;

UPDATE dates
SET "createdAt"=NOW(),
    "updatedAt"=NOW()
WHERE id = 24436;
DELETE
FROM dates
WHERE id > 24436;

UPDATE staging.debug_test_run
SET dd_date_id=24436
WHERE dd_date_id > 24436;
 */

-- 24436 2024-06-13T16:33:48.739Z
/*
CREATE TABLE test.retailer_flag AS
SELECT (dd_retailer).id                                       AS "retailerId",
       STRING_AGG(DISTINCT flag, ', ')                        AS flag,
       STRING_AGG(DISTINCT flag, ', ') = 'create-products-pp' AS is_pp
FROM staging.debug_test_run
GROUP BY 1;

CREATE TABLE test.retailer_flag
(
    "retailerId" integer,
    flag         text,
    is_pp        boolean
);

INSERT INTO test.retailer_flag ("retailerId", flag, is_pp)
VALUES (1, 'create-products', FALSE),
       (2, 'create-products', FALSE),
       (4, 'create-products-pp', TRUE),
       (48, 'create-products-pp', TRUE),
       (81, 'create-products-pp', TRUE),
       (114, 'create-products-pp', TRUE),
       (378, 'create-products-pp', TRUE),
       (411, 'create-products-pp', TRUE),
       (444, 'create-products-pp', TRUE),
       (477, 'create-products-pp', TRUE),
       (510, 'create-products-pp', TRUE),
       (543, 'create-products-pp', TRUE),
       (609, 'create-products-pp', TRUE),
       (642, 'create-products-pp', TRUE),
       (675, 'create-products-pp', TRUE),
       (741, 'create-products-pp', TRUE),
       (774, 'create-products-pp', TRUE),
       (775, 'create-products-pp', TRUE),
       (807, 'create-products-pp', TRUE),
       (840, 'create-products-pp', TRUE),
       (873, 'create-products-pp', TRUE),
       (906, 'create-products-pp', TRUE),
       (907, 'create-products-pp', TRUE),
       (908, 'create-products-pp', TRUE),
       (909, 'create-products-pp', TRUE),
       (910, 'create-products-pp', TRUE),
       (911, 'create-products-pp', TRUE),
       (912, 'create-products-pp', TRUE),
       (913, 'create-products-pp', TRUE),
       (914, 'create-products-pp', TRUE),
       (915, 'create-products-pp', TRUE),
       (916, 'create-products-pp', TRUE),
       (939, 'create-products-pp', TRUE),
       (972, 'create-products-pp', TRUE),
       (1005, 'create-products-pp', TRUE),
       (1006, 'create-products-pp', TRUE),
       (1007, 'create-products-pp', TRUE),
       (1008, 'create-products-pp', TRUE),
       (1009, 'create-products-pp', TRUE),
       (1010, 'create-products-pp', TRUE),
       (1011, 'create-products-pp', TRUE),
       (1012, 'create-products-pp', TRUE),
       (1013, 'create-products-pp', TRUE),
       (1038, 'create-products-pp', TRUE),
       (1071, 'create-products-pp', TRUE),
       (1072, 'create-products-pp', TRUE),
       (1104, 'create-products-pp', TRUE),
       (1137, 'create-products-pp', TRUE),
       (1170, 'create-products-pp', TRUE);
*/


SELECT *
FROM dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT *
FROM prod_fdw.dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT COUNT(*)
FROM products
WHERE "dateId" > 24436;

SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" > 24436;



WITH prod_cnt AS (SELECT test_run_id AS debug_test_run_id, COUNT(*) AS product_count
                  FROM staging.debug_products
                  GROUP BY test_run_id)
SELECT debug_test_run_id,
       --  fetched_data,
       product_count,
       flag,
       created_at
FROM staging.retailer_daily_data
         INNER JOIN prod_cnt USING (debug_test_run_id)
ORDER BY debug_test_run_id DESC;

SELECT COUNT(*) AS product_count
FROM staging.debug_products;



SELECT test_run_id, COUNT(*)
FROM staging.debug_products
GROUP BY test_run_id
ORDER BY test_run_id DESC;

WITH debug_errors AS (SELECT debug_errors.id AS error_id,
                             debug_test_run_id,
                             sql_state,
                             debug_errors.message,
                             detail,
                             hint,
                             context,
                             --debug_errors.fetched_data,
                             debug_errors.flag,
                             debug_errors.created_at
                      FROM staging.debug_errors),
     debug_test_run AS (SELECT id     AS debug_test_run_id,
                               -- data,
                               flag,
                               run_at AS created_at,
                               dd_date,
                               dd_retailer,
                               dd_date_id,
                               dd_source_type,
                               dd_sourcecategorytype
                        FROM staging.debug_test_run)
SELECT *
FROM debug_errors
         LEFT OUTER JOIN debug_test_run
                         USING (debug_test_run_id)
ORDER BY error_id;


