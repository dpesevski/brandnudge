CREATE TABLE "pdsCores"
(
    id          integer DEFAULT NEXTVAL('"pdsCores_id_seq"'::regclass) NOT NULL
        PRIMARY KEY,
    sku         varchar(255),
    retailer    varchar(255),
    "createdAt" timestamp with time zone                               NOT NULL,
    "updatedAt" timestamp with time zone                               NOT NULL
);

ALTER TABLE "pdsCores"
    OWNER TO postgres;

