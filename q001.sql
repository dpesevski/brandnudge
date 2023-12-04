SELECT -- Identifying information
       "sourceType"     AS retailer,
       CP1.ean          AS ean,
       P1.date          AS date,
       -- Search term information
       category         AS search_term,
       "productRank"    AS rank_organic,
       "featuredRank"   AS rank_sponsored,
       -- Search term information (created and updated metadata)
       "featured"       AS is_sponsored,
       -- Boolean promotion and availability information
       promotions       AS is_promoted,
       "productInStock" AS is_available,
       -- Price information
       "shelfPrice"     AS price_shelf,
       "promotedPrice"  AS price_promoted,
       "basePrice"      AS price_base,
       -- Review information
       "reviewsCount"   AS reviews_count,
       "reviewsStars"   AS reviews_stars,
       -- Display information
       "productTitle"   AS product_title,
       "productImage"   AS image,
       --"productDescription"   AS product_description,
       B1.name          AS product_brand,
       M1.name          AS manufacturer_name


FROM "productsData" AS PD1
         INNER JOIN "productStatuses" AS PS1 ON PD1."productId" = PS1."productId"
         INNER JOIN "products" AS P1 ON PD1."productId" = P1.id
         INNER JOIN "sourceCategories" AS S1 ON PD1."sourceCategoryId" = S1.id
         INNER JOIN "dates" AS D1 ON P1."dateId" = D1.id
         INNER JOIN "coreProducts" AS CP1 ON P1."coreProductId" = CP1.id
         INNER JOIN "brands" AS B1 ON CP1."brandId" = B1.id
         INNER JOIN "manufacturers" AS M1 ON B1."manufacturerId" = M1.id
         INNER JOIN "retailers" AS R1 ON P1."retailerId" = R1.id

WHERE PD1."categoryType" = 'search'
  AND PS1."status" != 'de-listed'
  AND LOWER(PD1.category) IN
      ('coffee', 'ground coffee', 'coffee beans', 'tea', 'tea bags', 'teabags', 'decaf tea', 'decaf coffee')
  AND "sourceType" IN ('ocado', 'asda', 'tesco', 'waitrose', 'morrisons', 'sainsburys', 'coop')
  AND P1.date >= '2023-11-01'
  AND P1.date < '2023-12-01';
