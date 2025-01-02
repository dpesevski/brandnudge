CREATE TABLE WEIGHTS
(
    ID          integer DEFAULT NEXTVAL('weights_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME        varchar(255),
    VALUE       text,
    "createdAt" timestamp with time zone                            NOT NULL,
    "updatedAt" timestamp with time zone                            NOT NULL,
    "userId"    integer                                             NOT NULL,
    CONSTRAINT "weights_name_userId_unique"
        UNIQUE (NAME, "userId")
);

ALTER TABLE WEIGHTS
    OWNER TO POSTGRES;

GRANT SELECT ON WEIGHTS TO BN_RO;

GRANT SELECT ON WEIGHTS TO BN_RO_ROLE;

GRANT SELECT ON WEIGHTS TO BN_RO_USER1;

GRANT SELECT ON WEIGHTS TO DEJAN_USER;

