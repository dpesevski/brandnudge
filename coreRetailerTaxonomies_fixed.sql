DROP TABLE IF EXISTS "_tmp_wrong_coreRetailerTaxonomies";
CREATE TABLE "_tmp_wrong_coreRetailerTaxonomies" AS
WITH all_rec AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY "coreRetailerId", "retailerTaxonomyId" ORDER BY ID) AS rownum
                 FROM "coreRetailerTaxonomies"),
     dup_rec AS (SELECT "coreRetailerId", "retailerTaxonomyId", ARRAY_AGG(id) AS wrong_ids
                 FROM all_rec
                 WHERE rownum != 1
                 GROUP BY 1, 2)
SELECT "coreRetailerId", "retailerTaxonomyId", id, wrong_ids
FROM all_rec
         INNER JOIN dup_rec USING ("coreRetailerId", "retailerTaxonomyId")
WHERE rownum = 1;


DROP TABLE "coreRetailerTaxonomies_fixed";

CREATE TABLE public."coreRetailerTaxonomies_fixed"
(
    id                   serial
        PRIMARY KEY,
    "coreRetailerId"     integer,
    "retailerTaxonomyId" integer,
    "createdAt"          timestamp WITH TIME ZONE NOT NULL,
    "updatedAt"          timestamp WITH TIME ZONE NOT NULL
);



WITH all_rec AS (SELECT id,
                        "coreRetailerId",
                        "retailerTaxonomyId",
                        "createdAt",
                        "updatedAt",
                        ROW_NUMBER() OVER (PARTITION BY "coreRetailerId", "retailerTaxonomyId" ORDER BY ID) AS rownum
                 FROM "coreRetailerTaxonomies")
INSERT
INTO "coreRetailerTaxonomies_fixed" (id, "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt")
SELECT id, "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt"
FROM all_rec
WHERE rownum = 1;



ALTER TABLE "coreRetailerTaxonomies_fixed"
    ADD CONSTRAINT coreRetailerTaxonomies_pk
        UNIQUE ("coreRetailerId", "retailerTaxonomyId");


SELECT *
FROM "coreRetailerTaxonomies_fixed"
WHERE "coreRetailerId" = 3458
  AND "retailerTaxonomyId" = 23357;


CREATE FUNCTION "sel_ins_coreRetailerTaxonomies"("p_coreRetailerId" integer, "p_retailerTaxonomyId" integer,
                                                 OUT response jsonb) RETURNS jsonb
    LANGUAGE plpgsql
AS
$$
BEGIN
    WITH upd AS (
        INSERT INTO public."coreRetailerTaxonomies" (id, "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt")
            VALUES (DEFAULT, "p_coreRetailerId", "p_retailerTaxonomyId", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT ("coreRetailerId", "retailerTaxonomyId")
                DO UPDATE
                    SET "updatedAt" = excluded."updatedAt"
            RETURNING *)
    SELECT JSON_AGG(upd)
    FROM upd;
END
$$;

WITH upd AS (
    INSERT INTO public."coreRetailerTaxonomies_fixed" (id, "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt")
        VALUES (DEFAULT, 3458, 23357, '2021-04-23 04:15:44.380000 +00:00', '2021-04-23 04:15:44.380000 +00:00')
        ON CONFLICT ("coreRetailerId", "retailerTaxonomyId") DO UPDATE SET "updatedAt" = excluded."updatedAt"
        RETURNING *)
SELECT JSON_AGG(upd)
FROM upd;