CREATE TABLE "mappingSuggestions"
(
    ID                        serial
        PRIMARY KEY,
    "coreProductId"           integer                  NOT NULL,
    "coreProductProduct"      integer                  NOT NULL,
    "suggestedProductId"      integer                  NOT NULL,
    "suggestedProductProduct" integer                  NOT NULL,
    MATCH                     real                     NOT NULL,
    "matchTitle"              real                     NOT NULL,
    "matchIngredients"        real                     NOT NULL,
    "matchNutritional"        real                     NOT NULL,
    "matchImage"              real                     NOT NULL,
    "createdAt"               timestamp with time zone NOT NULL,
    "updatedAt"               timestamp with time zone NOT NULL,
    "matchWeight"             real,
    "matchPrice"              real,
    CONSTRAINT MAPPING_SUGGESTIONS_UNIQUE
        UNIQUE ("coreProductId", "coreProductProduct", "suggestedProductId", "suggestedProductProduct")
);

ALTER TABLE "mappingSuggestions"
    OWNER TO POSTGRES;

GRANT SELECT ON "mappingSuggestions" TO BN_RO;

GRANT SELECT ON "mappingSuggestions" TO BN_RO_ROLE;

GRANT SELECT ON "mappingSuggestions" TO BN_RO_USER1;

GRANT SELECT ON "mappingSuggestions" TO DEJAN_USER;

