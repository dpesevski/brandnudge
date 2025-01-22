UPDATE tests.product_status_history
SET tenant_id = "retailerId";
SELECT *
FROM tests.product_status_history;
INSERT INTO tests.product_status_history("retailerId", "coreProductId", date, "productId", status)
SELECT "retailerId", "coreProductId", date, "productId", status
FROM staging.product_status_history;


ALTER TABLE tests.product_status_history
    RENAME TO orig_product_status_history;


DROP TABLE tests.product_status_history;

CREATE TABLE tests.product_status_history
(
    "retailerId"    integer NOT NULL,
    "coreProductId" integer NOT NULL,
    date            date    NOT NULL,
    "productId"     integer,--        CONSTRAINT "testsproduct_status_history_productId_key"            UNIQUE,
    status          text,
    CONSTRAINT tests_product_status_history_pkey
        PRIMARY KEY ("retailerId", "coreProductId", date)
) PARTITION BY LIST ("retailerId");


SELECT id, name
FROM retailers;
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

CREATE TABLE tests.product_status_history_grp_002 PARTITION OF tests.product_status_history FOR VALUES IN ( 576, 708, 1203, 1237, 1238, 1537);
