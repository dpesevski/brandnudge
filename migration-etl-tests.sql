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


