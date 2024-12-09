CREATE FUNCTION "findCoreRetailerId"(_coreproductid integer, _retailerid integer, _productid integer) RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    coreRetailerData int;
BEGIN
     SELECT id into coreRetailerData
     FROM "coreRetailers" where "coreProductId" = _coreProductId
                            and "retailerId" = _retailerId and "productId" = _productId;
     return coreRetailerData;
END
$$;

ALTER FUNCTION "findCoreRetailerId"(integer, integer, integer) OWNER TO postgres;

