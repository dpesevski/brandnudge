CREATE TABLE countries
(
    id           serial
        PRIMARY KEY,
    name         varchar(255),
    iso          varchar(255)
        CONSTRAINT country_iso_unique_constraint
            UNIQUE,
    iso3         varchar(255),
    "currencyId" integer
        REFERENCES currencies,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL,
    avatar       varchar(255)
);

ALTER TABLE countries
    OWNER TO postgres;

GRANT SELECT ON countries TO bn_ro;

GRANT SELECT ON countries TO bn_ro_role;

GRANT SELECT ON countries TO bn_ro_user1;

GRANT SELECT ON countries TO dejan_user;

