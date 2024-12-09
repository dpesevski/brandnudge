CREATE TABLE migration.mig_prod_stat_multiple_in_same_day
(
    id          integer,
    "productId" integer,
    status      varchar(255),
    screenshot  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    load_id     integer
);

ALTER TABLE migration.mig_prod_stat_multiple_in_same_day
    OWNER TO postgres;

GRANT SELECT ON migration.mig_prod_stat_multiple_in_same_day TO bn_ro;

GRANT SELECT ON migration.mig_prod_stat_multiple_in_same_day TO dejan_user;

