DROP TYPE IF EXISTS staging.t_promotion_pp;
CREATE TYPE staging.t_promotion_pp AS
(
    promo_id          text,
    promo_type        text,
    promo_description text
);
DROP TYPE IF EXISTS staging.retailer_data_pp;
CREATE TYPE staging.retailer_data_pp AS
(
    DATE          DATE,
    retailer      TEXT,
    "countryCode" TEXT,
    "currency"    TEXT,

    "sourceId"    TEXT,


    ean           TEXT,

    "brand"       TEXT,
    "title"       TEXT,

    "shelfPrice"  TEXT,--double precision,
    "wasPrice"    TEXT,--double precision,
    "cardPrice"   TEXT,--double precision,
    "inStock"     TEXT,--boolean,
    "onPromo"     TEXT,--boolean,

    "promoData"   staging.t_promotion_pp[],

    "skuURL"      TEXT,
    "imageURL"    TEXT,


    "bundled"     TEXT,--boolean,
    "masterSku"   TEXT--boolean
);

SHOW WORK_MEM;
SET WORK_MEM = ' 2097151';


CREATE FUNCTION fn_to_float(value text) RETURNS double precision
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::float;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

CREATE FUNCTION fn_to_date(value text) RETURNS date
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;
CREATE FUNCTION fn_to_boolean(value text) RETURNS boolean
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::boolean;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

DROP TABLE staging.tests_pp_file;
CREATE TABLE staging.tests_pp_file AS
SELECT fetched_data ->> 'retailer'                       AS retailer,
       JSON_ARRAY_LENGTH(fetched_data -> 'products')     AS products_count,
       fetched_data #>> '{products,0,date}'              AS date,
       fetched_data ->> 'retailer' || '__' || created_at AS file_src,
       fetched_data,
       created_at
FROM staging.retailer_daily_data;


DROP TABLE IF EXISTS staging.tests_daily_data_pp;
CREATE TABLE staging.tests_daily_data_pp AS
SELECT file_src,
       product.date,
       product.retailer,
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
FROM staging.tests_pp_file
         CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                    fetched_data -> 'products') AS product;
--WHERE tests_pp_file.retailer = 'aldi'

