CREATE TABLE "mappingSuggestions"
(
    id                        serial
        PRIMARY KEY,
    "coreProductId"           integer                  NOT NULL,
    "coreProductProduct"      integer                  NOT NULL,
    "suggestedProductId"      integer                  NOT NULL,
    "suggestedProductProduct" integer                  NOT NULL,
    match                     real                     NOT NULL,
    "matchTitle"              real                     NOT NULL,
    "matchIngredients"        real                     NOT NULL,
    "matchNutritional"        real                     NOT NULL,
    "matchImage"              real                     NOT NULL,
    "createdAt"               timestamp with time zone NOT NULL,
    "updatedAt"               timestamp with time zone NOT NULL,
    "matchWeight"             real,
    "matchPrice"              real,
    CONSTRAINT mapping_suggestions_unique
        UNIQUE ("coreProductId", "coreProductProduct", "suggestedProductId", "suggestedProductProduct")
);

ALTER TABLE "mappingSuggestions"
    OWNER TO postgres;

