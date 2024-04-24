DROP TABLE IF EXISTS staging.retailer_daily_data_all;
CREATE TABLE staging.retailer_daily_data_all AS
SELECT JSON_AGG(fetched_data) AS fetched_data
FROM (SELECT *
      FROM staging.retailer_daily_data11
      LIMIT 1) AS retailer_daily_data
         CROSS JOIN LATERAL GENERATE_SERIES(1, 20) AS ret_id;


DROP TABLE staging.tmp_coreretailer;
DROP TABLE staging.tmp_product;
DROP TABLE staging.tmp_daily_data;

DROP FUNCTION IF EXISTS staging.load_retailer_data_all(json);
CREATE OR REPLACE FUNCTION staging.load_retailer_data_all(value json) RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    /*
    INSERT INTO staging.retailer_daily_data(fetched_data)
    SELECT JSON_ARRAY_ELEMENTS(value);
     */

    PERFORM staging.load_retailer_data(ratailer_data)
    FROM JSON_ARRAY_ELEMENTS(value) AS ratailer_data;

    RETURN;
END ;
$$;

SELECT staging.load_retailer_data_all(fetched_data)
FROM staging.retailer_daily_data_all;

SELECT COUNT(*)
FROM staging.tmp_product
