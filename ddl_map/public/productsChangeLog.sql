CREATE TABLE "productsChangeLog"
(
    id           serial
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
    OWNER TO postgres;

GRANT SELECT ON "productsChangeLog" TO bn_ro;

GRANT SELECT ON "productsChangeLog" TO bn_ro_role;

GRANT SELECT ON "productsChangeLog" TO bn_ro_user1;

GRANT SELECT ON "productsChangeLog" TO dejan_user;

