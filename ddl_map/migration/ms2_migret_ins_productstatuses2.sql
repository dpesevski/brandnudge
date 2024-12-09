CREATE TABLE migration.ms2_migret_ins_productstatuses2
(
    "productId" integer,
    status      text
);

ALTER TABLE migration.ms2_migret_ins_productstatuses2
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migret_ins_productstatuses2 TO bn_ro;

GRANT SELECT ON migration.ms2_migret_ins_productstatuses2 TO dejan_user;

