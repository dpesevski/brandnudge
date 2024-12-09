CREATE TABLE categories
(
    id                integer      DEFAULT NEXTVAL('categories_id_seq'::regclass) NOT NULL
        PRIMARY KEY,
    name              varchar(255)
        CONSTRAINT categories_unique
            UNIQUE,
    "categoryId"      integer
        REFERENCES categories,
    "createdAt"       timestamp with time zone                                    NOT NULL,
    "updatedAt"       timestamp with time zone                                    NOT NULL,
    color             varchar(255) DEFAULT '#ffffff'::character varying           NOT NULL,
    "measurementUnit" varchar(255),
    "pricePer"        varchar(255)
);

ALTER TABLE categories
    OWNER TO postgres;

CREATE INDEX "IND_CATEGORIES_CATEGORY_ID"
    ON categories ("categoryId");

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON "categories_categoryId_fkey" TO postgres;

GRANT SELECT ON "categories_categoryId_fkey" TO bn_ro;

GRANT SELECT ON "categories_categoryId_fkey" TO bn_ro_role;

GRANT SELECT ON "categories_categoryId_fkey" TO bn_ro_user1;

GRANT SELECT ON "categories_categoryId_fkey" TO dejan_user;

GRANT SELECT ON categories TO bn_ro;

GRANT SELECT ON categories TO bn_ro_role;

GRANT SELECT ON categories TO bn_ro_user1;

GRANT SELECT ON categories TO dejan_user;

