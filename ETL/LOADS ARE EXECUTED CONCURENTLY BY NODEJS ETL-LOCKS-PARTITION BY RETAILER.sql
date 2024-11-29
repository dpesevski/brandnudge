SELECT "retailerId", COUNT(*), MIN("createdAt"), MAX("createdAt")
FROM products
WHERE "dateId" = 29980
GROUP BY "retailerId"