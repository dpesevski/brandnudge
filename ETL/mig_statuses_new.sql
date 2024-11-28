SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

/*  TODO:   REMOVE BEFORE COMMITING TO REPO */
TRUNCATE TABLE staging.migration_migrated_retailers;

CREATE OR REPLACE FUNCTION staging.migrate_retailer(id INTEGER) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    CREATE INDEX IF NOT EXISTS products_retailerId_index ON products ("retailerId");--[2024-11-28 15:15:32] completed in 6 m 3 s 346 ms

    RAISE NOTICE 'products_retailerId_index created';

    CREATE TABLE IF NOT EXISTS staging.migration_migrated_retailers
    (
        "retailerId"      integer PRIMARY KEY,
        "migration_start" timestamp DEFAULT NOW(),
        "migration_end"   timestamp
    );

    INSERT INTO staging.migration_migrated_retailers ("retailerId")
    VALUES (migrate_retailer.id);

    DROP TABLE IF EXISTS staging.migration_product_status;
    CREATE TABLE staging.migration_product_status AS
    SELECT *
    FROM "productStatuses"
             INNER JOIN (SELECT products.id AS "productId", "retailerId", "coreProductId", "date"::date
                         FROM products
                         WHERE "retailerId" = migrate_retailer.id) AS products
                        USING ("productId");--[2024-11-28 15:22:52] 27,185,505 rows affected in 6 m 53 s 33 ms

    RAISE NOTICE 'staging.migration_product_status created';

    CREATE UNIQUE INDEX migration_product_status_productid_uindex
        ON staging.migration_product_status ("productId");--[2024-11-28 15:23:25] completed in 16 s 282 ms

    CREATE INDEX migration_product_status_retailer_coreproduct_date_index
        ON staging.migration_product_status ("retailerId",
                                             "coreProductId",
                                             date);--[2024-11-28 15:23:49] completed in 23 s 775 ms
    CREATE INDEX migration_product_status_status_index
        ON staging.migration_product_status (status);
    --[2024-11-28 15:24:06] completed in 16 s 633 ms

    --[2024-11-28 16:36:27] completed in 4 m 29 s 139 ms

    /*  DELETE EXTRA De-listed records  */
    RAISE NOTICE 'Cleaning of extra `De-listed` records started';

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_productstatuses AS TABLE "productStatuses"
        WITH NO DATA;
    WITH deleted AS (
        WITH product_status_prev AS (SELECT *,
                                            LAG("productId")
                                            OVER (PARTITION BY "retailerId","coreProductId" ORDER BY date, "productId" DESC) AS prev_product_id,
                                            LAG(status)
                                            OVER (PARTITION BY "retailerId","coreProductId" ORDER BY date, "productId" DESC) AS prev_status
                                     FROM staging.migration_product_status)
            DELETE
                FROM "productStatuses"
                    USING product_status_prev
                    WHERE "productStatuses"."productId" = product_status_prev."productId"
                        AND product_status_prev.status IN ('de-listed', 'De-listed')
                        AND product_status_prev.prev_status IN ('de-listed', 'De-listed')
                    RETURNING "productStatuses".*)
    INSERT
    INTO staging.data_corr_status_deleted_productstatuses
    SELECT *
    FROM deleted;--[2024-11-28 17:34:43] 94,805 rows affected in 2 m 11 s 12 ms

    RAISE NOTICE 'staging.data_corr_status_deleted_productstatuses updated';

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_aggregatedProducts AS TABLE "aggregatedProducts"
        WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "aggregatedProducts"
                USING staging.data_corr_status_deleted_productstatuses
                WHERE "aggregatedProducts"."productId" = data_corr_status_deleted_productstatuses."productId"
                RETURNING "aggregatedProducts".*)
    INSERT
    INTO staging.data_corr_status_deleted_aggregatedProducts
    SELECT *
    FROM deleted;

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_productsData AS TABLE "productsData"
        WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "productsData"
                USING staging.data_corr_status_deleted_productstatuses
                WHERE "productsData"."productId" = data_corr_status_deleted_productstatuses."productId"
                RETURNING "productsData".*)
    INSERT
    INTO staging.data_corr_status_deleted_productsData
    SELECT *
    FROM deleted;

    RAISE NOTICE 'staging.data_corr_status_deleted_productsData updated';

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_promotions AS TABLE "promotions" WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM "promotions"
                USING staging.data_corr_status_deleted_productstatuses
                WHERE "promotions"."productId" = data_corr_status_deleted_productstatuses."productId"
                RETURNING "promotions".*)
    INSERT
    INTO staging.data_corr_status_deleted_promotions
    SELECT *
    FROM deleted;

    CREATE TABLE IF NOT EXISTS staging.data_corr_status_deleted_products AS TABLE products WITH NO DATA;
    WITH deleted AS (
        DELETE
            FROM products
                USING staging.data_corr_status_deleted_productstatuses
                WHERE products.id = data_corr_status_deleted_productstatuses."productId"
                RETURNING products.*)
    INSERT
    INTO staging.data_corr_status_deleted_products
    SELECT *
    FROM deleted;
    --[2024-11-28 17:59:01] 94,805 rows affected in 16 s 218 ms

    RAISE NOTICE 'staging.data_corr_status_deleted_products updated';

    DELETE
    FROM staging.migration_product_status
        USING staging.data_corr_status_deleted_productstatuses
    WHERE migration_product_status."productId" = data_corr_status_deleted_productstatuses."productId";

    RAISE NOTICE 'Cleaning of extra `De-listed` records completed';

    UPDATE staging.migration_migrated_retailers
    SET migration_end=CLOCK_TIMESTAMP()
    WHERE "retailerId" = migrate_retailer.id;
    /*  DELETE EXTRA De-listed records:  END */
END
$$;

SELECT staging.migrate_retailer(1);