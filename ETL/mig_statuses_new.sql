SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;
SHOW WORK_MEM;

/*  TODO:   REMOVE BEFORE COMMITING TO REPO */
TRUNCATE TABLE staging.migration_migrated_retailers;

DO
$$
    DECLARE
        _migrating_retailer_ integer = 1;
    BEGIN
        CREATE INDEX IF NOT EXISTS products_retailerId_index ON products ("retailerId");--[2024-11-28 15:15:32] completed in 6 m 3 s 346 ms

        CREATE TABLE IF NOT EXISTS staging.migration_migrated_retailers
        (
            "retailerId"      integer PRIMARY KEY,
            "migration_start" timestamp DEFAULT NOW(),
            "migration_end"   timestamp
        );

        INSERT INTO staging.migration_migrated_retailers ("retailerId")
        VALUES (_migrating_retailer_);

        DROP TABLE IF EXISTS staging.migration_product_status;
        CREATE TABLE staging.migration_product_status AS
        SELECT *
        FROM "productStatuses"
                 INNER JOIN (SELECT id AS "productId", "retailerId", "coreProductId", "date"::date
                             FROM products
                             WHERE "retailerId" = _migrating_retailer_) AS products
                            USING ("productId");--[2024-11-28 15:22:52] 27,185,505 rows affected in 6 m 53 s 33 ms

        CREATE UNIQUE INDEX migration_product_status_productid_uindex
            ON staging.migration_product_status ("productId");--[2024-11-28 15:23:25] completed in 16 s 282 ms

        CREATE INDEX migration_product_status_retailer_coreproduct_date_index
            ON staging.migration_product_status ("retailerId",
                                                 "coreProductId",
                                                 date);--[2024-11-28 15:23:49] completed in 23 s 775 ms
        CREATE INDEX migration_product_status_status_index
            ON staging.migration_product_status (status);--[2024-11-28 15:24:06] completed in 16 s 633 ms

        --[2024-11-28 16:36:27] completed in 4 m 29 s 139 ms
    END
$$;