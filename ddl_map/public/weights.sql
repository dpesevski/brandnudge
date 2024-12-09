CREATE TABLE weights
(
    id          integer DEFAULT NEXTVAL('weights_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name        varchar(255),
    value       text,
    "createdAt" timestamp with time zone                            NOT NULL,
    "updatedAt" timestamp with time zone                            NOT NULL,
    "userId"    integer                                             NOT NULL,
    CONSTRAINT "weights_name_userId_unique"
        UNIQUE (name, "userId")
);

ALTER TABLE weights
    OWNER TO postgres;

GRANT SELECT ON weights TO bn_ro;

GRANT SELECT ON weights TO bn_ro_role;

GRANT SELECT ON weights TO bn_ro_user1;

GRANT SELECT ON weights TO dejan_user;

