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
SELECT "coreProductSourceCategories".*
FROM "coreProductSourceCategories"
         INNER JOIN "_tmp_wrong_sourceCategories" upd
                    ON ("sourceCategoryId" = ANY (wrong_ids));

UPDATE "coreProductSourceCategories"
SET "sourceCategoryId" = upd.id
FROM "_tmp_wrong_sourceCategories" upd
WHERE "sourceCategoryId" = ANY (wrong_ids);

CREATE TABLE "_corrected_productsData" AS
SELECT "productsData".*
FROM "productsData"
         INNER JOIN "_tmp_wrong_sourceCategories" upd
                    ON ("sourceCategoryId" = ANY (wrong_ids));

WITH upd AS (SELECT "_corrected_productsData".id, "_tmp_wrong_sourceCategories".id AS "sourceCategoryId"
             FROM "_corrected_productsData"
                      INNER JOIN "_tmp_wrong_sourceCategories" ON ("sourceCategoryId" = ANY (wrong_ids)))
UPDATE "productsData"
SET "sourceCategoryId" = upd."sourceCategoryId"
FROM upd
WHERE "productsData".id = upd.id;


ALTER TABLE "productsData"
    DROP CONSTRAINT "productsData_sourceCategoryId_fkey";

ALTER TABLE "coreProductSourceCategories"
    DROP CONSTRAINT "coreProductSourceCategories_sourceCategoryId_fkey";

ALTER TABLE "companySourceCategories"
    DROP CONSTRAINT "companySourceCategories_sourceCategoryId_fkey";

CREATE TABLE "_corrected_sourceCategories" AS
WITH corrections AS (
    DELETE FROM "sourceCategories"
        USING "_tmp_wrong_sourceCategories" upd
        WHERE "sourceCategories".id = ANY (wrong_ids)
        RETURNING "sourceCategories".*)
SELECT *
FROM corrections;

ALTER TABLE "sourceCategories"
    ADD CONSTRAINT sourceCategories_pk
        UNIQUE (name, type);


ALTER TABLE public."productsData"
    ADD FOREIGN KEY ("sourceCategoryId") REFERENCES public."sourceCategories";

ALTER TABLE public."coreProductSourceCategories"
    ADD FOREIGN KEY ("sourceCategoryId") REFERENCES public."sourceCategories";

ALTER TABLE public."companySourceCategories"
    ADD FOREIGN KEY ("sourceCategoryId") REFERENCES public."sourceCategories";

