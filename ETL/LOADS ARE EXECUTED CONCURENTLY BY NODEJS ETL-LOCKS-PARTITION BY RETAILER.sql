SELECT "retailerId", COUNT(*), MIN("createdAt"), MAX("createdAt")
FROM products
WHERE "dateId" = 29980
GROUP BY "retailerId";


/*  other notes
    1. productStatuss FK to products is expensive. Both to check if productId exist there


*/