SELECT "sourceType",
       ean,
       "sourceId",
       "productBrand",
       "productTitle",
       "eposId",
       "coreProductId",
       "retailerId",
       "createdAt",
       "updatedAt",
       ROW_NUMBER() OVER (PARTITION BY "coreProductId",
           "retailerId" ORDER BY date DESC) AS row_num
FROM temp.products
WHERE "coreProductId" = 2848
  AND "retailerId" = 2;


CREATE INDEX "products_sourceType_index"
    ON temp.products ("sourceType");

CREATE INDEX "products_sourceType_sourceId_index"
    ON temp.products ("sourceType", "sourceId");

