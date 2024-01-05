DROP TYPE IF EXISTS product_pricing CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP FUNCTION IF EXISTS f_period_array();


CREATE TYPE public.product_pricing AS
(
    period          daterange,
    "shelfPrice"    text,
    "basePrice"     text,
    "promotedPrice" text
);

CREATE TABLE product
(
    id      serial,
    pricing product_pricing[]
);



INSERT INTO product(pricing)
WITH dates AS (SELECT i,
                      (timestamp '2023-01-01' +
                       RANDOM() * (timestamp '2024-01-01' - timestamp '2023-01-01'))::date AS date_since,
                      CEIL(RANDOM() * 10)                                                  AS days_till
               FROM GENERATE_SERIES(1, 50000) i)
SELECT ARRAY_AGG(
               (
                DATERANGE(
                        date_since,
                        (date_since + (days_till || ' day') ::interval)::date
                ),
                RANDOM() * 100, RANDOM() * 100, RANDOM() * 100
                   )::product_pricing)
FROM dates
GROUP BY i % 10000;


SELECT *
FROM product;
-- add exact value for below demo
INSERT INTO product(pricing)
SELECT ARRAY ['("[2023-09-23,2023-09-25)",73.29247941280128,60.64075257677048,63.962286330024654)'::product_pricing,
           '("[2023-09-26,2023-09-30)",98.3027859705514,76.50385670017594,21.92538273713689)'::product_pricing,
           '("[2023-09-30,2023-12-15)",73.02842004595296,85.4632785569263,39.42093448008026)'::product_pricing];
-- function to extract array of "r"
CREATE OR REPLACE FUNCTION f_r_array(product_pricing[])
    RETURNS daterange[]
    LANGUAGE sql
    IMMUTABLE STRICT PARALLEL SAFE
BEGIN
    ATOMIC
    SELECT ARRAY(SELECT (UNNEST($1)).period);
END;

-- expression idx based on above function
CREATE INDEX product_co_r_idx ON product USING GIN (f_r_array(pricing));
VACUUM ANALYZE product;
SELECT *
FROM product
WHERE f_r_array(pricing) @> ARRAY ['[2023-09-30,2023-12-15)'::daterange];
-- matching value inserted above for demo
EXPLAIN ANALYZE
SELECT *
FROM product
WHERE f_r_array(pricing) @> ARRAY ['[2023-09-30,2023-12-15)'::daterange];

/*

WITH data AS (SELECT ARRAY ['("[2023-09-23,2023-09-25)",73.29247941280128,60.64075257677048,63.962286330024654)'::product_pricing,
                         '("[2023-09-26,2023-09-30)",98.3027859705514,76.50385670017594,21.92538273713689)'::product_pricing,
                         '("[2023-09-30,2023-12-15)",73.02842004595296,85.4632785569263,39.42093448008026)'::product_pricing] AS pricings)
SELECT ARRAY_AGG(Dates."Date"::date)
FROM data
         CROSS JOIN LATERAL UNNEST(pricings) AS pricing
         CROSS JOIN LATERAL GENERATE_SERIES(LOWER(pricing.period), UPPER(pricing.period), '1 DAY') Dates ("Date");

CREATE OR REPLACE FUNCTION f_period_array(product_pricing[])
    RETURNS date[]
    LANGUAGE sql
    IMMUTABLE STRICT PARALLEL SAFE
BEGIN
    ATOMIC
    SELECT ARRAY_AGG(Dates."Date"::date)
    FROM UNNEST($1) AS pricing
             CROSS JOIN LATERAL GENERATE_SERIES(LOWER(pricing.period), UPPER(pricing.period) - '1 DAY'::interval,
                                                '1 DAY') Dates("Date");
END;

-- expression idx based on above function
CREATE INDEX product_pricing_period_idx ON product USING GIN (f_period_array(pricing));


SELECT *
FROM product
WHERE f_period_array(pricing) @> '{2023-09-24}'::date[];

EXPLAIN ANALYZE
SELECT *
FROM product
WHERE f_period_array(pricing) @> '{2023-09-24}'::date[];


 */


CREATE OR REPLACE FUNCTION f_period_array(product_pricing[])
    RETURNS date[]
    LANGUAGE sql
    IMMUTABLE STRICT PARALLEL SAFE
AS
$$
SELECT ARRAY_AGG(Dates."Date"::date)
FROM UNNEST($1) AS el
         CROSS JOIN LATERAL GENERATE_SERIES(LOWER(el.period), UPPER(el.period) - '1 DAY'::interval,
                                            '1 DAY') Dates("Date");
$$;

CREATE INDEX product_pricing_period_idx ON product USING GIN (f_period_array(pricing));

