/*
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER proddb_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'brandnudge-db-cluster-prod.cluster-cgtow2b7iejj.eu-north-1.rds.amazonaws.com', port '5432', dbname 'brandnudge');
CREATE USER MAPPING FOR postgres SERVER proddb_fdw OPTIONS (user 'dejan_user', password 'nCIqhxXgwItIGtK');

DROP SCHEMA IF EXISTS prod_fdw CASCADE;
CREATE SCHEMA prod_fdw;
IMPORT FOREIGN SCHEMA public FROM SERVER proddb_fdw INTO prod_fdw;

CREATE SCHEMA IF NOT EXISTS test;

DROP TABLE IF EXISTS test.retailer;
CREATE TABLE test.retailer
(
    "retailerId" integer,
    flag         text,
    is_pp        boolean
);


INSERT INTO test.retailer ("retailerId", flag, is_pp)
VALUES  (1, 'create-products', false),
        (2, 'create-products', false),
        (4, 'create-products-pp', true),
        (48, 'create-products-pp', true),
        (81, 'create-products-pp', true),
        (114, 'create-products-pp', true),
        (378, 'create-products-pp', true),
        (411, 'create-products-pp', true),
        (444, 'create-products-pp', true),
        (477, 'create-products-pp', true),
        (510, 'create-products-pp', true),
        (543, 'create-products-pp', true),
        (609, 'create-products-pp', true),
        (642, 'create-products-pp', true),
        (675, 'create-products-pp', true),
        (741, 'create-products-pp', true),
        (774, 'create-products-pp', true),
        (775, 'create-products-pp', true),
        (807, 'create-products-pp', true),
        (840, 'create-products-pp', true),
        (873, 'create-products-pp', true),
        (906, 'create-products-pp', true),
        (907, 'create-products-pp', true),
        (908, 'create-products-pp', true),
        (909, 'create-products-pp', true),
        (910, 'create-products-pp', true),
        (911, 'create-products-pp', true),
        (912, 'create-products-pp', true),
        (913, 'create-products-pp', true),
        (914, 'create-products-pp', true),
        (915, 'create-products-pp', true),
        (916, 'create-products-pp', true),
        (939, 'create-products-pp', true),
        (972, 'create-products-pp', true),
        (1005, 'create-products-pp', true),
        (1006, 'create-products-pp', true),
        (1007, 'create-products-pp', true),
        (1008, 'create-products-pp', true),
        (1009, 'create-products-pp', true),
        (1010, 'create-products-pp', true),
        (1011, 'create-products-pp', true),
        (1012, 'create-products-pp', true),
        (1013, 'create-products-pp', true),
        (1038, 'create-products-pp', true),
        (1071, 'create-products-pp', true),
        (1072, 'create-products-pp', true),
        (1104, 'create-products-pp', true),
        (1137, 'create-products-pp', true),
        (1170, 'create-products-pp', true),
        (3, NULL, false),
        (8, NULL, false),
        (9, NULL, false),
        (10, NULL, false),
        (13, NULL, false),
        (159, 'create-products-pp', true),
        (345, NULL, false),
        (1269, 'create-products-pp', true),
        (1302, 'create-products-pp', true),
        (11, 'create-products-pp', true),
        (1335, 'create-products-pp', true)
;
*/

