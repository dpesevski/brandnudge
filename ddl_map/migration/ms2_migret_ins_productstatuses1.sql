CREATE TABLE migration.ms2_migret_ins_productstatuses1
(
    id          integer,
    "productId" integer,
    status      text,
    screenshot  varchar(255),
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone,
    load_id     integer
);

ALTER TABLE migration.ms2_migret_ins_productstatuses1
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migret_ins_productstatuses1 TO bn_ro;

GRANT SELECT ON migration.ms2_migret_ins_productstatuses1 TO dejan_user;

