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


alter table "productsData"
    drop constraint "productsData_sourceCategoryId_fkey";

alter table "coreProductSourceCategories"
    drop constraint "coreProductSourceCategories_sourceCategoryId_fkey";

 alter table "companySourceCategories"
    drop constraint "companySourceCategories_sourceCategoryId_fkey";

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


CREATE OR REPLACE FUNCTION "ins_sourceCategories"(  IN "p_name" character varying(255),
                                                     IN "p_type" character varying(255),
                                                     IN "p_createdAt" timestamp WITH TIME ZONE,
                                                     IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                     OUT response "coreProductBarcodes",
                                                     OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "sourceCategories" ("id", "name", "type", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_name", "p_type", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;
alter table public."productsData"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

alter table public."coreProductSourceCategories"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

alter table public."companySourceCategories"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

