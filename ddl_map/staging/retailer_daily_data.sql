CREATE TABLE staging.retailer_daily_data
(
    load_id      serial,
    fetched_data json,
    flag         text,
    created_at   timestamp with time zone DEFAULT NOW()
);

ALTER TABLE staging.retailer_daily_data
    OWNER TO postgres;

GRANT SELECT ON staging.retailer_daily_data TO bn_ro;

GRANT SELECT ON staging.retailer_daily_data TO dejan_user;

