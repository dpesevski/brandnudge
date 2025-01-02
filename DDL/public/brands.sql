CREATE TABLE BRANDS
(
    ID               integer      DEFAULT NEXTVAL('brands_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME             varchar(255),
    "manufacturerId" integer
        REFERENCES MANUFACTURERS
            ON DELETE CASCADE,
    "checkList"      varchar(1024),
    "createdAt"      timestamp with time zone                                NOT NULL,
    "updatedAt"      timestamp with time zone                                NOT NULL,
    "brandId"        integer,
    COLOR            varchar(255) DEFAULT '#ffffff'::character varying       NOT NULL
);

ALTER TABLE BRANDS
    OWNER TO POSTGRES;

GRANT SELECT ON BRANDS TO BN_RO;

GRANT SELECT ON BRANDS TO BN_RO_ROLE;

GRANT SELECT ON BRANDS TO BN_RO_USER1;

GRANT SELECT ON BRANDS TO DEJAN_USER;

