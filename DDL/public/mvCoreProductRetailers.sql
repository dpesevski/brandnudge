CREATE MATERIALIZED VIEW "mvCoreProductRetailers" AS
SELECT products."coreProductId"                  AS id,
       products."coreProductId",
       ARRAY_AGG(DISTINCT products."retailerId") AS retailers
FROM products
GROUP BY products."coreProductId";

ALTER MATERIALIZED VIEW "mvCoreProductRetailers" OWNER TO POSTGRES;

CREATE UNIQUE INDEX INDEX_MV_COREPRODUCT_RETAILERS
    ON "mvCoreProductRetailers" (ID);

CREATE UNIQUE INDEX INDEX_MV_COREPRODUCT_RETAILERS_COREPRODUCTID
    ON "mvCoreProductRetailers" ("coreProductId");

GRANT SELECT ON "mvCoreProductRetailers" TO BN_RO;

GRANT SELECT ON "mvCoreProductRetailers" TO DEJAN_USER;

