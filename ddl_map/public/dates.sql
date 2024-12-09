CREATE TABLE dates
(
    id          serial
        PRIMARY KEY,
    date        timestamp with time zone,
    "createdAt" timestamp with time zone,
    "updatedAt" timestamp with time zone
);

ALTER TABLE dates
    OWNER TO postgres;

CREATE UNIQUE INDEX dates_uq_key
    ON dates (date);

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON dates_pkey TO postgres;

GRANT SELECT ON dates_pkey TO bn_ro;

GRANT SELECT ON dates_pkey TO bn_ro_role;

GRANT SELECT ON dates_pkey TO bn_ro_user1;

GRANT SELECT ON dates_pkey TO dejan_user;

GRANT SELECT ON dates TO bn_ro;

GRANT SELECT ON dates TO bn_ro_role;

GRANT SELECT ON dates TO bn_ro_user1;

GRANT SELECT ON dates TO dejan_user;

