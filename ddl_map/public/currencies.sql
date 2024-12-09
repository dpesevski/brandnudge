CREATE TABLE currencies
(
    id          serial
        PRIMARY KEY,
    name        varchar(255),
    iso         varchar(255),
    symbol      varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE currencies
    OWNER TO postgres;

GRANT SELECT ON currencies TO bn_ro;

GRANT SELECT ON currencies TO bn_ro_role;

GRANT SELECT ON currencies TO bn_ro_user1;

GRANT SELECT ON currencies TO dejan_user;

