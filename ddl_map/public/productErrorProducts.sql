CREATE TABLE "productErrorProducts"
(
    id          serial
        PRIMARY KEY,
    "errorId"   integer                  NOT NULL,
    "productId" integer                  NOT NULL,
    resolved    boolean DEFAULT FALSE    NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);

ALTER TABLE "productErrorProducts"
    OWNER TO postgres;

