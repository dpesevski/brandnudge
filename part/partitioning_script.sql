SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;

CREATE SCHEMA IF NOT EXISTS TESTS;

alter table staging.product_status_history
    drop constraint product_status_history_productid_uindex;

drop index staging.product_status_history_productid_uindex;


ALTER TABLE "productStatuses"
    DROP CONSTRAINT productstatuses_products_id_fk;
ALTER TABLE "aggregatedProducts"
    DROP CONSTRAINT "aggregatedProducts_productId_fkey";
ALTER TABLE "productsData"
    DROP CONSTRAINT "productsData_productId_fkey";
ALTER TABLE "promotions"
    DROP CONSTRAINT promotions_products_id_fk;
ALTER TABLE "productStatuses"
    DROP CONSTRAINT "productStatuses_productId_uq";

ALTER TABLE products
    DROP CONSTRAINT products_pkey;

CREATE INDEX products_id ON products (id);

DROP TABLE IF EXISTS tests.products;
CREATE TABLE tests.products
(
    LIKE PUBLIC.PRODUCTS INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
) PARTITION BY LIST ("retailerId");

DROP TABLE IF EXISTS tests.product_status_history;
CREATE TABLE tests.product_status_history
(
    LIKE staging.product_status_history INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
) PARTITION BY LIST ("retailerId");

CREATE TABLE tests.products_2 PARTITION OF tests.products FOR VALUES IN (2);
CREATE TABLE tests.products_3 PARTITION OF tests.products FOR VALUES IN (3);
CREATE TABLE tests.products_8 PARTITION OF tests.products FOR VALUES IN (8);
CREATE TABLE tests.products_10 PARTITION OF tests.products FOR VALUES IN (10);
CREATE TABLE tests.products_13 PARTITION OF tests.products FOR VALUES IN (13);

CREATE TABLE tests.products_1 PARTITION OF tests.products FOR VALUES IN (1);
CREATE TABLE tests.products_159 PARTITION OF tests.products FOR VALUES IN (159);
CREATE TABLE tests.products_1335 PARTITION OF tests.products FOR VALUES IN (1335);
CREATE TABLE tests.products_1536 PARTITION OF tests.products FOR VALUES IN (1536);
CREATE TABLE tests.products_9 PARTITION OF tests.products FOR VALUES IN (9);
CREATE TABLE tests.products_345 PARTITION OF tests.products FOR VALUES IN (345);
CREATE TABLE tests.products_774 PARTITION OF tests.products FOR VALUES IN (774);
CREATE TABLE tests.products_1434 PARTITION OF tests.products FOR VALUES IN (1434);
CREATE TABLE tests.products_1336 PARTITION OF tests.products FOR VALUES IN (1336);
CREATE TABLE tests.products_1302 PARTITION OF tests.products FOR VALUES IN (1302);
CREATE TABLE tests.products_1535 PARTITION OF tests.products FOR VALUES IN (1535);
CREATE TABLE tests.products_609 PARTITION OF tests.products FOR VALUES IN (609);
CREATE TABLE tests.products_1538 PARTITION OF tests.products FOR VALUES IN (1538);
CREATE TABLE tests.products_1533 PARTITION OF tests.products FOR VALUES IN (1533);
CREATE TABLE tests.products_1368 PARTITION OF tests.products FOR VALUES IN (1368);
CREATE TABLE tests.products_642 PARTITION OF tests.products FOR VALUES IN (642);
CREATE TABLE tests.products_675 PARTITION OF tests.products FOR VALUES IN (675);
CREATE TABLE tests.products_1104 PARTITION OF tests.products FOR VALUES IN (1104);
CREATE TABLE tests.products_81 PARTITION OF tests.products FOR VALUES IN (81);
CREATE TABLE tests.products_1269 PARTITION OF tests.products FOR VALUES IN (1269);
CREATE TABLE tests.products_11 PARTITION OF tests.products FOR VALUES IN (11);
CREATE TABLE tests.products_115 PARTITION OF tests.products FOR VALUES IN (115);
CREATE TABLE tests.products_114 PARTITION OF tests.products FOR VALUES IN (114);
CREATE TABLE tests.products_1500 PARTITION OF tests.products FOR VALUES IN (1500);
CREATE TABLE tests.products_807 PARTITION OF tests.products FOR VALUES IN (807);
CREATE TABLE tests.products_510 PARTITION OF tests.products FOR VALUES IN (510);
CREATE TABLE tests.products_1170 PARTITION OF tests.products FOR VALUES IN (1170);
CREATE TABLE tests.products_1401 PARTITION OF tests.products FOR VALUES IN (1401);
CREATE TABLE tests.products_48 PARTITION OF tests.products FOR VALUES IN (48);
CREATE TABLE tests.products_1534 PARTITION OF tests.products FOR VALUES IN (1534);
CREATE TABLE tests.products_1137 PARTITION OF tests.products FOR VALUES IN (1137);
CREATE TABLE tests.products_972 PARTITION OF tests.products FOR VALUES IN (972);
CREATE TABLE tests.products_741 PARTITION OF tests.products FOR VALUES IN (741);
CREATE TABLE tests.products_543 PARTITION OF tests.products FOR VALUES IN (543);
CREATE TABLE tests.products_378 PARTITION OF tests.products FOR VALUES IN (378);
CREATE TABLE tests.products_grp_001 PARTITION OF tests.products FOR VALUES IN (477, 4, 444, 1467, 1038, 873, 910, 908, 915,
    411, 916, 907, 911, 914, 913, 906, 909, 912, 1071, 1072, 775,
    840, 939, 1008, 1006, 1009, 1011, 1005, 1012, 1010, 1013, 1007);

CREATE TABLE tests.products_arch PARTITION OF tests.products FOR VALUES IN ( 576, 708, 1203, 1237, 1238, 1537);

