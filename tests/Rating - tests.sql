SELECT "id",
       "name",
       "checkList",
       "color",
       "createdAt",
       "updatedAt",
       "manufacturerId",
       "brandId"
FROM "brands" AS "brands"
WHERE (("brands"."manufacturerId" IN
        ('1', '3', '7', '20', '24', '28', '29', '30', '31', '32', '34', '39', '42', '53', '56', '58', '61', '62', '63',
         '64', '65', '66', '67', '77', '79', '81', '84', '88', '91', '94', '95', '98', '101', '102', '106', '112',
         '116', '132', '136', '139', '150', '152', '159', '166', '170', '179', '180', '181', '184', '185', '186', '194',
         '216', '218', '222', '226', '232', '235', '241', '245', '260', '261', '265', '285', '287', '295', '302', '307',
         '315', '398', '402', '412', '437', '438', '440', '452', '457', '458', '465', '473', '547', '584', '597', '615',
         '620', '631', '640', '655', '681', '703', '737', '788', '797', '810', '821', '825', '831', '841', '853', '858',
         '862', '863', '866', '871', '874', '944', '961', '969', '994', '995', '1011', '1012', '1020', '1054', '1082',
         '1088', '1089', '1132', '1304', '1332', '1343', '1379', '1402', '1429', '1432', '1443', '1445', '1447', '1490',
         '1503', '1519', '1525', '1528', '1535', '1555', '1572', '1574', '1582', '1583', '1597', '1599', '1624', '1637',
         '1655', '1667', '1668', '1679', '1720', '1735', '1760', '1762', '1789', '1796', '1802', '1830', '1842', '1844',
         '1846', '1878', '1882', '1884', '1885', '1888', '1890', '1897', '1932', '1933', '1944', '1989', '1995', '2000',
         '2010', '2048', '2049', '2060', '2078', '2121', '2139', '2144', '2155', '2187', '2195', '2212', '2232', '2237',
         '2285', '2299', '2345', '2501', '2502', '2503', '2504', '2507', '2509', '2510', '2511', '2514', '2516', '2521',
         '2549', '2737', '3134', '3385', '4460', '4746', '4752', '5885', '6014', '6023', '6072', '6213', '6699', '8880',
         '9143', '19502', '20359')) OR "brands"."manufacturerId" IS NULL)
  AND "brands"."brandId" IS NULL;
SELECT "coreProduct"."id",
       "coreProduct"."title",
       "coreProduct"."image",
       "coreProduct"."secondaryImages",
       "coreProduct"."bundled",
       "coreProduct"."disabled",
       "coreProduct"."eanIssues",
       "coreProduct"."productOptions",
       "coreProduct"."reviewed",
       "coreProduct"."brandId",
       "coreProduct"."categoryId",
       COUNT("coreRetailers->reviews"."id")                           AS "reviewCount",
       CAST(AVG("coreRetailers->reviews"."rating") AS NUMERIC(10, 2)) AS "avgRating",
       MAX("coreRetailers->reviews"."date")                           AS "recentReview",
       MIN("coreRetailers->reviews"."date")                           AS "firstReview",
       "countryData"."title"                                          AS "countryData.title",
       "countryData"."image"                                          AS "countryData.image",
       "coreRetailers"."id"                                           AS "coreRetailers.id",
       "coreRetailers"."coreProductId"                                AS "coreRetailers.coreProductId",
       "coreRetailers"."retailerId"                                   AS "coreRetailers.retailerId",
       "coreRetailers"."productId"                                    AS "coreRetailers.productId",
       "coreRetailers->retailer"."id"                                 AS "coreRetailers.retailer.id",
       "coreRetailers->retailer"."name"                               AS "coreRetailers.retailer.name",
       "coreRetailers->retailer"."color"                              AS "coreRetailers.retailer.color",
       "coreRetailers->retailer"."logo"                               AS "coreRetailers.retailer.logo",
       "coreRetailers->retailer"."countryId"                          AS "coreRetailers.retailer.countryId",
       "productBrand"."id"                                            AS "productBrand.id",
       "productBrand"."name"                                          AS "productBrand.name",
       "productBrand"."checkList"                                     AS "productBrand.checkList",
       "productBrand"."color"                                         AS "productBrand.color",
       "productBrand"."manufacturerId"                                AS "productBrand.manufacturerId",
       "productBrand"."brandId"                                       AS "productBrand.brandId"
