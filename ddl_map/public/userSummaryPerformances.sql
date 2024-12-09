CREATE TABLE "userSummaryPerformances"
(
    id          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES users,
    metrics     jsonb DEFAULT '["price", "promotions", "searchTermsRanking", "locationRanking", "content", "rating", "media", "navigation", "availability", "assortment"]'::jsonb,
    "order"     jsonb DEFAULT '["price", "promotions", "searchTermsRanking", "locationRanking", "content", "rating", "media", "navigation", "availability", "assortment"]'::jsonb,
    retailers   jsonb DEFAULT '[1, 2, 3, 9, 11, 8, 10, 4]'::jsonb,
    goals       jsonb DEFAULT '{"media": {"value": 40}, "price": {"value": 1.2}, "rating": {"value": 4.6}, "content": {"value": 80}, "assortment": {"value": 60}, "navigation": {"value": 45}, "promotions": {"value": 20}, "availability": {"value": 95}, "locationRanking": {"value": 25, "maxRanking": 10}, "searchTermsRanking": {"value": 25, "maxRanking": 10}}'::jsonb,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userSummaryPerformances"
    OWNER TO postgres;

GRANT SELECT ON "userSummaryPerformances" TO bn_ro;

GRANT SELECT ON "userSummaryPerformances" TO bn_ro_role;

GRANT SELECT ON "userSummaryPerformances" TO bn_ro_user1;

GRANT SELECT ON "userSummaryPerformances" TO dejan_user;