/*
DROP TABLE IF EXISTS test.tprd_coreproducts;
CREATE TABLE IF NOT EXISTS test.tprd_coreproducts AS
SELECT "coreProducts".id         AS "coreProductId",
       "coreProducts"."createdAt",
       MIN(products."createdAt") AS first_usage,
       COUNT(*)
FROM prod_fdw."coreProducts"
         INNER JOIN prod_fdw.products ON ("coreProducts".id = products."coreProductId")
WHERE "sourceId" IN
          /* ('RHTWR3S_WH', 'RHTWR3SB_BL', 'PSV165', 'CJF11WHUK_WH', '837188', '837186', '837185', '796381', '6552961',
            '5331413', '5060604012354', '505432PLP', '38614301', '354655', '312834095', '311441428', '311426827',
            '311274925', '311260043', '311224945', '308453931', '285896240', '285896234', '28040_GY', '26740_BK',
            '262815303', '26020_TE', '25591_WH', '24510_AQ', '1927350000', '1674930', '1674908', '1657120', '1625421',
            '1624855', '1622306', '1559502', '1551523', '1550794', '1508707', '1487021', '1460874', '1460863', '1460859',
            '1376705', '134095', '11694628', '11694616', '11694615', '1007016', '100303155')*/
      ('000000000000293573', '000000000000531092', '00007033033183', '00007033035098', '00007033041198',
       '00007033042210', '00400580854010', '0070330128071', '00871520081720', '1000383202221', '1000383204164',
       '1000383204175', '1000383204361', '1000383204379', '1000383206830', '1000383209698', '1000383218056',
       '1000383222152', '1000383225265', '1000383226683', '1000383226685', '1000383229237', '1000383229249',
       '100303155', '1007016', '1014469000', '1015646001', '10229661', '10234963', '10236449', '10241489', '10241747',
       '10242403', '10242433', '10242435', '10243865', '10244891', '10245059', '10245443', '10245594', '10245679',
       '10245743', '10246786', '10246792', '10246811', '10247127', '10247247', '10247729', '10248236', '10248717',
       '10248763', '10249021', '10249472', '10250023', '10250044', '10250378', '10252086', '10252191', '10252425',
       '10252543', '10253092', '10253230', '10254017', '10254082', '10254307', '10254732', '10255090', '10255107',
       '10255111', '10255128', '10255379', '10255865', '10256379', '10256778', '10257774', '10259166', '10260474',
       '10260534', '10260535', '10260556', '10261521', '10261862', '10261952', '10262150', '10263357', '10264132',
       '1027427001', '1031907002', '1051879001', '112445', '113537', '11694615', '11694616', '11694628', '1197773000',
       '12614203', '1323501', '134095', '136192', '1376705', '141696', '1448869', '1455573', '1459078', '1459310',
       '1460859', '1460863', '1460874', '1472488', '1472817', '1472821', '1472822', '1472826', '1472881', '1472883',
       '1472884', '1487021', '1491803001', '1496631005', '1501681000', '1508707', '153826', '1550794', '1551523',
       '1559502', '155962', '156829', '157147', '159190', '1601003422', '160972', '160984', '1622306', '1624482000',
       '1624855', '1625421', '1657120', '1674908', '1674930', '1675211', '1675639', '1683185004', '1702986000',
       '1709635', '1713348', '1713372', '1713453', '1713475', '1714511', '1714541', '1714559', '1735705', '173692PLP',
       '1758036000', '1802871001', '1816593000', '1840103000', '186080', '1869010000', '1871901000', '1871902000',
       '1892078000', '1892168000', '1894261000', '1895394000', '1896103000', '1896282000', '1897260000', '1897992001',
       '1898336000', '1906209000', '1907190000', '1907194000', '1907993000', '1910518000', '1910835000', '1910835002',
       '1915411000', '1918336000', '1919220000', '1920836000', '1921865000', '1922342000', '1922407000', '1922409000',
       '1923221000', '1923487000', '1924629000', '1924831000', '1924856000', '1925834000', '1925834001', '1927350000',
       '229541', '237150', '24155304', '24155404', '24510_AQ', '252517078', '25591_WH', '26020_TE', '262815303',
       '26740_BK', '272285', '27278602', '2730966', '2730988', '27638702', '27638902', '27970902', '27971002',
       '279748PLP', '28040_GY', '28191801', '2838100000000', '285896234', '285896240', '292474', '293610ZTR',
       '299792PLP', '3030050188028', '3030050191431', '3030053836377', '3030053840046', '303869643', '306821608',
       '308153013', '308429650', '308453931', '3086123360648', '3086123360655', '3086123378698', '3086123431287',
       '3086123537569', '3086123538115', '3086123538153', '3086123545397', '3086123594630', '3086123594647',
       '3086123594654', '3086123594661', '3086123594678', '3086123594685', '3086123595149', '3086123595385',
       '3086123679078', '3086123679085', '3086123717206', '3086123717534', '3086123718531', '3086123734555',
       '3086123734562', '3086123734623', '3086123734661', '3086123734678', '3086123734685', '3086123734784',
       '3086123734814', '3086123735316', '3086123735347', '3086123735354', '3086123735385', '3086123735590',
       '3086123740266', '3086123742444', '3086123742451', '3086123745308', '3086123745315', '3086123747692',
       '3086123748002', '3086123748033', '3086123748040', '3086123748743', '3086123750104', '3086123750432',
       '3086123751439', '310730157', '3110447', '311208032', '311224945', '311260043', '311274925', '311426827',
       '311441428', '31191102', '312084371', '312084745', '312267898', '312582985', '312834095', '313173949',
       '314030518', '314432135', '315332577', '315332701', '315341114', '315349313', '315391555', '315431745',
       '315431837', '315431964', '315431970', '315431987', '315502190', '315562941', '315569110', '315590786',
       '315634839', '315634845', '315634874', '315736483', '315741240', '315785533', '315840917', '315860876',
       '315912758', '316089808', '316089814', '316089843', '316191433', '316195544', '316225429', '316657119',
       '316808374', '316934385', '316942087', '316948377', '317046115', '317053538', '317065757', '317066650',
       '317067764', '317180502', '317181173', '317183574', '317186703', '317189429', '317190939', '317289455',
       '317299184', '317302636', '317313709', '317396077', '317533702', '317551191', '320031', '325098822', '325098826',
       '325098828', '325098833', '325098838', '325098839', '325098862', '325098866', '325098870', '325098873',
       '325098885', '325098935', '325098940', '325098982', '3270220000082', '3270220000457', '3270220048701',
       '334508PLP', '3411359', '3411380', '3411438', '3441920941504', '3469891135937', '349172', '354655', '36550701',
       '36566901', '3724095', '3724164', '37325801', '3735422', '37456501', '376376', '37696101', '37700201',
       '37704501', '37953301', '380093', '38246001', '38246101', '38415701', '38470801', '38613401', '38614301',
       '38862701', '38862801', '389380', '38946001', '38946101', '391956', '392564', '396838', '397120', '397568',
       '399429', '399701', '399884', '4002359019128', '4002359019159', '4006381101981', '402424', '403273', '403274',
       '405261', '4061459931099', '4061459940282', '4061461460327', '4061461460365', '4061462189609', '4061462212321',
       '4061462212413', '4061462511165', '4061462511202', '4061462511233', '4061462574863', '4061462781094',
       '4061462781155', '4061462987021', '4061463174871', '4061464848993', '4061464849013', '4061464849020', '406340',
       '407018', '407168', '408460', '408650', '408734', '4088600568447', '4088600571409', '4088600571416', '409491',
       '409492', '411398', '411458', '411656', '411657', '411661', '411667', '412524', '414300', '414355', '414384',
       '414810', '414937', '414939', '4210201192732', '431026PLP', '439348', '452106', '469888', '470468', '472132',
       '489683', '5018297011529', '5018297011604', '502091', '5025232873951', '504863', '505432PLP', '5060604012354',
       '520554PLP', '520564PLP', '53198', '5331413', '545270PLP', '565644PLP', '571207', '5783539', '5889043',
       '5996415036794', '618645', '618646', '622030', '627616', '632408', '6552961', '6620642', '6620675', '6620700',
       '6620711', '668684PLP', '679371', '7131981', '7131982', '7131983', '7143016', '7148440', '7149827', '7149852',
       '7149853', '7149967', '7149968', '7149969', '7149970', '7149971', '7149972', '7149980', '7149981', '7149991',
       '7149992', '7149993', '7149994', '7149995', '7149997', '7149999', '7150000', '7150002', '7150005', '7150006',
       '7150007', '7150008', '7150010', '7150012', '7150209', '7150221', '7150222', '7150224', '7150225', '7150227',
       '7150287', '7150288', '7150289', '7150306', '7150307', '7150308', '7150313', '7150314', '7150315', '7150316',
       '7150317', '7150318', '7150319', '7150320', '7150321', '7150322', '7150323', '7150324', '7150325', '7150326',
       '7150327', '7150328', '7150329', '7150330', '7150331', '7150332', '7150369', '7150389', '7150390', '7150394',
       '7150417', '7150418', '7150420', '7150919', '7150989', '7150990', '7150991', '7150992', '7150993', '7150994',
       '7150995', '7150996', '7150997', '7150998', '7151029', '7151061', '7151062', '7151063', '7151066', '7151067',
       '7151068', '7151078', '7151112', '7151113', '7151114', '7151153', '7151154', '7152841', '717114', '727359',
       '7350071700808', '757857', '7689429', '7689600', '7689622', '7706980', '796381', '8013480', '8050341', '8050385',
       '8050840', '8050909', '8051151', '805467', '8055425', '8098632', '8098676', '8098698', '8100086', '8129452',
       '8185577', '828959', '833453', '834247', '834253', '834255', '837185', '837186', '837188', '837650', '841648',
       '842988', '842991', '842992', '8435484042246', '8435484042451', '843612', '844181', '844378', '844488', '844490',
       '844630', '844632', '844634', '845868PLP', '874412FJY', '886805PLP', '897214', '898515', '901838', '902979',
       '903641', '903654', '903704', '903734', '903813', '904922', '905040', '905041', '905266', '905306', '905310',
       '906308', '906428', '906769', '907297', '907319', '907433', '907519', '907639', '908275', '909081', '909263',
       '930239', '938231', '939892PLP', '948706', '950329', '961872', '970869PLP', '970920PLP', '994552',
       '9999999113849', 'B00SSXCSTM', 'B08VBNC1SM', 'CJF11WHUK_WH', 'PSV165', 'RHTWR3SB_BL', 'RHTWR3S_WH')
