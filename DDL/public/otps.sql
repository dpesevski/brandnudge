CREATE TABLE OTPS
(
    ID          serial
        PRIMARY KEY,
    "userId"    integer,
    OPERATION   varchar(255),
    CODE        varchar(255),
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE OTPS
    OWNER TO POSTGRES;

GRANT SELECT ON OTPS TO BN_RO;

GRANT SELECT ON OTPS TO DEJAN_USER;

