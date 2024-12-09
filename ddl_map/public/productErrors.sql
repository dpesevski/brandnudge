CREATE TABLE "productErrors"
(
    id           serial
        PRIMARY KEY,
    "retailerId" integer                  NOT NULL,
    type         varchar(255)             NOT NULL,
    resolved     boolean DEFAULT FALSE,
    "createdAt"  timestamp with time zone NOT NULL,
    "updatedAt"  timestamp with time zone NOT NULL
);

ALTER TABLE "productErrors"
    OWNER TO postgres;