FROM "coreProducts" AS "coreProduct"
         LEFT OUTER JOIN "coreProductCountryData" AS "countryData"
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = 1
         INNER JOIN "coreRetailers" AS "coreRetailers" ON "coreProduct"."id" = "coreRetailers"."coreProductId" AND
                                                          "coreRetailers"."retailerId" IN
                                                          ('4', '1', '8', '2', '3', '9', '10', '81')
         LEFT OUTER JOIN "reviews" AS "coreRetailers->reviews"
                         ON "coreRetailers"."id" = "coreRetailers->reviews"."coreRetailerId"
         INNER JOIN "retailers" AS "coreRetailers->retailer"
                    ON "coreRetailers"."retailerId" = "coreRetailers->retailer"."id"
         INNER JOIN "brands" AS "productBrand" ON "coreProduct"."brandId" = "productBrand"."id" AND
                                                  "productBrand"."id" IN
                                                  ('1', '3', '5', '9', '32', '36', '42', '43', '45', '46', '49', '50',
                                                   '61', '66', '76', '93', '96', '103', '117', '123', '133', '141',
                                                   '155', '169', '171', '173', '175', '181', '182', '248', '646',
                                                   '1338', '1342', '1358', '1372', '1376', '1393', '1395', '1396',
                                                   '1397', '1398', '1400', '1403', '4374', '4657', '7569', '7799',
                                                   '7840', '7842', '8520', '8521', '8522', '8530', '8531', '8533',
                                                   '8537', '8581', '8582', '8583', '8588', '8605', '9073', '9331',
                                                   '9332', '9459', '9485', '9565', '9776', '9919', '9930', '9942',
                                                   '9948', '9951', '9988', '10007', '10113', '10114', '10157', '10158',
                                                   '10159', '10160', '10161', '10168', '10178', '10180', '10185',
                                                   '10186', '10191', '10194', '10196', '10199', '10216', '10225',
                                                   '10235', '10236', '10242', '10270', '10294', '10303', '10304',
                                                   '10305', '10308', '10309', '10310', '10312', '10315', '10317',
                                                   '10332', '10394', '10408', '10426', '10429', '10440', '10442',
                                                   '10447', '10449', '10460', '10471', '10474', '10489', '10498',
                                                   '10523', '10554', '10555', '10557', '10558', '10560', '10562',
                                                   '10563', '10566', '10569', '10573', '10578', '10581', '10588',
                                                   '10595', '10597', '10598', '10602', '10603', '10604', '10605',
                                                   '10606', '10607', '10612', '10614', '10616', '10619', '10630',
                                                   '10631', '10635', '10636', '10638', '10640', '10645', '10646',
                                                   '10650', '10653', '10654', '10664', '10665', '10680', '10719',
                                                   '10998', '11013', '11023', '11030', '11052', '11062', '11090',
                                                   '11091', '11095', '11194', '11919', '12008', '12010', '12051',
                                                   '12060', '12064', '12170', '12227', '12239', '12382', '12389',
                                                   '12667', '12668', '12669', '12680', '12758', '12768', '12882',
                                                   '12890', '12893', '12894', '12913', '12969', '13016', '13017',
                                                   '13019', '13042', '13091', '13139', '13162', '13194', '13196',
                                                   '13265', '13285', '13322', '13330', '13356', '13370', '13452',
                                                   '13480', '13758', '13786', '13829', '13831', '13921', '13927',
                                                   '13965', '13999', '14001', '14015', '14035', '14059', '14061',
                                                   '14070', '14087', '14130', '14140', '14142', '14143', '14144',
                                                   '14145', '14146', '14148', '14162', '14223', '14254', '14282',
                                                   '14327', '14339', '14342', '14374', '14378', '14415', '14441',
                                                   '14453', '14493', '14511', '14521', '14553', '14565', '14619',
                                                   '14639', '14643', '14692', '14731', '14780', '14792', '14793',
                                                   '14873', '14975', '15051', '15103', '15104', '15105', '15106',
                                                   '15107', '15108', '15109', '15110', '15111', '15112', '15113',
                                                   '15114', '15117', '15120', '15121', '15122', '15125', '15127',
                                                   '15304', '15305', '15306', '15416', '36819', '37013', '37284',
                                                   '37312', '37315', '37316', '37329', '37330', '39159', '39629',
                                                   '39638', '40859', '40877', '40925', '41557', '41562', '41591',
                                                   '41781', '41794', '41799', '41828', '41880', '42073', '42079',
                                                   '42085', '42115', '42222', '42248', '42355', '42357', '42360',
                                                   '42442', '43467', '44574', '44999', '45232', '48821', '55010',
                                                   '56314', '57171', '57172')
         INNER JOIN "manufacturers" AS "productBrand->manufacture"
                    ON "productBrand"."manufacturerId" = "productBrand->manufacture"."id" AND
                       "productBrand->manufacture"."id" IN
                       ('1', '3', '7', '20', '24', '28', '29', '30', '31', '32', '34', '39', '42', '53', '56', '58',
                        '61', '62', '63', '64', '65', '66', '67', '77', '79', '81', '84', '88', '91', '94', '95', '98',
                        '101', '102', '106', '112', '116', '132', '136', '139', '150', '152', '159', '166', '170',
                        '179', '180', '181', '184', '185', '186', '194', '216', '218', '222', '226', '232', '235',
                        '241', '245', '260', '261', '265', '285', '287', '295', '302', '307', '315', '398', '402',
                        '412', '437', '438', '440', '452', '457', '458', '465', '473', '547', '584', '597', '615',
                        '620', '631', '640', '655', '681', '703', '737', '788', '797', '810', '821', '825', '831',
                        '841', '853', '858', '862', '863', '866', '871', '874', '944', '961', '969', '994', '995',
                        '1011', '1012', '1020', '1054', '1082', '1088', '1089', '1132', '1304', '1332', '1343', '1379',
                        '1402', '1429', '1432', '1443', '1445', '1447', '1490', '1503', '1519', '1525', '1528', '1535',
                        '1555', '1572', '1574', '1582', '1583', '1597', '1599', '1624', '1637', '1655', '1667', '1668',
                        '1679', '1720', '1735', '1760', '1762', '1789', '1796', '1802', '1830', '1842', '1844', '1846',
                        '1878', '1882', '1884', '1885', '1888', '1890', '1897', '1932', '1933', '1944', '1989', '1995',
                        '2000', '2010', '2048', '2049', '2060', '2078', '2121', '2139', '2144', '2155', '2187', '2195',
                        '2212', '2232', '2237', '2285', '2299', '2345', '2501', '2502', '2503', '2504', '2507', '2509',
                        '2510', '2511', '2514', '2516', '2521', '2549', '2737', '3134', '3385', '4460', '4746', '4752',
                        '5885', '6014', '6023', '6072', '6213', '6699', '8880', '9143', '19502', '20359')
         INNER JOIN "categories" AS "category" ON "coreProduct"."categoryId" = "category"."id" AND "category"."id" IN
                                                                                                   ('1681', '1682',
                                                                                                    '1683', '1684',
                                                                                                    '1685', '1686',
                                                                                                    '1687', '1688',
                                                                                                    '1689', '1712',
                                                                                                    '1715')
