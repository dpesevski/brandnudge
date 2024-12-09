CREATE TABLE sections
(
    id          serial
        PRIMARY KEY,
    name        varchar(255)
        UNIQUE,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    title       varchar(255)
);

ALTER TABLE sections
    OWNER TO postgres;

GRANT SELECT ON sections TO bn_ro;

GRANT SELECT ON sections TO bn_ro_role;

GRANT SELECT ON sections TO bn_ro_user1;

GRANT SELECT ON sections TO dejan_user;

