CREATE TABLE "coreTaggings"
(
    ID          integer DEFAULT NEXTVAL('coretaggings_id_seq'::REGCLASS) NOT NULL
        PRIMARY KEY,
    NAME        varchar(255),
    "createdAt" timestamp with time zone                                 NOT NULL,
    "updatedAt" timestamp with time zone                                 NOT NULL
);

ALTER TABLE "coreTaggings"
    OWNER TO POSTGRES;

GRANT SELECT ON "coreTaggings" TO BN_RO;

GRANT SELECT ON "coreTaggings" TO BN_RO_ROLE;

GRANT SELECT ON "coreTaggings" TO BN_RO_USER1;

GRANT SELECT ON "coreTaggings" TO DEJAN_USER;

