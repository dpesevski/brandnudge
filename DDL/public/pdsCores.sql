CREATE TABLE "pdsCores"
(
    ID          integer DEFAULT NEXTVAL('"pdsCores_id_seq"'::REGCLASS) NOT NULL
        PRIMARY KEY,
    SKU         varchar(255),
    RETAILER    varchar(255),
    "createdAt" timestamp with time zone                               NOT NULL,
    "updatedAt" timestamp with time zone                               NOT NULL
);

ALTER TABLE "pdsCores"
    OWNER TO POSTGRES;

GRANT SELECT ON "pdsCores" TO BN_RO;

GRANT SELECT ON "pdsCores" TO BN_RO_ROLE;

GRANT SELECT ON "pdsCores" TO BN_RO_USER1;

GRANT SELECT ON "pdsCores" TO DEJAN_USER;

