CREATE MATERIALIZED VIEW "mvCoreProductRetailers" AS
SELECT products."coreProductId"                  AS id,
       products."coreProductId",
       ARRAY_AGG(DISTINCT products."retailerId") AS retailers
FROM products
GROUP BY products."coreProductId";

ALTER MATERIALIZED VIEW "mvCoreProductRetailers" OWNER TO postgres;

CREATE UNIQUE INDEX index_mv_coreproduct_retailers
    ON "mvCoreProductRetailers" (id);

CREATE UNIQUE INDEX index_mv_coreproduct_retailers_coreproductid
    ON "mvCoreProductRetailers" ("coreProductId");

GRANT SELECT ON "mvCoreProductRetailers" TO bn_ro;

GRANT SELECT ON "mvCoreProductRetailers" TO dejan_user;

