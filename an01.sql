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
FROM staging.productsFull
WHERE "coreProductId" = 2848
  AND "retailerId" = 2;


CREATE INDEX "products_sourceType_index"
    ON staging.productsFull ("sourceType");

CREATE INDEX "products_sourceType_sourceId_index"
    ON staging.productsFull ("sourceType", "sourceId");