GROUP BY "coreProducts".id, "coreProducts"."createdAt";

DROP TABLE IF EXISTS test.tstg_coreproducts;
CREATE TABLE IF NOT EXISTS test.tstg_coreproducts AS
SELECT "coreProducts".id         AS "coreProductId",
       "coreProducts"."createdAt",
       MIN(products."createdAt") AS first_usage,
       COUNT(*)
FROM "coreProducts"
         LEFT OUTER JOIN products ON ("coreProducts".id = products."coreProductId")
GROUP BY "coreProducts".id, "coreProducts"."createdAt";
*/

DROP TABLE IF EXISTS test.tprd_products;
CREATE TABLE IF NOT EXISTS test.tprd_products AS
SELECT *, NULL::json AS promo_data
FROM prod_fdw.products
         INNER JOIN (SELECT id AS "dateId", date AS dates_date
                     FROM prod_fdw.dates
                     WHERE id > 27076
    --WHERE date >= '2024-07-10'
) AS dates
                    USING ("dateId");

DROP TABLE IF EXISTS test.tstg_products;
CREATE TABLE IF NOT EXISTS test.tstg_products AS
SELECT *, NULL::json AS promo_data
FROM products
         INNER JOIN (SELECT id AS "dateId", date AS dates_date
                     FROM dates
                     WHERE id > 28028
    --WHERE date >= '2024-07-10'
) AS dates
                    USING ("dateId");

