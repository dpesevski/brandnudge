CREATE TABLE "userSummaryPerformances"
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer
        REFERENCES USERS,
    METRICS     JSONB DEFAULT '["price", "promotions", "searchTermsRanking", "locationRanking", "content", "rating", "media", "navigation", "availability", "assortment"]'::JSONB,
    "order"     JSONB DEFAULT '["price", "promotions", "searchTermsRanking", "locationRanking", "content", "rating", "media", "navigation", "availability", "assortment"]'::JSONB,
    RETAILERS   JSONB DEFAULT '[1, 2, 3, 9, 11, 8, 10, 4]'::JSONB,
    GOALS       JSONB DEFAULT '{"media": {"value": 40}, "price": {"value": 1.2}, "rating": {"value": 4.6}, "content": {"value": 80}, "assortment": {"value": 60}, "navigation": {"value": 45}, "promotions": {"value": 20}, "availability": {"value": 95}, "locationRanking": {"value": 25, "maxRanking": 10}, "searchTermsRanking": {"value": 25, "maxRanking": 10}}'::JSONB,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "userSummaryPerformances"
    OWNER TO POSTGRES;

GRANT SELECT ON "userSummaryPerformances" TO BN_RO;

GRANT SELECT ON "userSummaryPerformances" TO BN_RO_ROLE;

GRANT SELECT ON "userSummaryPerformances" TO BN_RO_USER1;

GRANT SELECT ON "userSummaryPerformances" TO DEJAN_USER;

