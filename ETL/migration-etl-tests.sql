/*
TRUNCATE staging.retailer_daily_data;
TRUNCATE staging.debug_errors;
TRUNCATE staging.debug_test_run;

SELECT staging.load_retailer_data(fetched_data, flag)
FROM staging.debug_errors
where id=1

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
CREATE TABLE test.retailer AS
SELECT (dd_retailer).id                                       AS "retailerId",
       STRING_AGG(DISTINCT flag, ', ')                        AS flag,
       STRING_AGG(DISTINCT flag, ', ') = 'create-products-pp' AS is_pp
FROM staging.debug_test_run
GROUP BY 1;


*/
/*
SELECT COUNT(*) AS product_count
FROM staging.debug_products;

SELECT test_run_id, COUNT(*)
FROM staging.debug_products
GROUP BY test_run_id
ORDER BY test_run_id DESC;

SELECT *
FROM dates
WHERE id >= 27670
ORDER BY "createdAt" DESC NULLS LAST;

SELECT *
FROM prod_fdw.dates
WHERE id >=27670
ORDER BY "createdAt" DESC NULLS LAST;

SELECT COUNT(*)
FROM products
WHERE "dateId" > 25096;

SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" > 25096;

*/


/*
SELECT debug_test_run_id,
       flag,
       CASE
           WHEN flag = 'create-products-pp' THEN
               fetched_data #>> '{retailer}'
           ELSE fetched_data #>> '{0,sourceType}' END AS dd_retailer,
       CASE
           WHEN flag = 'create-products-pp' THEN
               fetched_data #>> '{products,0,date}'
           ELSE fetched_data #>> '{0,date}' END       AS dd_date,
       created_at
FROM staging.retailer_daily_data
ORDER BY created_at DESC;
 */
SET WORK_MEM = '2GB';
WITH prod_cnt AS (SELECT load_id AS id, "retailerId", "sourceType", COUNT(*) AS product_count
                  FROM staging.debug_products
                  GROUP BY load_id, "retailerId", "sourceType")
SELECT run_at::date,
       COUNT(*)                          AS run_count,
       SUM(product_count)                AS product_count,
       SUM(execution_time) / (1000 * 60) AS execution_time
FROM staging.load
         INNER JOIN prod_cnt USING (id)
GROUP BY 1
ORDER BY 1 DESC;

SELECT id AS load_id,
       --  fetched_data,

       flag,
--
       run_at,
       execution_time,
       dd_date
FROM staging.load;

WITH prod_cnt AS (SELECT load_id AS id, "retailerId", "sourceType", COUNT(*) AS product_count
                  FROM staging.debug_products
                  GROUP BY load_id, "retailerId", "sourceType")
SELECT id           AS load_id,
       --  fetched_data,
       "retailerId",
       "sourceType" AS retailer_name,
       product_count,
       flag,
--
       run_at,
       execution_time,
       dd_date
FROM staging.load
         LEFT OUTER JOIN prod_cnt USING (id)
ORDER BY id DESC;

WITH debug_errors AS (SELECT debug_errors.id AS error_id,
                             load_id,
                             sql_state,
                             debug_errors.message,
                             detail,
                             hint,
                             context,
                             --debug_errors.fetched_data,
                             debug_errors.flag,
                             debug_errors.created_at
                      FROM staging.debug_errors),
     load AS (SELECT id     AS load_id,
                     -- data,
                     flag,
                     run_at AS created_at,
                     dd_date,
                     dd_retailer,
                     dd_date_id,
                     dd_source_type
              FROM staging.load)
SELECT *
FROM debug_errors
         LEFT OUTER JOIN load
                         USING (load_id)
ORDER BY error_id;

SELECT id,
       load_id,
       sql_state,
       message,
       detail,
       hint,
       context,
       --fetched_data,
       flag,
       created_at,
       ROUND(LENGTH(fetched_data::text) / 1024 / 1024 ::numeric, 2) AS "Payload size (in MB)",
       JSON_ARRAY_LENGTH(fetched_data #> '{products}')              AS product_count,
       fetched_data #> '{retailer, name}'                           AS retailer,
       flag
FROM staging.debug_errors;

SELECT id,
       --data,
       flag,
       run_at,
       dd_date,
       dd_retailer,
       dd_date_id,
       dd_source_type,
       execution_time,
       ROUND(LENGTH(data::text) / 1024 / 1024 ::numeric, 2) AS "Payload size (in MB)",
       JSON_ARRAY_LENGTH(data #> '{products}')              AS product_count,
       data #> '{retailer, name}'                           AS retailer
FROM staging.load;

/*
WITH load AS (SELECT id     AS debug_test_run_id,
                     data,
                     flag,
                     run_at AS created_at,
                     dd_date,
                     dd_retailer,
                     dd_date_id,
                     dd_source_type,
                     dd_sourcecategorytype
              FROM staging.debug_test_run
              WHERE id = 92)
SELECT key, COUNT(*)
FROM load
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(data #> '{products}') AS product
         CROSS JOIN LATERAL JSON_OBJECT_KEYS(product) AS key
GROUP BY 1;
*/
/*
null value in column "retailerPromotionId" violates not-null constraint
{"id":1337,"name":"target_us","countryId":1,"updatedAt":"2024-08-17T15:39:36.133Z","createdAt":"2024-08-17T15:39:36.133Z"}

truncate staging.debug_errors

SELECT *
FROM "retailerPromotions"
WHERE "retailerId" = 1337

 */
SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

SELECT staging.load_retailer_data(fetched_data, flag)
FROM staging.debug_errors
WHERE id = 100;
/*
load id for error 100 = 216
[2024-11-19 20:14:29] 1 row retrieved starting from 1 in 1 h 35 m 4 s 49 ms (execution: 1 h 35 m 3 s 805 ms, fetching: 244 ms)
*/
--133,134, tesco: 100, 201
-- '209','210' FROM staging.load TO BE RELOADED JUST IN CASE!!

SELECT staging.load_retailer_data(data, flag)
FROM staging.load
WHERE id = 299;

DELETE
FROM staging.debug_errors
WHERE id NOT IN (100, 201);

SELECT *
FROM staging.debug_errors
WHERE id = 7;


SELECT *
FROM staging.load
WHERE id IN (1300, 1298);


SELECT *
FROM pg_stat_activity
WHERE datname = 'brandnudge-dev'
  AND state != 'idle';


SELECT *
FROM products
WHERE load_id = 67;

SELECT *
FROM staging.debug_tmp_product_pp
WHERE load_id = 301

SELECT data -> 'retailer', data #> '{products,0,sourceType}'
FROM staging.load
WHERE id = 303;