WHERE "coreProduct"."productOptions" = FALSE
  AND "coreProduct"."id" IN ('356', '357')
GROUP BY "coreProduct"."id", "countryData"."id", "coreRetailers"."id", "coreRetailers->retailer"."id",
         "productBrand"."id"
HAVING COUNT("coreRetailers->reviews"."id") >= 0
ORDER BY "avgRating" DESC, "reviewCount" DESC;
SELECT "coreProduct"."id",
       "coreProduct"."title",
       "coreProduct"."image",
       "coreProduct"."secondaryImages",
       "coreProduct"."bundled",
       "coreProduct"."disabled",
       "coreProduct"."eanIssues",
       "coreProduct"."productOptions",
       "coreProduct"."reviewed",
       "coreProduct"."brandId",
       "coreProduct"."categoryId",
       COUNT("coreRetailers->reviews"."id")                           AS "reviewCount",
       CAST(AVG("coreRetailers->reviews"."rating") AS NUMERIC(10, 2)) AS "avgRating",
       MAX("coreRetailers->reviews"."date")                           AS "recentReview",
       MIN("coreRetailers->reviews"."date")                           AS "firstReview",
       "countryData"."title"                                          AS "countryData.title",
       "countryData"."image"                                          AS "countryData.image",
       "coreRetailers"."id"                                           AS "coreRetailers.id",
       "coreRetailers"."coreProductId"                                AS "coreRetailers.coreProductId",
       "coreRetailers"."retailerId"                                   AS "coreRetailers.retailerId",
       "coreRetailers"."productId"                                    AS "coreRetailers.productId",
       "coreRetailers->retailer"."id"                                 AS "coreRetailers.retailer.id",
       "coreRetailers->retailer"."name"                               AS "coreRetailers.retailer.name",
       "coreRetailers->retailer"."color"                              AS "coreRetailers.retailer.color",
       "coreRetailers->retailer"."logo"                               AS "coreRetailers.retailer.logo",
       "coreRetailers->retailer"."countryId"                          AS "coreRetailers.retailer.countryId",
       "productBrand"."id"                                            AS "productBrand.id",
       "productBrand"."name"                                          AS "productBrand.name",
       "productBrand"."checkList"                                     AS "productBrand.checkList",
       "productBrand"."color"                                         AS "productBrand.color",
       "productBrand"."manufacturerId"                                AS "productBrand.manufacturerId",
       "productBrand"."brandId"                                       AS "productBrand.brandId"