CREATE INDEX IF NOT EXISTS tprd_products_retailerId_date_sourceId_index
    ON test.tprd_products ("retailerId", dates_date, "sourceId");

CREATE INDEX IF NOT EXISTS tstg_products_retailerId_date_sourceId_index
    ON test.tstg_products ("retailerId", dates_date, "sourceId");
/*
WITH promo AS (SELECT promotions."productId",
                      JSON_AGG(promo ORDER BY promo.description) AS promo_data
               FROM promotions
                        CROSS JOIN LATERAL (SELECT DATE_PART('month', promotions."startDate"::date) || '/' ||
                                                   DATE_PART('day', promotions."startDate"::date) || '/' ||
                                                   DATE_PART('year', promotions."startDate"::date) AS "startDate",
                                                   DATE_PART('month', promotions."endDate"::date) || '/' ||
                                                   DATE_PART('day', promotions."endDate"::date) || '/' ||
                                                   DATE_PART('year', promotions."endDate"::date)   AS "endDate") AS lat_dates
                        CROSS JOIN LATERAL (SELECT promotions."retailerPromotionId",
                                                   promotions.description,
                                                   lat_dates."startDate",
                                                   lat_dates."endDate",
                                                   REPLACE(promotions."promoId",
                                                           REPLACE(promotions."startDate", ' ', '_'),
                                                           lat_dates."startDate") AS "promoId") AS promo
                        INNER JOIN test.tstg_products ON (promotions."productId" = tstg_products.id)
               GROUP BY promotions."productId")
UPDATE test.tstg_products AS products
SET promo_data=promo.promo_data
FROM promo
WHERE promo."productId" = products.id;

WITH promo AS (SELECT promotions."productId",
                      JSON_AGG(promo ORDER BY promo.description) AS promo_data
               FROM prod_fdw.promotions
                        INNER JOIN (SELECT id AS "productId"
                                    FROM prod_fdw.products
                                    WHERE products."dateId" >= 25327) AS products
                                   USING ("productId")
                        CROSS JOIN LATERAL (SELECT promotions."retailerPromotionId",
                                                   promotions.description,
                                                   promotions."startDate",
                                                   promotions."endDate",
                                                   promotions."promoId") AS promo
               GROUP BY promotions."productId")
UPDATE test.tprd_products AS products
SET promo_data=promo.promo_data
FROM promo
WHERE promo."productId" = products.id;
*/

