CREATE TABLE MANUFACTURERS
(
    ID                       integer      DEFAULT NEXTVAL('manufacturers_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME                     varchar(255)
        CONSTRAINT MANUFACTURERS_UNIQUE
            UNIQUE,
    "createdAt"              timestamp with time zone                                       NOT NULL,
    "updatedAt"              timestamp with time zone                                       NOT NULL,
    COLOR                    varchar(255) DEFAULT '#ffffff'::character varying              NOT NULL,
    "isOwnLabelManufacturer" boolean      DEFAULT FALSE
);

ALTER TABLE MANUFACTURERS
    OWNER TO POSTGRES;

GRANT SELECT ON MANUFACTURERS TO BN_RO;

GRANT SELECT ON MANUFACTURERS TO BN_RO_ROLE;

GRANT SELECT ON MANUFACTURERS TO BN_RO_USER1;

GRANT SELECT ON MANUFACTURERS TO DEJAN_USER;

