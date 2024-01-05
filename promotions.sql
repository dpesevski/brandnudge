--"retailerPromotionId" /was £([0-9.,]+) now £([0-9.,]+) \(save £([0-9.,]+)\)/i.exec("Was £129 now £115 (Save £14)")

CREATE OR REPLACE FUNCTION public.fn_to_date(value text) RETURNS date
    LANGUAGE plpgsql
AS
$$
BEGIN
    BEGIN
        RETURN value::date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END;
$$;

DROP TABLE IF EXISTS tests.promotions;
CREATE TABLE tests.promotions AS
WITH products AS (SELECT id AS "productId",
                         "coreProductId",
                         "retailerId"
                  FROM products)
SELECT "retailerId",
       ARRAY_AGG(DISTINCT "coreProductId") AS "coreProductId",
       "promoId",
       MIN("promotionMechanicId")          AS promotionMechanicId,
       MIN(description)                    AS description,

       fn_to_date(MIN("startDate"))        AS "startDate",
       fn_to_date(MAX("endDate"))          AS "endDate",

       MIN("createdAt")                    AS "createdAt",
       MAX("updatedAt")                    AS "updatedAt"
FROM promotions
         INNER JOIN products USING ("productId")
         INNER JOIN "retailerPromotions" ON ("retailerPromotionId" = "retailerPromotions".id)
GROUP BY "retailerId",
         "promoId";

DROP TABLE IF EXISTS tests.promotions_issues_w_data;
CREATE TABLE tests.promotions_issues_w_data AS --1.654 records
SELECT *
FROM tests.promotions
WHERE "promoId" IS NULL
   OR description = ''
   OR "endDate" < "startDate";

DELETE
FROM tests.promotions
WHERE "promoId" IS NULL
   OR description = ''
   OR "endDate" < "startDate";


/*  correction of the startDate/endDate null values */

UPDATE tests.promotions
SET "startDate"="createdAt"
WHERE "startDate" IS NULL;


UPDATE tests.promotions
SET "endDate"="updatedAt"
WHERE "endDate" IS NULL;

DROP TABLE IF EXISTS tests.promotions_arch;
CREATE TABLE tests.promotions_arch AS --71.802 records
SELECT *
FROM tests.promotions
WHERE "updatedAt" < '2022-01-01';

DELETE
FROM tests.promotions
WHERE "updatedAt" < '2022-01-01';

DROP TABLE IF EXISTS tests.promotions_expired; --1.236.329
CREATE TABLE tests.promotions_expired AS
SELECT *
FROM tests.promotions
WHERE "endDate" < '2023-12-06'; -- last working day

DELETE
FROM tests.promotions
WHERE "endDate" < '2023-12-06';

ALTER TABLE tests.promotions
    RENAME TO promotions_active;

SELECT COUNT(*) --  30.135 records
FROM tests.promotions_issues_w_data;


CREATE INDEX tests_promotions_expired_coreproductid_index
    ON tests.promotions_expired USING gin ("coreProductId");

ALTER TABLE tests.promotions_expired
    ADD CONSTRAINT test_promotions_expired_pk
        PRIMARY KEY ("retailerId", "promoId");


CREATE INDEX tests_promotions_active_coreproductid_index
    ON tests.promotions_active USING gin ("coreProductId");

ALTER TABLE tests.promotions_active
    ADD CONSTRAINT test_promotions_active_pk
        PRIMARY KEY ("retailerId", "promoId");

CREATE VIEW tests.promotions AS
SELECT *
FROM tests.promotions_active
UNION ALL
SELECT *
FROM tests.promotions_expired;


SELECT *--JSON_AGG(promotions ORDER BY "startDate")
FROM tests.promotions_active AS promotions
WHERE "retailerId" IN (2, 3, 8, 11)
  AND "coreProductId" && ARRAY [48,49,55,57,58]
  AND DATERANGE("startDate", "endDate") && DATERANGE('2023-11-15', '2023-12-04');


SELECT description, COUNT(*)
FROM tests.promotions_w_dates
GROUP BY 1
ORDER BY 2 DESC;


CREATE TABLE tests.tmp_promotionMechanicId AS
SELECT "retailerId",
       "promoId",
       MIN("promotionMechanicId") AS "promotionMechanicId"
FROM promotions
         INNER JOIN "retailerPromotions" ON ("retailerPromotionId" = "retailerPromotions".id)
GROUP BY "retailerId",
         "promoId";

ALTER TABLE tests.promotions_active
    ADD COLUMN "promotionMechanicId" smallint;
ALTER TABLE tests.promotions_arch
    ADD COLUMN "promotionMechanicId" smallint;
ALTER TABLE tests.promotions_expired
    ADD COLUMN "promotionMechanicId" smallint;
ALTER TABLE tests.promotions_issues_w_data
    ADD COLUMN "promotionMechanicId" smallint;
ALTER TABLE tests.promotions_w_dates
    ADD COLUMN "promotionMechanicId" smallint;

UPDATE tests.promotions_active
SET "promotionMechanicId"=upd."promotionMechanicId"
FROM tests.tmp_promotionMechanicId AS upd
WHERE upd."retailerId" = upd."retailerId"
  AND upd."promoId" = upd."promoId";



UPDATE tests.promotions_arch
SET "promotionMechanicId"=upd."promotionMechanicId"
FROM tests.tmp_promotionMechanicId AS upd
WHERE upd."retailerId" = upd."retailerId"
  AND upd."promoId" = upd."promoId";

UPDATE tests.promotions_expired
SET "promotionMechanicId"=upd."promotionMechanicId"
FROM tests.tmp_promotionMechanicId AS upd
WHERE upd."retailerId" = upd."retailerId"
  AND upd."promoId" = upd."promoId";

UPDATE tests.promotions_issues_w_data
SET "promotionMechanicId"=upd."promotionMechanicId"
FROM tests.tmp_promotionMechanicId AS upd
WHERE upd."retailerId" = upd."retailerId"
  AND upd."promoId" = upd."promoId";

UPDATE tests.promotions_w_dates
SET "promotionMechanicId"=upd."promotionMechanicId"
FROM tests.tmp_promotionMechanicId AS upd
WHERE upd."retailerId" = upd."retailerId"
  AND upd."promoId" = upd."promoId";

DROP VIEW IF EXISTS tests.promotions;
CREATE VIEW tests.promotions AS
SELECT *
FROM tests.promotions_active
UNION ALL
SELECT *
FROM tests.promotions_expired;