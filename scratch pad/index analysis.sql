--duplicate indexes
SELECT STRING_AGG(idx::text, ', ')                        AS idx1,
       PG_SIZE_PRETTY(SUM(PG_RELATION_SIZE(idx))::bigint) AS size
FROM (SELECT indexrelid::regclass                                                   AS idx,
             (indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n' ||
              COALESCE(indexprs::text, '') || E'\n' || COALESCE(indpred::text, '')) AS key
      FROM pg_index) sub
GROUP BY key
HAVING COUNT(*) > 1
ORDER BY SUM(PG_RELATION_SIZE(idx)) DESC;

--unused indexes
SELECT *,
       PG_SIZE_PRETTY(PG_RELATION_SIZE(indexrelid::regclass)::bigint) AS size,
       PG_RELATION_SIZE(indexrelid::regclass)::bigint
FROM pg_stat_user_indexes
WHERE idx_scan <1000
ORDER BY PG_RELATION_SIZE(indexrelid::regclass)::bigint DESC;
