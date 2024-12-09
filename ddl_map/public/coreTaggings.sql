CREATE TABLE "coreTaggings"
(
    id          integer DEFAULT NEXTVAL('coretaggings_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name        varchar(255),
    "createdAt" timestamp with time zone                                 NOT NULL,
    "updatedAt" timestamp with time zone                                 NOT NULL
);

ALTER TABLE "coreTaggings"
    OWNER TO postgres;

GRANT SELECT ON "coreTaggings" TO bn_ro;

GRANT SELECT ON "coreTaggings" TO bn_ro_role;

GRANT SELECT ON "coreTaggings" TO bn_ro_user1;

GRANT SELECT ON "coreTaggings" TO dejan_user;

