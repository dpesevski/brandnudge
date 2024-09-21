CREATE EXTENSION IF NOT EXISTS ltree;

/*  taxonomies  */
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

/*  "retailerTaxonomies"    */
ALTER TABLE "retailerTaxonomies"
    ADD banners boolean;

ALTER TABLE "retailerTaxonomies"
    ADD products boolean;

ALTER TABLE "retailerTaxonomies"
    ADD subscription boolean;

ALTER TABLE "retailerTaxonomies"
    ADD path text;

ALTER TABLE "retailerTaxonomies"
    ADD ltpath ltree;

UPDATE "retailerTaxonomies"
SET banners="retailerTaxonomyStatuses".banners,
    products="retailerTaxonomyStatuses".products,
    subscription="retailerTaxonomyStatuses".subscription
FROM "retailerTaxonomyStatuses"
WHERE "retailerTaxonomyStatuses"."retailerTaxonomyId" = "retailerTaxonomies".id;

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


SELECT *
FROM taxonomies
         CROSS JOIN LATERAL (SELECT subpath(ltpath, 0, nlevel(ltpath) - 1) AS parent_taxonomy,
                                    nlevel(ltpath)                         AS level_from_path) AS lat
WHERE level != nlevel(ltpath)
ORDER BY retailer, parent_taxonomy, position;

SELECT *
FROM "retailerTaxonomies"
WHERE "retailerId" = 4
ORDER BY ltpath;

SELECT *
FROM "taxonomies"
WHERE retailer = 'amazon' --81
ORDER BY ltpath;


SELECT TO_CHAR("createdAt", 'YYYY-MM') AS "createdAt", COUNT(*)
FROM "taxonomies"
GROUP BY 1;

SELECT TO_CHAR("createdAt", 'YYYY-MM') AS "createdAt", COUNT(*)
FROM "retailerTaxonomies"
GROUP BY 1;
/*
    "taxonomies" relates to a retailer.
    Q1: Why do we need both "taxonomies" and "retailerTaxonomies"?
*/
SELECT *
FROM "taxonomies"
WHERE id = 618568;

/*
    taxonomyProducts relates to a taxonomies. As a redundancy repeats the retailer though is already defined in taxonomies.
    Links a taxonomyId to a coreProductId.

    sourceId here seems like is unnecessary here and adds up to the confusion. It adds more records for each coreProductId. It should not relate directly to a taxonomy.
    We may have a table linking all the sourceId to taxonomy, but first we need to have a clear/base table linking all the taxonomies with a coreProduct.
*/
SELECT *
FROM "taxonomyProducts"
WHERE "taxonomyId" = 618568;


/*
    retailerTaxonomies and taxonomies both try to define taxonomies for a specific retailer

    Did not find a way to connect the two tables.
    When comparing using their "category" (and retailer) the records come up created at different times (event years).
*/
SELECT *
FROM "retailerTaxonomies"
WHERE category = 'Custard'
  AND id = 7072;

SELECT *
FROM "retailerTaxonomyStatuses"
WHERE "retailerTaxonomyId" = 7072;

/*
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