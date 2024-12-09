CREATE FUNCTION insert_products_ranking_data(product_json jsonb) RETURNS void
    LANGUAGE plpgsql
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
        retailer text,
        product jsonb,
		retailerId integer,
        date timestamptz
    ) ON COMMIT DROP;

    -- Insert unnested products into temp table
    INSERT INTO temp_products (product, retailerId, date)
    SELECT
        p.value AS product,
		v_retailerId as "retailerId",
        (product_json->>'date')::timestamptz AS "date"
    FROM jsonb_array_elements(product_json->'products') AS p;

    -- Create an index on product's sourceId for faster lookups
    CREATE INDEX idx_temp_products_sourceid ON temp_products ((product->>'sourceId'));

    -- Date lookup and processing
    WITH date_lookup AS (
        SELECT DISTINCT
            tp."date" AS "formattedDate"
        FROM temp_products tp
    ),

    existing_dates AS (
        SELECT 
            dl."formattedDate",
            d."id" AS "dateId"
        FROM date_lookup dl
        LEFT JOIN dates d
        ON d."date"::date = dl."formattedDate"::date
    ),

    inserted_dates AS (
        INSERT INTO dates ("date", "createdAt", "updatedAt")
        SELECT dl."formattedDate"::date, NOW()::timestamptz, NOW()::timestamptz
        FROM date_lookup dl
        LEFT JOIN dates d
        ON d."date"::date = dl."formattedDate"::date
        WHERE d."id" IS NULL
        RETURNING id, "date", "createdAt", "updatedAt"
    ),

    combined_dates AS (
        SELECT 
            "formattedDate",
            "dateId"
        FROM existing_dates
        UNION ALL
        SELECT 
            "date" AS "formattedDate",
            "id" AS "dateId"
        FROM inserted_dates
    ),

    -- Prepare products data
    products_data AS (
        SELECT 
            tp."product"->>'sourceId' AS "sourceId",
            COALESCE(tp."product"->>'category', '') AS "category",
            COALESCE(tp."product"->>'categoryType', '') AS "categoryType",
            COALESCE(tp."product"->>'parentCategory', '') AS "parentCategory",
            COALESCE((tp."product"->>'productRank')::int, 0) AS "productRank",
            tp."product"->>'pageNumber' AS "pageNumber",
            COALESCE(tp."product"->>'screenshot', '') AS "screenshot",
            COALESCE((tp."product"->>'featured')::boolean, false) AS "featured",
            COALESCE((tp."product"->>'featuredRank')::int, 0) AS "featuredRank",
            COALESCE(NULLIF(tp."product"->>'taxonomyId', '')::int, 0) AS "taxonomyId",
            v_retailerId AS "retailerId",
            cd."dateId"
        FROM temp_products tp
        JOIN combined_dates cd
        ON tp."date" = cd."formattedDate"
    ),

    -- Existing products lookup
    existing_products AS (
        SELECT 
            p.id AS "productId",
            pd."sourceId",
            pd."retailerId",
            d.id AS "dateId",
            pd."category",
			pd."taxonomyId",
			pd."categoryType"
        FROM products_data pd
        JOIN products p
        ON p."sourceId" = pd."sourceId"
        AND p."retailerId" = pd."retailerId"
        JOIN dates d
        ON d."date"::date = p."date"::date
        WHERE d.id = pd."dateId"
    ),

    -- Categorised products
    categorised_products AS (
        SELECT DISTINCT
            pd.*
        FROM products_data pd
    ),

    -- Filter out already existing products
    new_products_data AS (
        SELECT
            cp.*,
            ep."productId"
        FROM categorised_products cp
        INNER JOIN existing_products ep
			ON cp."sourceId" = ep."sourceId"
			AND cp."retailerId" = ep."retailerId"
			AND cp."dateId" = ep."dateId"
			AND cp."category" = ep."category"
			AND cp."taxonomyId" = ep."taxonomyId"
			AND cp."categoryType" = ep."categoryType"
    )

    -- Insert new products into the productsData table
    INSERT INTO "productsData" (
        "productId",
        "category",
        "categoryType",
        "parentCategory",
        "productRank",
        "pageNumber",
        "screenshot",
        "featured",
        "featuredRank",
        "taxonomyId"
    )
    SELECT DISTINCT
        np."productId",
        np."category",
        np."categoryType",
        np."parentCategory",
        np."productRank"::int,
        np."pageNumber",
        np."screenshot",
        np."featured"::boolean,
        np."featuredRank"::int,
        np."taxonomyId"::int
    FROM new_products_data np;
END;
$$;

ALTER FUNCTION insert_products_ranking_data(jsonb) OWNER TO postgres;

