CREATE TABLE roles
(
    id           serial
        PRIMARY KEY,
    role_name    varchar(255)             NOT NULL
        CONSTRAINT unique_role_name
            UNIQUE,
    access_pages jsonb DEFAULT '[]'::jsonb,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE roles
    OWNER TO postgres;

GRANT SELECT ON roles TO bn_ro;

GRANT SELECT ON roles TO bn_ro_role;

GRANT SELECT ON roles TO bn_ro_user1;

GRANT SELECT ON roles TO dejan_user;