/*
SELECT *
FROM dates
WHERE id > 24646
ORDER BY "createdAt" DESC NULLS LAST;

SELECT *
FROM prod_fdw.dates
WHERE id > 24646
ORDER BY "createdAt" DESC NULLS LAST;

SELECT COUNT(*)
FROM products
WHERE "dateId" > 24646;

SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" > 24646;
*/

/*  TESTS   */


/*  T01:  product count prod <-> staging    */
WITH prod AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
              FROM test.tprd_products),
     staging AS (SELECT DISTINCT dates_date, "sourceId", "retailerId"
                 FROM test.tstg_products),
     prod_cnt AS (SELECT "retailerId", COUNT(prod.*) AS prod_prd_count, COUNT(staging.*) AS stg_prd_count
                  FROM prod
                           FULL OUTER JOIN staging USING ("retailerId", dates_date, "sourceId")
                  GROUP BY "retailerId")
SELECT "retailerId",
       is_pp,
       prod_prd_count,
       stg_prd_count,
       prod_prd_count - stg_prd_count AS prd_count_diff
FROM prod_cnt
         FULL OUTER JOIN test.retailer USING ("retailerId")
ORDER BY "retailerId";

/*  T02:  missing products in prod    */
SELECT *
FROM test.tstg_products AS staging
         LEFT OUTER JOIN test.tprd_products AS prod
                         USING ("retailerId", dates_date, "sourceId")
WHERE prod.id IS NULL;

