CREATE TABLE otps
(
    id          serial
        PRIMARY KEY,
    "userId"    integer,
    operation   varchar(255),
    code        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE otps
    OWNER TO postgres;

GRANT SELECT ON otps TO bn_ro;

GRANT SELECT ON otps TO dejan_user;

