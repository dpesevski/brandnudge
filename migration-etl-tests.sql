/*
TRUNCATE staging.retailer_daily_data;
TRUNCATE staging.debug_errors;
TRUNCATE staging.debug_test_run;
 */
DROP TABLE IF EXISTS staging_bck.tests_daily_data_pp;
CREATE TABLE staging_bck.tests_daily_data_pp AS
SELECT debug_test_run_id,
       product.date,
       retailer,
       product."countryCode",
       product."currency",
       product."sourceId",
       product.ean,
       product."brand",
       product."title",
       fn_to_float(product."shelfPrice")  AS "shelfPrice",
       fn_to_float(product."wasPrice")    AS "wasPrice",
       fn_to_float(product."cardPrice")   AS "cardPrice",
       fn_to_boolean(product."inStock")   AS "inStock",
       fn_to_boolean(product."onPromo")   AS "onPromo",
       product."promoData",
       product."skuURL",
       product."imageURL",
       fn_to_boolean(product."bundled")   AS "bundled",
       fn_to_boolean(product."masterSku") AS "masterSku"
FROM staging.retailer_daily_data
         CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                    fetched_data #> '{products}') AS product
WHERE flag = 'create-products-pp';

SELECT COUNT(*)
FROM staging_bck.tests_daily_data_pp;


SELECT staging.load_retailer_data(fetched_data, flag)
--SELECT *
FROM staging.debug_errors;

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

SELECT debug_test_run_id,
       --  fetched_data,
       flag,
       created_at
FROM staging.retailer_daily_data
ORDER BY debug_test_run_id DESC;



CREATE TABLE staging.sample_non_pp AS
SELECT fetched_data, *
FROM staging.debug_errors
WHERE id = 19;
