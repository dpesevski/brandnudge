SELECT "coreProductId", * --584735
FROM products
WHERE "retailerId" = 1
  AND "dateId" = 29980
  --AND "coreProductId" = 1006430;
  AND id = 312672016;

SELECT *
FROM staging.product_status_history
WHERE "productId" = 312672016;


SELECT *
FROM staging.product_status_history
WHERE "retailerId" = 1
  AND "coreProductId" = 1006430
  AND date = '2024-11-29';


SELECT *
FROM "coreProducts"
WHERE id IN (1006430, 584735);
/*
+-------+-------------+-------------------------------+
|id     |ean          |title                          |
+-------+-------------+-------------------------------+
|584735 |5030756007065|Pukka Pies 4 Sausage Rolls 360g|
|1006430|5030756008253|Pukka 4 Sausage Rolls 360g     |
+-------+-------------+-------------------------------+
*/

SELECT *
FROM "coreProductBarcodes"
WHERE "coreProductId" IN (1006430, 584735);
/*
+------+-------------+-------------+
|id    |coreProductId|barcode      |
+------+-------------+-------------+
|184555|584735       |5030756007065|
|640491|584735       |5030756008253|
+------+-------------+-------------+
*/

SELECT *
FROM "coreRetailers"
WHERE "coreProductId" IN (1006430, 584735);

/*
+------+-------------+----------+---------------------------------+---------------------------------+-------+
|id    |coreProductId|retailerId|createdAt                        |updatedAt                        |load_id|
+------+-------------+----------+---------------------------------+---------------------------------+-------+
|677740|1006430      |1         |2024-03-06 12:16:08.940000 +00:00|2024-12-03 20:51:42.614677 +00:00|null   |
|703491|1006430      |9         |2024-04-25 09:12:34.053000 +00:00|2024-04-25 09:12:34.053000 +00:00|null   |
+------+-------------+----------+---------------------------------+---------------------------------+-------+
*/

SELECT "coreRetailerSources".*
FROM "coreRetailers"
         INNER JOIN "coreRetailerSources" ON ("coreRetailerSources"."coreRetailerId" = "coreRetailers".id)
WHERE "coreProductId" = 1006430;
/*
+------+--------------+----------+---------+
|id    |coreRetailerId|retailerId|sourceId |
+------+--------------+----------+---------+
|330780|703491        |9         |598865011|
|41509 |677740        |1         |316554707|
+------+--------------+----------+---------+
*/


SELECT "coreProductId", ean, "sourceId", id, date::date, load_id, *
FROM products
WHERE "retailerId" = 1
  AND "coreProductId" IN (1006430, 584735)
  AND "dateId" >= 29980
ORDER BY load_id;

/*
+-------------+-------------+---------+---------+----------+
|coreProductId|ean          |sourceId |id       |date      |
+-------------+-------------+---------+---------+----------+
|584735       |5030756007065|316554707|312672016|2024-11-29|
|584735       |5030756007065|316554707|313862840|2024-11-30|
|584735       |5030756007065|316554707|314009389|2024-12-01|
|584735       |5030756007065|316554707|314790400|2024-12-02|
|584735       |5030756007065|316554707|315543692|2024-12-03|
|584735       |5030756008253|316554707|316216897|2024-12-04|
+-------------+-------------+---------+---------+----------+

1. sourceId:316554707 links to coreProductid=1006430 in coreRetailers/Sources

2. ean:5030756008253 correctly links to coreProduct:584735 in coreProductBarcodes.
                     However, it also links to the old coreProduct:1006430 in coreProducts

3.
*/


SELECT *
FROM "coreProductCountryData"
WHERE "coreProductId" = 1006430;

SELECT *
FROM "coreRetailerTaxonomies"
WHERE "coreRetailerId" IN (677740, 703491);

SELECT *
FROM "bannersProducts"
WHERE "coreRetailerId" IN (677740, 703491);



SELECT "retailerId", "coreProductId", ean, "sourceId", COUNT(*)
FROM products
WHERE "coreProductId" = 584735
GROUP BY "retailerId", "coreProductId", ean, "sourceId";
/*
+----------+-------------+-------------+-------------+-----+
|retailerId|coreProductId|ean          |sourceId     |count|
+----------+-------------+-------------+-------------+-----+
|1         |584735       |5030756007065|316554707    |273  |
|1         |584735       |5030756008253|316554707    |2    |
|1         |584735       |5030756007065|312343981    |485  |
|2         |584735       |5030756007065|1000383116881|45   |
|9         |584735       |5030756007065|112907563    |68   |
|9         |584735       |5030756007065|598865011    |677  |
|11        |584735       |5030756007065|94213        |180  |
+----------+-------------+-------------+-------------+-----+
*/

