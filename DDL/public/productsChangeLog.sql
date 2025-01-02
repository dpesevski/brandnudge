CREATE TABLE "productsChangeLog"
(
    ID           serial
        PRIMARY KEY,
    "changeType" varchar(255),
    "changeFrom" text,
    "changeTo"   text,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL,
    "productId"  integer,
    "dateIdFrom" integer,
    "dateIdTo"   integer
);

ALTER TABLE "productsChangeLog"
    OWNER TO POSTGRES;

GRANT SELECT ON "productsChangeLog" TO BN_RO;

GRANT SELECT ON "productsChangeLog" TO BN_RO_ROLE;

GRANT SELECT ON "productsChangeLog" TO BN_RO_USER1;

GRANT SELECT ON "productsChangeLog" TO DEJAN_USER;

