CREATE TABLE brands
(
    id               integer      DEFAULT NEXTVAL('brands_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name             varchar(255),
    "manufacturerId" integer
        REFERENCES manufacturers
            ON DELETE CASCADE,
    "checkList"      varchar(1024),
    "createdAt"      timestamp with time zone                                NOT NULL,
    "updatedAt"      timestamp with time zone                                NOT NULL,
    "brandId"        integer,
    color            varchar(255) DEFAULT '#ffffff'::character varying       NOT NULL
);

ALTER TABLE brands
    OWNER TO postgres;

GRANT SELECT ON brands TO bn_ro;

GRANT SELECT ON brands TO bn_ro_role;

GRANT SELECT ON brands TO bn_ro_user1;

GRANT SELECT ON brands TO dejan_user;

