/*  "retailerTaxonomies"    */
/*
    joining retailerTaxonomyStatuses with retailerTaxonomies
    ===================================================================================================

    Every record in retailerTaxonomies relates to exactly one record in retailerTaxonomyStatuses
    It will be practical if the two tables are be joined.
*/
WITH stats AS (SELECT "retailerTaxonomies".id, COUNT("retailerTaxonomyStatuses"."retailerTaxonomyId") AS statuses_count
               FROM "retailerTaxonomies"
                        LEFT OUTER JOIN "retailerTaxonomyStatuses"
                                        ON "retailerTaxonomies".id = "retailerTaxonomyStatuses"."retailerTaxonomyId"
               GROUP BY 1)
SELECT statuses_count, COUNT(*)
FROM stats
GROUP BY 1;

/*  only one record in retailerTaxonomies (id=68143) does not have a related record in retailerTaxonomyStatuses   */
SELECT *
FROM "retailerTaxonomies"
         LEFT OUTER JOIN "retailerTaxonomyStatuses"
                         ON "retailerTaxonomies".id = "retailerTaxonomyStatuses"."retailerTaxonomyId"
WHERE "retailerTaxonomyStatuses"."retailerTaxonomyId" IS NULL;

/*  add retailerTaxonomyStatuses data to retailerTaxonomies    */
ALTER TABLE "retailerTaxonomies"
    ADD banners boolean;

ALTER TABLE "retailerTaxonomies"
    ADD products boolean;

ALTER TABLE "retailerTaxonomies"
    ADD subscription boolean;

UPDATE "retailerTaxonomies"
SET banners="retailerTaxonomyStatuses".banners,
    products="retailerTaxonomyStatuses".products,
    subscription="retailerTaxonomyStatuses".subscription
FROM "retailerTaxonomyStatuses"
WHERE "retailerTaxonomyStatuses"."retailerTaxonomyId" = "retailerTaxonomies".id;

/*  add path    */
CREATE EXTENSION IF NOT EXISTS ltree;

ALTER TABLE "retailerTaxonomies"
    ADD path text;

ALTER TABLE "retailerTaxonomies"
    ADD ltpath ltree;

WITH RECURSIVE txpaths (id, path) AS (SELECT id,
                                             category::text  AS path,
                                             id::text::ltree AS ltpath,
                                             1               AS path_level
                                      FROM "retailerTaxonomies"
                                      WHERE "parentId" IS NULL

                                      UNION ALL

                                      SELECT "retailerTaxonomies".id,
                                             txpaths.path || '\' || category::text           AS path,
                                             txpaths.ltpath || "retailerTaxonomies".id::text AS ltpath,
                                             txpaths.path_level + 1                          AS path_level
                                      FROM "retailerTaxonomies"
                                               INNER JOIN txpaths ON ("retailerTaxonomies"."parentId" = txpaths.id))
UPDATE "retailerTaxonomies"
SET path=txpaths.path,
    ltpath=txpaths.ltpath
FROM txpaths
WHERE txpaths.id = "retailerTaxonomies".id;

CREATE INDEX idx_retailerTaxonomies_ltpath ON "retailerTaxonomies" USING gist (ltpath);

/*  taxonomies  */
/*  add path    */
ALTER TABLE taxonomies
    ADD path text;

ALTER TABLE taxonomies
    ADD ltpath ltree;

WITH RECURSIVE txpaths (id, path) AS (SELECT id,
                                             category::text  AS path,
                                             id::text::ltree AS ltpath,
                                             1               AS path_level
                                      FROM taxonomies
                                      WHERE "taxonomyId" IS NULL

                                      UNION ALL

                                      SELECT taxonomies.id,
                                             txpaths.path || '\' || category::text AS path,
                                             txpaths.ltpath || taxonomies.id::text AS ltpath,
                                             txpaths.path_level + 1                AS path_level
                                      FROM taxonomies
                                               INNER JOIN txpaths ON (taxonomies."taxonomyId" = txpaths.id))
UPDATE taxonomies
SET path=txpaths.path,
    ltpath=txpaths.ltpath
FROM txpaths
WHERE txpaths.id = taxonomies.id;

CREATE INDEX idx_taxonomies_ltpath ON taxonomies USING gist (ltpath);

/*  "taxonomies"/"retailerTaxonomies" with path/ltpath data */
SELECT *
FROM "retailerTaxonomies"
WHERE "retailerId" = 4
ORDER BY ltpath;

SELECT *
FROM "taxonomies"
WHERE retailer = 'amazon'
ORDER BY ltpath;

/*
    "taxonomies" and "taxonomyProducts"
    ============================================================================================

    "taxonomyProducts" relates to taxonomies. As a redundancy, retailer is repeated though is already defined in taxonomies.
    The table links a taxonomyId to a coreProductId.

    "sourceId" here seems unnecessary and adds up to the confusion. "sourceId" contributes to more records for each "coreProductId". It should not relate directly to a taxonomy.
    We may have a table linking all the sourceId to taxonomy, but first we need to have a clear/base table linking all the taxonomies with a coreProduct.
*/


/*  taxonomyProducts
    =============================================================


*/

