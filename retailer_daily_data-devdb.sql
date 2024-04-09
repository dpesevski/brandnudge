CREATE SCHEMA staging;

DROP TABLE IF EXISTS staging.retailer_daily_data CASCADE;
CREATE TABLE IF NOT EXISTS staging.retailer_daily_data
(
    fetched_data json,
    flag         text,
    created_at   timestamptz DEFAULT NOW()
);
DROP FUNCTION IF EXISTS staging.load_retailer_data(json, text);
CREATE OR REPLACE FUNCTION staging.load_retailer_data(value json, flag text = NULL::text) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO staging.retailer_daily_data (fetched_data, flag)
    VALUES (value, flag);
    RETURN;
END;
$$;