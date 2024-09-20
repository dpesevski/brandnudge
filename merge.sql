/*
+---------------------------+-----------+
|table_name                 |is_nullable|
+---------------------------+-----------+
|products                   |NO         |
|taxonomyProducts           |NO         | no uq constraint, but should be enforced to avoid duplicates after a merge.
|productGroupCoreProducts   |YES        | no NOT NULL constraint. no uq constraint, but should be enforced to avoid duplicates after a merge.
|coreProductBarcodes        |YES        | there is no NOT NULL constraint on coreProductId, and no FK to coreProducts. However, the data is ok, and these constraints can be added immediately,
|coreProductSourceCategories|YES        | FK to coreProducts exists as well, add NOT NULL constraint. UQ constraint exist on ("sourceCategoryId", "coreProductId"). When merging, if a record with a ("sourceCategoryId", new "coreProductId") exists, the record being merged should be deleted.
|coreRetailers              |YES        | there is no NOT NULL constraint on coreProductId and no FK to coreProducts. One record relates to non-existing coreProductId(36693). Other then this constraints can be added immediately,
                                          There is UQ on ("coreProductId", "retailerId", "productId"). However, this table should split in 2
                                            - one, keeping the name but with UQ ("coreProductId", "retailerId"), and
                                            - additional one,  a copy of the original, with UQ on ("coreProductId", "retailerId", "productId").
                                          Most of the tables relating to coreRetailers are relating on the coreProduct, not the sourceId(productId).
|coreProductCountryData     |YES        | FK to coreProducts exists as well, add NOT NULL constraint. UQ constraint exist on ("coreProductId", "countryId"). When merging, if a record with a ("countryId", new "coreProductId") exists, the record being merged should be deleted.

NOT included in the updates.
|mappingSuggestions         |NO         | This table has less records than mappingLogs (when counting distinct coreProductId,suggestedProductId)
|coreProductsOverride       |YES        | A small table, only 3 records. Looks like coreRetailers.
|coreProductTaggings        |YES        | An empty table. New feature?
+---------------------------+-----------+
*/

SELECT *
FROM "products";

SELECT *
FROM "coreProductCountryData"
WHERE "coreProductId" IS NULL;

SELECT *
FROM "coreProductCountryData"
         LEFT OUTER JOIN "coreProducts" ON ("coreProducts".id = "coreProductId")
WHERE "coreProducts".id IS NULL;