FROM "coreProducts" AS "coreProduct"
         LEFT OUTER JOIN "coreProductCountryData" AS "countryData"
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = 1
         INNER JOIN "coreRetailers" AS "coreRetailers" ON "coreProduct"."id" = "coreRetailers"."coreProductId" AND
                                                          "coreRetailers"."retailerId" IN
                                                          ('4', '1', '8', '2', '3', '9', '10', '81')
         LEFT OUTER JOIN "reviews" AS "coreRetailers->reviews"
                         ON "coreRetailers"."id" = "coreRetailers->reviews"."coreRetailerId" AND
                            ("coreRetailers->reviews"."date" >= '2022-09-30 23:00:00.000 +00:00' AND
                             "coreRetailers->reviews"."date" <= '2024-01-01 00:00:00.000 +00:00')
         INNER JOIN "retailers" AS "coreRetailers->retailer"
                    ON "coreRetailers"."retailerId" = "coreRetailers->retailer"."id"
         INNER JOIN "brands" AS "productBrand" ON "coreProduct"."brandId" = "productBrand"."id" AND
                                                  "productBrand"."id" IN
                                                  ('1', '3', '5', '9', '32', '36', '42', '43', '45', '46', '49', '50',
                                                   '61', '66', '76', '93', '96', '103', '117', '123', '133', '141',
                                                   '155', '169', '171', '173', '175', '181', '182', '248', '646',
                                                   '1338', '1342', '1358', '1372', '1376', '1393', '1395', '1396',
                                                   '1397', '1398', '1400', '1403', '4374', '4657', '7569', '7799',
                                                   '7840', '7842', '8520', '8521', '8522', '8530', '8531', '8533',
                                                   '8537', '8581', '8582', '8583', '8588', '8605', '9073', '9331',
                                                   '9332', '9459', '9485', '9565', '9776', '9919', '9930', '9942',
                                                   '9948', '9951', '9988', '10007', '10113', '10114', '10157', '10158',
                                                   '10159', '10160', '10161', '10168', '10178', '10180', '10185',
                                                   '10186', '10191', '10194', '10196', '10199', '10216', '10225',
                                                   '10235', '10236', '10242', '10270', '10294', '10303', '10304',
                                                   '10305', '10308', '10309', '10310', '10312', '10315', '10317',
                                                   '10332', '10394', '10408', '10426', '10429', '10440', '10442',
                                                   '10447', '10449', '10460', '10471', '10474', '10489', '10498',
                                                   '10523', '10554', '10555', '10557', '10558', '10560', '10562',
                                                   '10563', '10566', '10569', '10573', '10578', '10581', '10588',
                                                   '10595', '10597', '10598', '10602', '10603', '10604', '10605',
                                                   '10606', '10607', '10612', '10614', '10616', '10619', '10630',
                                                   '10631', '10635', '10636', '10638', '10640', '10645', '10646',
                                                   '10650', '10653', '10654', '10664', '10665', '10680', '10719',
                                                   '10998', '11013', '11023', '11030', '11052', '11062', '11090',
                                                   '11091', '11095', '11194', '11919', '12008', '12010', '12051',
                                                   '12060', '12064', '12170', '12227', '12239', '12382', '12389',
                                                   '12667', '12668', '12669', '12680', '12758', '12768', '12882',
                                                   '12890', '12893', '12894', '12913', '12969', '13016', '13017',
                                                   '13019', '13042', '13091', '13139', '13162', '13194', '13196',
                                                   '13265', '13285', '13322', '13330', '13356', '13370', '13452',
                                                   '13480', '13758', '13786', '13829', '13831', '13921', '13927',
                                                   '13965', '13999', '14001', '14015', '14035', '14059', '14061',
                                                   '14070', '14087', '14130', '14140', '14142', '14143', '14144',
                                                   '14145', '14146', '14148', '14162', '14223', '14254', '14282',
                                                   '14327', '14339', '14342', '14374', '14378', '14415', '14441',
                                                   '14453', '14493', '14511', '14521', '14553', '14565', '14619',
                                                   '14639', '14643', '14692', '14731', '14780', '14792', '14793',
                                                   '14873', '14975', '15051', '15103', '15104', '15105', '15106',
                                                   '15107', '15108', '15109', '15110', '15111', '15112', '15113',
                                                   '15114', '15117', '15120', '15121', '15122', '15125', '15127',
                                                   '15304', '15305', '15306', '15416', '36819', '37013', '37284',
                                                   '37312', '37315', '37316', '37329', '37330', '39159', '39629',
                                                   '39638', '40859', '40877', '40925', '41557', '41562', '41591',
                                                   '41781', '41794', '41799', '41828', '41880', '42073', '42079',
                                                   '42085', '42115', '42222', '42248', '42355', '42357', '42360',
                                                   '42442', '43467', '44574', '44999', '45232', '48821', '55010',
                                                   '56314', '57171', '57172')
         INNER JOIN "manufacturers" AS "productBrand->manufacture"
                    ON "productBrand"."manufacturerId" = "productBrand->manufacture"."id" AND
                       "productBrand->manufacture"."id" IN
                       ('1', '3', '7', '20', '24', '28', '29', '30', '31', '32', '34', '39', '42', '53', '56', '58',
                        '61', '62', '63', '64', '65', '66', '67', '77', '79', '81', '84', '88', '91', '94', '95', '98',
                        '101', '102', '106', '112', '116', '132', '136', '139', '150', '152', '159', '166', '170',
                        '179', '180', '181', '184', '185', '186', '194', '216', '218', '222', '226', '232', '235',
                        '241', '245', '260', '261', '265', '285', '287', '295', '302', '307', '315', '398', '402',
                        '412', '437', '438', '440', '452', '457', '458', '465', '473', '547', '584', '597', '615',
                        '620', '631', '640', '655', '681', '703', '737', '788', '797', '810', '821', '825', '831',
                        '841', '853', '858', '862', '863', '866', '871', '874', '944', '961', '969', '994', '995',
                        '1011', '1012', '1020', '1054', '1082', '1088', '1089', '1132', '1304', '1332', '1343', '1379',
                        '1402', '1429', '1432', '1443', '1445', '1447', '1490', '1503', '1519', '1525', '1528', '1535',
                        '1555', '1572', '1574', '1582', '1583', '1597', '1599', '1624', '1637', '1655', '1667', '1668',
                        '1679', '1720', '1735', '1760', '1762', '1789', '1796', '1802', '1830', '1842', '1844', '1846',
                        '1878', '1882', '1884', '1885', '1888', '1890', '1897', '1932', '1933', '1944', '1989', '1995',
                        '2000', '2010', '2048', '2049', '2060', '2078', '2121', '2139', '2144', '2155', '2187', '2195',
                        '2212', '2232', '2237', '2285', '2299', '2345', '2501', '2502', '2503', '2504', '2507', '2509',
                        '2510', '2511', '2514', '2516', '2521', '2549', '2737', '3134', '3385', '4460', '4746', '4752',
                        '5885', '6014', '6023', '6072', '6213', '6699', '8880', '9143', '19502', '20359')
         INNER JOIN "categories" AS "category" ON "coreProduct"."categoryId" = "category"."id" AND "category"."id" IN
                                                                                                   ('1681', '1682',
                                                                                                    '1683', '1684',
                                                                                                    '1685', '1686',
                                                                                                    '1687', '1688',
                                                                                                    '1689', '1712',
                                                                                                    '1715')
