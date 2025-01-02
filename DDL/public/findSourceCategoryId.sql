CREATE FUNCTION "findSourceCategoryId"(_productcategory character varying) RETURNS integer
    LANGUAGE PLPGSQL
AS
$$
DECLARE
    sourceCategory int;
BEGIN
    SELECT id into sourceCategory
    FROM "sourceCategories" where "name" = _productCategory
                           and "type" = 'taxonomy';
    return sourceCategory;
END
$$;

ALTER FUNCTION "findSourceCategoryId"(varchar) OWNER TO POSTGRES;