/*  T03:  product differences in general attributes    */
SELECT COUNT(*)
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."sourceType" != prod."sourceType"
   -- OR staging.ean != prod.ean
   OR staging.promotions != prod.promotions
   --OR staging."promotionDescription" != prod."promotionDescription"
   --OR staging.features != prod.features
   OR staging."productBrand" != prod."productBrand"
   OR staging."productTitle" != prod."productTitle"
   OR staging."productImage" != prod."productImage"
   OR staging."secondaryImages" != prod."secondaryImages"
   OR staging."productDescription" != prod."productDescription"
   -- OR staging."productInfo" != prod."productInfo"
   -- OR staging."promotedPrice" != prod."promotedPrice"
   OR staging."productInStock" != prod."productInStock"
   OR staging."productInListing" != prod."productInListing"
   OR staging."reviewsCount" != prod."reviewsCount"
   OR staging."reviewsStars" != prod."reviewsStars"
   OR staging."eposId" != prod."eposId"
   --OR staging.multibuy != prod.multibuy
   --OR staging."coreProductId" != prod."coreProductId"
   OR staging."imageId" != prod."imageId"
   OR staging.size != prod.size
   OR staging."pricePerWeight" != prod."pricePerWeight"
   --OR staging.href != prod.href
   OR staging.nutritional != prod.nutritional
   --OR staging."basePrice" != prod."basePrice"
   --OR staging."shelfPrice" != prod."shelfPrice"
   OR staging."productTitleDetail" != prod."productTitleDetail"
   OR staging."sizeUnit" != prod."sizeUnit"
   OR staging.marketplace != prod.marketplace
   OR staging."marketplaceData"::text != prod."marketplaceData"::text
   OR staging."priceMatchDescription" != prod."priceMatchDescription"
   OR staging."priceMatch" != prod."priceMatch";

/*  T04:  product differences in prices    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."promotedPrice" AS stag_promotedPrice,
       staging."basePrice"     AS stag_basePrice,
       staging."shelfPrice"    AS stag_shelfPrice,
       prod."promotedPrice"    AS prod_promotedPrice,
       prod."basePrice"        AS prod_basePrice,
       prod."shelfPrice"       AS prod_shelfPrice,
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."promotedPrice"::numeric != REPLACE(REPLACE(prod."promotedPrice", ',', ''), '', NULL)::numeric
   OR staging."basePrice"::numeric != REPLACE(REPLACE(prod."basePrice", ',', ''), '', NULL)::numeric
   OR staging."shelfPrice"::numeric != REPLACE(REPLACE(prod."shelfPrice", ',', ''), '', NULL)::numeric
ORDER BY staging."sourceId" DESC;

/*  T05:  product differences in ean    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging.ean,
       prod.ean,
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging.ean != prod.ean
ORDER BY staging."sourceId" DESC;

/*  T06:  product differences in coreProductId    */
WITH staging AS (SELECT tstg_products.*, "coreProducts".ean AS core_ean
                 FROM test.tstg_products
                          LEFT OUTER JOIN "coreProducts" ON ("coreProductId" = "coreProducts".id)),
     prod AS (SELECT tprd_products.*, "coreProducts".ean AS core_ean
              FROM test.tprd_products
                       LEFT OUTER JOIN prod_fdw."coreProducts" ON ("coreProductId" = "coreProducts".id))
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."coreProductId",
       prod."coreProductId",
       staging.core_ean,
       prod.core_ean,
       prod.*
FROM staging
         INNER JOIN prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."coreProductId" != prod."coreProductId"
  AND staging.core_ean != prod.core_ean
ORDER BY staging."sourceId" DESC;

/*  T07:  product differences in multibuy    */
WITH staging AS (SELECT tstg_products.*,
                        debug_tmp_product_pp.promotions AS promodata
                 FROM test.tstg_products
                          INNER JOIN staging.debug_tmp_product_pp USING (id))
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging.multibuy,
       prod.multibuy,
       JSONB_PRETTY(TO_JSONB(staging.promodata)) AS promodata,
       prod.*
FROM staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging.multibuy != prod.multibuy
ORDER BY staging."sourceId" DESC;

