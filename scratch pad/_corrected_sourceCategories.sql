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


alter table public."productsData"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

alter table public."coreProductSourceCategories"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

alter table public."companySourceCategories"
    add foreign key ("sourceCategoryId") references public."sourceCategories";

