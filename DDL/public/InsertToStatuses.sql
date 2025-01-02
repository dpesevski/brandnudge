CREATE FUNCTION "InsertToStatuses"() RETURNS boolean
    LANGUAGE PLPGSQL
AS
$$
DECLARE
    P RECORD;
BEGIN
    FOR P IN SELECT * FROM products
        inner join "productsData" on products.id = "productsData"."productId"
        inner join "coreRetailers" cR on products."coreProductId" = cR."coreProductId"
    where "dateId" >= 4940 and "dateId" <= 5032 and products."retailerId" = 13
        LOOP
            DECLARE
                coreRetailerId int;
                sourceCategoryId int;
                tax int;
            BEGIN
                select "findCoreRetailerId"(
                    P."coreProductId",
                    P."retailerId",
                    P.id) into coreRetailerId;
                select "findSourceCategoryId"(
                               P."category") into sourceCategoryId;
                select id from "retailerTaxonomies" where P."taxonomyId" into tax;
                insert into "coreRetailerDates" ("coreRetailerId", "dateId", "createdAt", "updatedAt")
                VALUES (coreRetailerId, P."dateId", now(), now())
                on conflict do nothing;
                insert into "coreProductSourceCategories" ("coreProductId", "sourceCategoryId", "createdAt", "updatedAt")
                VALUES (P."coreProductId", sourceCategoryId, now(), now())
                on conflict do nothing;
                IF tax then
                    insert into "coreRetailerTaxonomies" ("coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt")
                    VALUES ("coreRetailerId", tax)
                     on conflict do nothing;
                END IF;

            END;
        END LOOP;
    RETURN TRUE;
END
$$;

ALTER FUNCTION "InsertToStatuses"() OWNER TO POSTGRES;

