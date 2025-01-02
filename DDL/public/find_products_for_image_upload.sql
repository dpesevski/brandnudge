CREATE FUNCTION FIND_PRODUCTS_FOR_IMAGE_UPLOAD(product_json jsonb)
    RETURNS TABLE(sourceid text, ean text, imageurl text)
    LANGUAGE PLPGSQL
AS
$$
DECLARE
    v_retailer text;
    v_retailerId integer;
BEGIN
    -- Extract retailer once to avoid repeated lookups
    v_retailer := product_json->>'retailer';

    -- Retailer lookup: ID from name
    SELECT r."id"
    INTO v_retailerId  -- Assign retailerId to the variable
    FROM retailers r
    WHERE r."name" = v_retailer
    LIMIT 1;

    -- Create a temporary table for storing unnested products
    CREATE TEMP TABLE temp_products (
        product jsonb,
        retailerId integer
    ) ON COMMIT DROP;

    -- Insert unnested products into temp table
    INSERT INTO temp_products (product, retailerId)
    SELECT
        p.value AS product,
        v_retailerId AS retailerId
    FROM jsonb_array_elements(product_json->'products') AS p;

    -- Create an index on product's sourceId and ean for faster lookups
    CREATE INDEX idx_temp_products_sourceid ON temp_products ((product->>'sourceId'));
    CREATE INDEX idx_temp_products_ean ON temp_products ((product->>'ean'));

    RETURN QUERY
    WITH no_barcode_products AS (
        SELECT tp.product->>'sourceId' AS "sourceId",
               tp.product->>'ean' AS "ean",
               tp.product->>'imageURL' AS "imageURL"
        FROM temp_products tp
        LEFT JOIN public."coreProductBarcodes" cb
            ON tp.product->>'ean' = cb."barcode"
        WHERE cb."barcode" IS NULL ),
    no_core_products AS (
        SELECT np."ean", np."sourceId", np."imageURL" FROM no_barcode_products np
        LEFT JOIN public."coreProducts" cp
            ON np."ean" = cp."ean"
        WHERE cp."ean" IS NULL ),
    no_core_retailer_sources AS (
        SELECT ncp."sourceId", ncp."ean", ncp."imageURL"
        FROM no_core_products ncp LEFT JOIN public."coreRetailerSources" crs
        ON ncp."sourceId" = crs."sourceId" AND crs."retailerId" = v_retailerId
        WHERE crs."sourceId" IS NULL )    
    SELECT ncp."sourceId", ncp."ean", ncp."imageURL" FROM no_core_retailer_sources ncp;

END;
$$;

ALTER FUNCTION FIND_PRODUCTS_FOR_IMAGE_UPLOAD(JSONB) OWNER TO POSTGRES;