CREATE TABLE tests.product_status_history_2 PARTITION OF tests.product_status_history FOR VALUES IN (2);
CREATE TABLE tests.product_status_history_3 PARTITION OF tests.product_status_history FOR VALUES IN (3);
CREATE TABLE tests.product_status_history_8 PARTITION OF tests.product_status_history FOR VALUES IN (8);
CREATE TABLE tests.product_status_history_10 PARTITION OF tests.product_status_history FOR VALUES IN (10);
CREATE TABLE tests.product_status_history_13 PARTITION OF tests.product_status_history FOR VALUES IN (13);

CREATE TABLE tests.product_status_history_1 PARTITION OF tests.product_status_history FOR VALUES IN (1);
CREATE TABLE tests.product_status_history_159 PARTITION OF tests.product_status_history FOR VALUES IN (159);
CREATE TABLE tests.product_status_history_1335 PARTITION OF tests.product_status_history FOR VALUES IN (1335);
CREATE TABLE tests.product_status_history_1536 PARTITION OF tests.product_status_history FOR VALUES IN (1536);
CREATE TABLE tests.product_status_history_9 PARTITION OF tests.product_status_history FOR VALUES IN (9);
CREATE TABLE tests.product_status_history_345 PARTITION OF tests.product_status_history FOR VALUES IN (345);
CREATE TABLE tests.product_status_history_774 PARTITION OF tests.product_status_history FOR VALUES IN (774);
CREATE TABLE tests.product_status_history_1434 PARTITION OF tests.product_status_history FOR VALUES IN (1434);
CREATE TABLE tests.product_status_history_1336 PARTITION OF tests.product_status_history FOR VALUES IN (1336);
CREATE TABLE tests.product_status_history_1302 PARTITION OF tests.product_status_history FOR VALUES IN (1302);
CREATE TABLE tests.product_status_history_1535 PARTITION OF tests.product_status_history FOR VALUES IN (1535);
CREATE TABLE tests.product_status_history_609 PARTITION OF tests.product_status_history FOR VALUES IN (609);
CREATE TABLE tests.product_status_history_1538 PARTITION OF tests.product_status_history FOR VALUES IN (1538);
CREATE TABLE tests.product_status_history_1533 PARTITION OF tests.product_status_history FOR VALUES IN (1533);
CREATE TABLE tests.product_status_history_1368 PARTITION OF tests.product_status_history FOR VALUES IN (1368);
CREATE TABLE tests.product_status_history_642 PARTITION OF tests.product_status_history FOR VALUES IN (642);
CREATE TABLE tests.product_status_history_675 PARTITION OF tests.product_status_history FOR VALUES IN (675);
CREATE TABLE tests.product_status_history_1104 PARTITION OF tests.product_status_history FOR VALUES IN (1104);
CREATE TABLE tests.product_status_history_81 PARTITION OF tests.product_status_history FOR VALUES IN (81);
CREATE TABLE tests.product_status_history_1269 PARTITION OF tests.product_status_history FOR VALUES IN (1269);
CREATE TABLE tests.product_status_history_11 PARTITION OF tests.product_status_history FOR VALUES IN (11);
CREATE TABLE tests.product_status_history_115 PARTITION OF tests.product_status_history FOR VALUES IN (115);
CREATE TABLE tests.product_status_history_114 PARTITION OF tests.product_status_history FOR VALUES IN (114);
CREATE TABLE tests.product_status_history_1500 PARTITION OF tests.product_status_history FOR VALUES IN (1500);
CREATE TABLE tests.product_status_history_807 PARTITION OF tests.product_status_history FOR VALUES IN (807);
CREATE TABLE tests.product_status_history_510 PARTITION OF tests.product_status_history FOR VALUES IN (510);
CREATE TABLE tests.product_status_history_1170 PARTITION OF tests.product_status_history FOR VALUES IN (1170);
CREATE TABLE tests.product_status_history_1401 PARTITION OF tests.product_status_history FOR VALUES IN (1401);
CREATE TABLE tests.product_status_history_48 PARTITION OF tests.product_status_history FOR VALUES IN (48);
CREATE TABLE tests.product_status_history_1534 PARTITION OF tests.product_status_history FOR VALUES IN (1534);
CREATE TABLE tests.product_status_history_1137 PARTITION OF tests.product_status_history FOR VALUES IN (1137);
CREATE TABLE tests.product_status_history_972 PARTITION OF tests.product_status_history FOR VALUES IN (972);
CREATE TABLE tests.product_status_history_741 PARTITION OF tests.product_status_history FOR VALUES IN (741);
CREATE TABLE tests.product_status_history_543 PARTITION OF tests.product_status_history FOR VALUES IN (543);
CREATE TABLE tests.product_status_history_378 PARTITION OF tests.product_status_history FOR VALUES IN (378);
CREATE TABLE tests.product_status_history_grp_001 PARTITION OF tests.product_status_history FOR VALUES IN (477, 4, 444, 1467, 1038, 873, 910, 908, 915,
    411, 916, 907, 911, 914, 913, 906, 909, 912, 1071, 1072, 775,
    840, 939, 1008, 1006, 1009, 1011, 1005, 1012, 1010, 1013, 1007);

CREATE TABLE tests.product_status_history_arch PARTITION OF tests.product_status_history FOR VALUES IN ( 576, 708, 1203, 1237, 1238, 1537);

SET work_mem = '4GB';
SET max_parallel_workers_per_gather = 4;

INSERT INTO tests.product_status_history
SELECT *
FROM staging.product_status_history;
--[2025-01-31 14:35:42] 213,850,011 rows affected in 35 m 29 s 704 ms

INSERT INTO tests.products
SELECT *
FROM public.products;
