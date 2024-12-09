CREATE TABLE migration.migret_ins_productstatuses2
(
    "productId" integer,
    status      text
);

ALTER TABLE migration.migret_ins_productstatuses2
    OWNER TO postgres;

GRANT SELECT ON migration.migret_ins_productstatuses2 TO bn_ro;

GRANT SELECT ON migration.migret_ins_productstatuses2 TO dejan_user;