/*  T08:  product differences in promotionDescription    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."promotionDescription" AS staging_promotionDescription,
       prod."promotionDescription"    AS prod_promotionDescription,
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."promotionDescription" != prod."promotionDescription"
ORDER BY staging."sourceId" DESC;

/*  T09:  product differences in href    */
WITH staging AS (SELECT tstg_products.*,
                        test_run_id
                 FROM test.tstg_products
                          INNER JOIN staging.debug_tmp_product USING (id))
SELECT "retailerId",
       dates_date,
       "sourceId",
       test_run_id,
       staging."href" AS staging_href,
       prod."href"    AS prod_href
FROM staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."href" != prod."href";


/*  T10:  product differences in features    */
WITH staging AS (SELECT tstg_products.*,
                        debug_tmp_daily_data.features AS features_data
                 FROM test.tstg_products
                          LEFT OUTER JOIN staging.debug_tmp_daily_data USING ("sourceId", "sourceType", date))
SELECT "retailerId",
       dates_date,
       "sourceId",
       features_data,
       staging."features" AS staging_features,
       prod."features"    AS prod_features,
       prod.*
FROM staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging.features != prod.features;

/*  T11:  product differences in productInfo    */
WITH staging AS (SELECT tstg_products.*,
                        debug_tmp_daily_data.href          AS href_data,
                        debug_tmp_daily_data."productInfo" AS productInfo_data
                 FROM test.tstg_products
                          LEFT OUTER JOIN staging.debug_tmp_daily_data USING ("sourceId", "sourceType", date))
SELECT "retailerId",
       dates_date,
       "sourceId",
       ROW_NUMBER()
       OVER (PARTITION BY "retailerId", dates_date, "sourceId" ORDER BY href_data DESC) AS daily_load_record_version,
       productInfo_data,
       staging."productInfo"                                                            AS staging_productInfo,
       prod."productInfo"                                                               AS prod_productInfo,
       prod.*
FROM staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."productInfo" != prod."productInfo";
/*
/*  T12A:  pp loads with multiple records for a single product - different promoData and prices   */
WITH daily_load AS (SELECT fetched_data #>> '{retailer, id}'                     AS "retailerId",
                           "sourceId",
                           "promoData",
                           "skuURL",
                           ROW_NUMBER()
                           OVER (PARTITION BY "sourceId" ORDER BY "skuURL" DESC) AS rownum,

                           date,
                           ean,
                           brand,
                           title,
                           "shelfPrice",
                           "wasPrice",
                           "cardPrice",
                           "inStock",
                           "onPromo"
                    FROM staging.retailer_daily_data
                             CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                                        fetched_data #> '{products}') AS product
                    WHERE debug_test_run_id = 313)
SELECT *
FROM daily_load
WHERE "sourceId" IN ('578732');
--, '196087');


