DROP TABLE IF EXISTS staging.retailer_daily_data_all;
CREATE TABLE staging.retailer_daily_data_all AS
SELECT JSON_AGG(fetched_data) AS fetched_data
FROM staging.retailer_daily_data
         CROSS JOIN LATERAL GENERATE_SERIES(1, 10) AS ret_id;


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

    PERFORM staging.load_retailer_data(ratailer_data::jsonb)
    FROM JSON_ARRAY_ELEMENTS(value) AS ratailer_data;

    RETURN;
END ;
$$;

SELECT staging.load_retailer_data_all(fetched_data)
FROM staging.retailer_daily_data_all;

SELECT fetched_data #>'{products,0,sourceId}'
FROM staging.retailer_daily_data;



SELECT (retailer_data::jsonb)#>'{products,0,sourceId}'
FROM staging.retailer_daily_data_all
         CROSS JOIN LATERAL JSON_ARRAY_ELEMENTS(fetched_data) AS retailer_data;
select  count(*) from staging.tmp_product
