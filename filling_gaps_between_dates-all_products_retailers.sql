WITH query_base AS (SELECT "coreProductId",
                           "retailerId",

                           date::date,

                           "reviewsCount",
                           "reviewsStars"
                    FROM products),
     query_calendar AS (SELECT DATE_TRUNC('day', dd):: date AS date
                        FROM (SELECT MIN(date::timestamp) AS start_date, MAX(date::timestamp) AS end_date
                              FROM query_base) AS active_period
                                 CROSS JOIN LATERAL GENERATE_SERIES(start_date, end_date, '1 day'::interval) dd),
     query_ext AS (SELECT "coreProductId",
                          "retailerId",

                          date,

                          "reviewsCount",
                          "reviewsStars",
                          SUM(CASE WHEN query_base.date IS NOT NULL THEN 1 END)
                          OVER ( PARTITION BY "coreProductId", "retailerId" ORDER BY date) AS group_id
                   FROM query_calendar
                            LEFT OUTER JOIN query_base USING (date)),
     query_result AS (SELECT "coreProductId",
                             "retailerId",

                             date,
                             FIRST_VALUE("reviewsCount")
                             OVER (PARTITION BY "coreProductId", "retailerId",group_id) AS "reviewsCount",
                             FIRST_VALUE("reviewsStars")
                             OVER (PARTITION BY "coreProductId", "retailerId",group_id) AS "reviewsStars"
                      FROM query_ext)
SELECT *
FROM query_result
WHERE "coreProductId" = 593665
  AND "retailerId" = 8
  AND date BETWEEN '2024-02-01' AND '2024-03-15'
ORDER BY DATE DESC
