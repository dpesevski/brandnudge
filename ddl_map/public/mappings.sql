CREATE TABLE mappings
(
    id          integer DEFAULT NEXTVAL('"asinMappings_id_seq"'::regclass) NOT NULL
        CONSTRAINT "asinMappings_pkey"
            PRIMARY KEY,
    ean         varchar(255)                                               NOT NULL,
    code        varchar(255),
    "createdAt" timestamp with time zone                                   NOT NULL,
    "updatedAt" timestamp with time zone                                   NOT NULL,
    retailer_id integer
        CONSTRAINT "mappings_ retailers___fk"
            REFERENCES retailers
);

ALTER TABLE mappings
    OWNER TO postgres;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "mappings_ retailers___fk" TO postgres;

GRANT SELECT ON "mappings_ retailers___fk" TO bn_ro;

GRANT SELECT ON "mappings_ retailers___fk" TO bn_ro_role;

GRANT SELECT ON "mappings_ retailers___fk" TO bn_ro_user1;

GRANT SELECT ON "mappings_ retailers___fk" TO dejan_user;

GRANT SELECT ON mappings TO bn_ro;

GRANT SELECT ON mappings TO bn_ro_role;

GRANT SELECT ON mappings TO bn_ro_user1;

GRANT SELECT ON mappings TO dejan_user;