WHERE "coreProduct"."productOptions" = FALSE
  AND "coreProduct"."id" IN ('356', '357')
GROUP BY "coreProduct"."id", "countryData"."id", "coreRetailers"."id", "coreRetailers->retailer"."id",
         "productBrand"."id"
HAVING COUNT("coreRetailers->reviews"."id") >= 0
ORDER BY "avgRating" DESC, "reviewCount" DESC;
SELECT "coreProduct"."id",
       "coreRetailers->retailer"."name"   AS "retailer",
       "productBrand"."name"              AS "brand",
       "countryData"."title"              AS "productName",
       "coreProduct"."ean",
       "products"."sourceId"              AS "retailerCode",
       "products"."productTitle"          AS "retailerProductName",
       "coreRetailers->reviews"."title"   AS "reviewTitle",
       "coreRetailers->reviews"."comment" AS "reviewComments",
       "coreRetailers->reviews"."rating"  AS "reviewRating",
       "coreRetailers->reviews"."date"    AS "reviewDate"
FROM "coreProducts" AS "coreProduct"
         LEFT OUTER JOIN "coreProductCountryData" AS "countryData"
                         ON "coreProduct"."id" = "countryData"."coreProductId" AND "countryData"."countryId" = 1
         INNER JOIN "coreRetailers" AS "coreRetailers" ON "coreProduct"."id" = "coreRetailers"."coreProductId"
    AND "coreRetailers"."retailerId" IN (4, 1, 8, 2, 3, 9, 10, 81)
         RIGHT OUTER JOIN "reviews" AS "coreRetailers->reviews"
                          ON "coreRetailers"."id" = "coreRetailers->reviews"."coreRetailerId"
         INNER JOIN "retailers" AS "coreRetailers->retailer"
                    ON "coreRetailers"."retailerId" = "coreRetailers->retailer"."id"
         INNER JOIN "brands" AS "productBrand" ON "coreProduct"."brandId" = "productBrand"."id"
         LEFT OUTER JOIN "products" AS "products" ON "coreProduct"."id" = "products"."coreProductId"
         JOIN (SELECT MAX("products"."dateId") AS "lastDateId", "retailerId", "coreProduct"."id" AS "coreProductId"
               FROM "coreProducts" AS "coreProduct"
                        LEFT OUTER JOIN "products" AS "products" ON "coreProduct"."id" = "products"."coreProductId"
                   AND "retailerId" IN (4, 1, 8, 2, 3, 9, 10, 81)
               WHERE "coreProduct"."id" IN (356, 357)
               GROUP BY "retailerId", "coreProduct"."id") AS "lastProduct"
              ON "lastProduct"."lastDateId" = "products"."dateId"
                  AND "lastProduct"."retailerId" = "products"."retailerId"
                  AND "lastProduct"."coreProductId" = "products"."coreProductId"
WHERE "coreProduct"."productOptions" = FALSE
  AND "coreProduct"."id" IN (356, 357)
  AND "coreRetailers->reviews"."date" IS NOT NULL
  AND "coreRetailers"."retailerId" = "products"."retailerId"
ORDER BY "coreRetailers->reviews"."date" DESC