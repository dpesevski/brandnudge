CREATE OR REPLACE FUNCTION "ins_sourceCategories"(IN "p_coreProductId" integer,
                                                     IN "p_barcode" character varying(255),
                                                     IN "p_createdAt" timestamp WITH TIME ZONE,
                                                     IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                     OUT response "coreProductBarcodes",
                                                     OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "sourceCategories" ("id", "coreProductId", "barcode", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreProductId", "p_barcode", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_coreProductBarcodes"(IN "p_coreProductId" integer,
                                                     IN "p_barcode" character varying(255),
                                                     IN "p_createdAt" timestamp WITH TIME ZONE,
                                                     IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                     OUT response "coreProductBarcodes",
                                                     OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "coreProductBarcodes" ("id", "coreProductId", "barcode", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreProductId", "p_barcode", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_coreProductSourceCategories"(IN "p_coreProductId" integer,
                                                             IN "p_sourceCategoryId" integer,
                                                             IN "p_createdAt" timestamp WITH TIME ZONE,
                                                             IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                             OUT response "coreProductSourceCategories",
                                                             OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "coreProductSourceCategories" ("id", "coreProductId", "sourceCategoryId", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreProductId", "p_sourceCategoryId", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_coreRetailerDates"(IN "p_coreRetailerId" integer, IN "p_dateId" integer,
                                                   IN "p_createdAt" timestamp WITH TIME ZONE,
                                                   IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                   OUT response "coreRetailerDates",
                                                   OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "coreRetailerDates" ("id", "coreRetailerId", "dateId", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreRetailerId", "p_dateId", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_coreRetailerTaxonomies"(IN "p_coreRetailerId" integer,
                                                        IN "p_retailerTaxonomyId" integer,
                                                        IN "p_createdAt" timestamp WITH TIME ZONE,
                                                        IN "p_updatedAt" timestamp WITH TIME ZONE,
                                                        OUT response "coreRetailerTaxonomies",
                                                        OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "coreRetailerTaxonomies" ("id", "coreRetailerId", "retailerTaxonomyId", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreRetailerId", "p_retailerTaxonomyId", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_coreRetailers"(IN "p_coreProductId" integer, IN "p_retailerId" integer,
                                               IN "p_productId" character varying(255),
                                               IN "p_createdAt" timestamp WITH TIME ZONE,
                                               IN "p_updatedAt" timestamp WITH TIME ZONE, OUT response "coreRetailers",
                                               OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "coreRetailers" ("id", "coreProductId", "retailerId", "productId", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_coreProductId", "p_retailerId", "p_productId", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_promotions"(IN "p_retailerPromotionId" integer, IN "p_productId" integer,
                                            IN "p_description" text, IN "p_startDate" character varying(255),
                                            IN "p_endDate" character varying(255),
                                            IN "p_createdAt" timestamp WITH TIME ZONE,
                                            IN "p_updatedAt" timestamp WITH TIME ZONE,
                                            IN "p_promoId" character varying(255), OUT response "promotions",
                                            OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "promotions" ("id", "retailerPromotionId", "productId", "description", "startDate", "endDate",
                              "createdAt", "updatedAt", "promoId")
    VALUES (DEFAULT, "p_retailerPromotionId", "p_productId", "p_description", "p_startDate", "p_endDate", "p_createdAt",
            "p_updatedAt", "p_promoId")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "ins_scraperErrors"(IN "p_retailerId" integer, IN "p_type" character varying(255),
                                               IN "p_message" text, IN "p_url" text, IN "p_resolved" boolean,
                                               IN "p_createdAt" timestamp WITH TIME ZONE,
                                               IN "p_updatedAt" timestamp WITH TIME ZONE, OUT response "scraperErrors",
                                               OUT sequelize_caught_exception text) RETURNS RECORD AS
$$
BEGIN
    INSERT INTO "scraperErrors" ("id", "retailerId", "type", "message", "url", "resolved", "createdAt", "updatedAt")
    VALUES (DEFAULT, "p_retailerId", "p_type", "p_message", "p_url", "p_resolved", "p_createdAt", "p_updatedAt")
    RETURNING * INTO response;
EXCEPTION
    WHEN unique_violation THEN GET STACKED DIAGNOSTICS sequelize_caught_exception = PG_EXCEPTION_DETAIL;
END
$$ LANGUAGE plpgsql;
