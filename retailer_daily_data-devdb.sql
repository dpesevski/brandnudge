CREATE TABLE staging.retailer_daily_data
(
    fetched_data json,
    created_at   timestamp WITH TIME ZONE DEFAULT NOW()
);


CREATE FUNCTION load_retailer_data(value json) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO staging.retailer_daily_data (fetched_data)
    VALUES (value);
    RETURN;
END;
$$;
