SELECT *
FROM dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT *
FROM prod_fdw.dates
WHERE id > 24436
ORDER BY "createdAt" DESC NULLS LAST;

SELECT COUNT(*)
FROM products
WHERE "dateId" > 24436;

SELECT COUNT(*)
FROM prod_fdw.products
WHERE "dateId" > 24436;