/*  T12B:  pp loads with multiple records for a single product - different ean   */
WITH daily_load AS (SELECT fetched_data #>> '{retailer, id}'                     AS "retailerId",
                           "sourceId",
                           "promoData",
                           "skuURL",
                           ROW_NUMBER()
                           OVER (PARTITION BY "sourceId" ORDER BY "skuURL" DESC) AS rownum,

                           date,
                           ean,
                           brand,
                           title,
                           "shelfPrice",
                           "wasPrice",
                           "cardPrice",
                           "inStock",
                           "onPromo"
                    FROM staging.retailer_daily_data
                             CROSS JOIN LATERAL JSON_POPULATE_RECORDSET(NULL::staging.retailer_data_pp,
                                                                        fetched_data #> '{products}') AS product
                    WHERE debug_test_run_id = 320)
SELECT *
FROM daily_load
WHERE "sourceId" IN ('1460859');
*/
/*
/*  T06-details:  product differences in coreProductId    */
WITH staging AS (SELECT products.*,
                        core.first_usage,
                        core."createdAt" AS core_created_at,
                        core.count
                 FROM (SELECT tstg_products.*,
                              products.test_run_id
                       FROM test.tstg_products
                                LEFT OUTER JOIN (SELECT id, MIN(test_run_id) AS test_run_id
                                                 FROM staging.debug_tmp_product
                                                 GROUP BY id
                                                 UNION
                                                 SELECT id, MIN(test_run_id) AS test_run_id
                                                 FROM staging.debug_tmp_product_pp
                                                 GROUP BY id) AS products USING (id)) AS products
                          LEFT OUTER JOIN test.tstg_coreproducts AS core USING ("coreProductId")),
     prod AS (SELECT products.*,
                     core.first_usage,
                     core."createdAt" AS core_created_at,
                     core.count
              FROM test.tprd_products AS products
                       LEFT OUTER JOIN test.tprd_coreproducts AS core USING ("coreProductId"))
SELECT "retailerId",
       dates_date,
       "sourceId",
       test_run_id,

       staging."coreProductId",
       staging.core_created_at,
       staging.first_usage,
       staging.count,
       staging.ean,


       prod."coreProductId",
       prod.core_created_at,
       prod.first_usage,
       prod.count

FROM staging
         INNER JOIN prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."coreProductId" != prod."coreProductId"
  AND staging.core_created_at - prod.core_created_at > '1 day'
ORDER BY staging."sourceId" DESC;

/*  T06-sample:  barcodes with a difference in coreproduct_id    */
SELECT *
FROM "coreProductBarcodes" AS staging
         FULL OUTER JOIN prod_fdw."coreProductBarcodes" AS prod USING (barcode)
WHERE staging."coreProductId" != prod."coreProductId"
  AND barcode IN ('0000000PSV165', '8720181547102', '5059001018809', '5059001018779', '5060523019816', '5060523019809',
                  '5060523019793', '8720181303173', '9300830087884', '5010415220141', '5060604012354', '8690146168713',
                  '0885131702548', '3086125002805', '5061025058365', '5056725533335', '5056725538293', '5056725502409',
                  '5061025039388', '5056725529161', '5056725533502', '5056725510251', '5056725500085', '5056399127137',
                  '5056725513894', '5056399127687', '5056725516918', '5055974859760', '5012701579001', '4895248002352',
                  '4895248000327', '4895248000334', '4897097260709', '9421907143033', '4895248000310', '4895248002062',
                  '0888793306857', '0888793306833', '28040_GY', '26740_BK', '0820650807794', '26020_TE', '25591_WH',
                  '5024071280012', 'supervalu1927350000', '4006000112695', '4006000111698', '4067796000498',
                  '4067796000702', '4066447713466', '4066447580334', '5011832062819', '4068134036629', '4066447562750',
                  '8712175936269', '8712175936771', '4058172216275', '4066447382433', '4066447783339', '4006000111650',
                  '4006000111926', '4027800106806', '4027800106905', '1719356563597', '1719356563597', '1719356563597',
                  '4066447755336', 'Dunnes_100303155', '5063089543603', '5000171061485', '5000171061478',
                  '5063089437414')
*/
/*  T14:  product differences in promo_data    */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging.promo_data #>> '{0,startDate}',
       prod.promo_data #>> '{0,startDate}'

FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE LOWER(staging.promo_data::text) != LOWER(prod.promo_data::text)
ORDER BY staging."sourceId" DESC;

/*  T15:  product differences in  productInStock   */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."productInStock",
       prod."productInStock",
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."productInStock" != prod."productInStock"
ORDER BY staging."sourceId" DESC;

/*  T16:  product differences in productBrand   */
SELECT "retailerId",
       dates_date,
       "sourceId",
       staging."productBrand",
       prod."productBrand",
       prod.*
FROM test.tstg_products AS staging
         INNER JOIN test.tprd_products AS prod
                    USING ("retailerId", dates_date, "sourceId")
WHERE staging."productBrand" != prod."productBrand"
ORDER BY staging."sourceId" DESC;