SELECT "taxonomyId", "coreProductId", retailer, COUNT(*), STRING_AGG(DISTINCT "sourceId", ', ') AS "sourceIds"
FROM "taxonomyProducts"
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

SELECT "coreProductId",
       COUNT(*),
       STRING_AGG(DISTINCT "taxonomyId", ', ') AS "taxonomyIds",
       STRING_AGG(DISTINCT "sourceId", ', ')   AS "sourceIds"
FROM "taxonomyProducts"
GROUP BY 1
ORDER BY COUNT(*);


SELECT *
FROM "taxonomyProducts"
WHERE "taxonomyId" = 618568;


/*  "taxonomies" and "retailerTaxonomies"
    =======================================================================================================================

    "taxonomies" relates to a retailer. "retailerTaxonomies", as the name suggest, also relates to a retailer.
    Both "retailerTaxonomies" and taxonomies try to define taxonomies for a specific retailer.
    "retailerTaxonomies" contains a URL, which points to retailer's website "category" page.
    Looks like "taxonomies" are manually edited, while "retailerTaxonomies" are loaded from retailers directly, like the products.

    Q1: Do we need both "taxonomies" and "retailerTaxonomies"?
*/

/*
    Did not find a way to connect the two tables directly.
    If comparing using "category" and retailer, the found records are created at different times (even years apart).
*/
SELECT *
FROM "retailerTaxonomies"
WHERE category = 'Custard'
  AND "retailerId" = 2;

SELECT *
FROM "taxonomies"
WHERE category = 'Custard'
  AND retailer = 'asda';

/*
    The above queries returns 429 records from taxonomies. Only one in "retailerTaxonomies".
    It looks like there is some bug in code filling data to taxonomies, as the same record is inserted almost every day for the past 3 years.
    This bug is still present as the most recent records are from yesterday.
*/

/*  distribution of time of creation of records in "taxonomies" and "retailerTaxonomies"    */
SELECT TO_CHAR("createdAt", 'YYYY-MM') AS "createdAt", COUNT(*)
FROM "taxonomies"
GROUP BY 1;

SELECT TO_CHAR("createdAt", 'YYYY-MM') AS "createdAt", COUNT(*)
FROM "retailerTaxonomies"
GROUP BY 1;


/*
    taxonomies records have issues with the level and the parent/taxonomyId values. There are additional discrepancies like the number of products with the number of records in "taxonomyProducts".
    "retailerTaxonomies" do not have these issues.
*/
SELECT *
FROM taxonomies
         CROSS JOIN LATERAL (SELECT subpath(ltpath, 0, nlevel(ltpath) - 1) AS parent_taxonomy,
                                    nlevel(ltpath)                         AS level_from_path) AS lat
WHERE level != nlevel(ltpath)
ORDER BY retailer, parent_taxonomy, position;

SELECT *
FROM taxonomies
WHERE "taxonomyId" = 1;

SELECT *
FROM taxonomies
WHERE id = 1;

/*
    parent/taxonomyId values
    there are 5 records in "taxonomies" from retailers "asda" and "sainsburys" having taxonomyId=1. The referenced taxonomy with id=1 is for retailer "tesco".
*/
SELECT parent_txn.retailer, txn.*
FROM taxonomies AS txn
         INNER JOIN taxonomies AS parent_txn ON (txn."taxonomyId" = parent_txn.id)
WHERE parent_txn.retailer != txn.retailer;

/*
    TO DO:  After data is corrected, fix the self-referencing constraint to include the retailer.
            Though there are no issues with the data, the same should be applied also for "retailerTaxonomies".
    =============================================================================================

    ALTER TABLE taxonomies
        ADD CONSTRAINT taxonomies_uq
            UNIQUE (retailer, id);

    ALTER TABLE taxonomies
        DROP CONSTRAINT "taxonomies_taxonomyId_fkey";

    ALTER TABLE taxonomies
        ADD CONSTRAINT taxonomies_taxonomies_fk
            FOREIGN KEY (retailer, "taxonomyId") REFERENCES taxonomies (retailer, id);
*/

/*

There are many records in the retailerTaxonomies which form duplicate trees.
For example, the following query results in 9 records all having same value for the attribute "path":

They are all from same retailer (10-waitrose), and the rest of the attributes are all same including the URL and the new ones from the statuses.
These only differ in the id and the createdAt timestamps.
Thease are all archived now.
Feels like the code which is ingesting the retailer's taxonomies does not always recognise existing ones and re-creates it.*/

SELECT *
FROM "retailerTaxonomies"
WHERE path = 'Baby, Child & Parent\Nappies & Potty Training\15 Kg+ (Size 6)';


WITH paths AS (SELECT path, COUNT(*) AS count
               FROM "retailerTaxonomies"
               GROUP BY path
               HAVING COUNT(*) > 1)
SELECT COUNT(*)
FROM paths 106K/163K;


SELECT "coreProductCountryData"."title",  *
FROM "coreProducts"
         JOIN "coreProductCountryData" ON "coreProducts".id = "coreProductCountryData"."coreProductId"
WHERE "coreProducts".id IN (
                            741198,
                            737278,
                            731744
    )