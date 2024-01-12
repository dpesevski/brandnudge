DROP TABLE IF EXISTS "_tmp_wrong_sourceCategories";
CREATE TABLE "_tmp_wrong_sourceCategories" AS
WITH all_rec AS (SELECT *, ROW_NUMBER() OVER (PARTITION BY NAME, TYPE ORDER BY ID) AS rownum
                 FROM "sourceCategories"),
     dup_rec AS (SELECT NAME, TYPE, ARRAY_AGG(id) AS wrong_ids
                 FROM all_rec
                 WHERE rownum != 1
                 GROUP BY 1, 2)
SELECT name, type, id, wrong_ids
FROM all_rec
         INNER JOIN dup_rec USING (name, type)
WHERE rownum = 1;

CREATE TABLE "_corrected_coreProductSourceCategories" AS
WITH corrections AS (
    UPDATE "coreProductSourceCategories"
        SET "sourceCategoryId" = upd.id
        FROM "_tmp_wrong_sourceCategories" upd
        WHERE "sourceCategoryId" = ANY (wrong_ids)
        RETURNING "coreProductSourceCategories".*)
SELECT *
FROM corrections;



/*  TO DO FROM HERE ON

    1. Can we have the backup _corrected_productsData?
    2. drop the referential FK constraints of the 3 tables to the sourceCategories, before deleting the records
*/



CREATE TABLE "_corrected_productsData" AS
WITH corrections AS (
    UPDATE "productsData"
        SET "sourceCategoryId" = upd.id
        FROM "_tmp_wrong_sourceCategories" upd
        WHERE "sourceCategoryId" = ANY (wrong_ids)
        RETURNING "productsData".*)
SELECT *
FROM corrections;


/*
CREATE TABLE "_corrected_sourceCategories" AS
WITH corrections AS (
    DELETE FROM "sourceCategories"
        USING "_tmp_wrong_sourceCategories" upd
        WHERE id = ANY (wrong_ids)
        RETURNING "sourceCategories".*)
SELECT *
FROM corrections;
*/
CREATE TABLE "_corrected_removed_sourceCategories" AS
SELECT *
FROM "sourceCategories"
WHERE "sourceCategories".id IN
      (756, 703, 4470, 776, 788, 720, 4465, 1820, 535, 497, 606, 404, 766, 4467, 503, 592, 638, 749, 609, 546,
       634, 742, 649, 485, 678, 4472, 458, 752, 696, 4477, 574, 682, 10899, 10900, 10901, 10902);

DELETE
FROM "sourceCategories"
WHERE "sourceCategories".id IN
      (756, 703, 4470, 776, 788, 720, 4465, 1820, 535, 497, 606, 404, 766, 4467, 503, 592, 638, 749, 609, 546,
       634, 742, 649, 485, 678, 4472, 458, 752, 696, 4477, 574, 682, 10899, 10900, 10901, 10902);


ALTER TABLE "sourceCategories"
    ADD CONSTRAINT sourceCategories_pk
        UNIQUE (name, type);



SELECT COUNT(*)
FROM "_corrected_productsData";
SELECT *
FROM "_corrected_coreProductSourceCategories";

/*
/*reccount=0*/
SELECT *
FROM tmp_upd_dup
         INNER JOIN "coreProductSourceCategories" ON "sourceCategoryId" = ANY (wrong_ids);
 */