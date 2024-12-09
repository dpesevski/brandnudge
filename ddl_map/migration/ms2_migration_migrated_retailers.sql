CREATE TABLE migration.ms2_migration_migrated_retailers
(
    "retailerId"    integer NOT NULL
        PRIMARY KEY,
    migration_start timestamp DEFAULT NOW(),
    migration_end   timestamp
);

ALTER TABLE migration.ms2_migration_migrated_retailers
    OWNER TO postgres;

GRANT SELECT ON migration.ms2_migration_migrated_retailers TO bn_ro;

GRANT SELECT ON migration.ms2_migration_migrated_retailers TO dejan_user;

