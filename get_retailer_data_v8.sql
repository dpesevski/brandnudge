CREATE TYPE staging.t_promotion AS
(
    "promoId"     TEXT,
    "startDate"   TIMESTAMP,
    "endDate"     TIMESTAMP,
    "description" TEXT
);

DROP TABLE IF EXISTS staging.retailer_data CASCADE;
CREATE TABLE IF NOT EXISTS staging.retailer_data
(
    retailer               retailers,
    ean                    text,
    date                   date,
    href                   text,
    size                   text,
    "eposId"               text,
    status                 text,
    bundled                boolean,
    category               text,
    featured               boolean,
    features               text,
    multibuy               boolean,
    "sizeUnit"             text,
    "sourceId"             text,
    "inTaxonomy"           boolean,
    "isFeatured"           boolean,
    "pageNumber"           text,
    promotions             staging.t_promotion[],
    screenshot             text,
    "sourceType"           text,
    "taxonomyId"           integer,
    nutritional            text,
    "productInfo"          text,
    "productRank"          integer,
    "categoryType"         text,
    "featuredRank"         integer,
    "productBrand"         text,
    "productImage"         text,
    "productPrice"         double precision,
    "productTitle"         text,
    "reviewsCount"         integer,
    "reviewsStars"         double precision,
    "originalPrice"        double precision,
    "pricePerWeight"       text,
    "productInStock"       boolean,
    "secondaryImages"      boolean,
    "productDescription"   text,
    "productTitleDetail"   text,
    "promotionDescription" text
);


DROP FUNCTION IF EXISTS staging.get_retailer_data_v8;
CREATE OR REPLACE FUNCTION staging.get_retailer_data_v8()
    RETURNS setof staging.retailer_data AS
$$

    var json_result = plv8.execute(
        'SELECT * FROM staging.retailer_daily_data'
    );
    let products=json_result[0].fetched_data.products;

    return products.map(e=> {return {
        retailer:e.retailer,
        ean:e.ean,
        date:e.date,
        href:e.href,
        size:e.size,
        eposId:e.eposId,
        status:e.status,
        bundled:e.bundled,
        category:e.category,
        featured:e.featured,
        features:e.features,
        multibuy:e.multibuy,
        sizeUnit:e.sizeUnit,
        sourceId:e.sourceId,
        inTaxonomy:e.inTaxonomy,
        isFeatured:e.isFeatured,
        pageNumber:e.pageNumber,
        promotions:e.promotions,
        screenshot:e.screenshot,
        sourceType:e.sourceType,
        taxonomyId:e.taxonomyId,
        nutritional:e.nutritional,
        productInfo:e.productInfo,
        productRank:e.productRank,
        categoryType:e.categoryType,
        featuredRank:e.featuredRank,
        productBrand:e.productBrand,
        productImage:e.productImage,
        productPrice:e.productPrice,
        productTitle:e.productTitle,
        reviewsCount:e.reviewsCount,
        reviewsStars:e.reviewsStars,
        originalPrice:e.originalPrice,
        pricePerWeight:e.pricePerWeight,
        productInStock:e.productInStock,
        secondaryImages:e.secondaryImages,
        productDescription:e.productDescription,
        productTitleDetail:e.productTitleDetail,
        promotionDescription:e.promotionDescription
    }});
$$ LANGUAGE plv8;

TRUNCATE staging.retailer_data;
INSERT INTO staging.retailer_data
SELECT *
FROM staging.get_retailer_data_v8();

SELECT retailer_data.*, promotion.*
FROM staging.retailer_data
         CROSS JOIN LATERAL UNNEST(promotions) AS promotion
LIMIT 10;



DROP FUNCTION IF EXISTS staging.get_retailer_data_02_v8;
CREATE OR REPLACE FUNCTION staging.get_retailer_data_02_v8(products jsonb)
    RETURNS setof staging.retailer_data AS
$$
    return products.map(e=> {return {
        retailer:e.retailer,
        ean:e.ean,
        date:e.date,
        href:e.href,
        size:e.size,
        eposId:e.eposId,
        status:e.status,
        bundled:e.bundled,
        category:e.category,
        featured:e.featured,
        features:e.features,
        multibuy:e.multibuy,
        sizeUnit:e.sizeUnit,
        sourceId:e.sourceId,
        inTaxonomy:e.inTaxonomy,
        isFeatured:e.isFeatured,
        pageNumber:e.pageNumber,
        promotions:e.promotions,
        screenshot:e.screenshot,
        sourceType:e.sourceType,
        taxonomyId:e.taxonomyId,
        nutritional:e.nutritional,
        productInfo:e.productInfo,
        productRank:e.productRank,
        categoryType:e.categoryType,
        featuredRank:e.featuredRank,
        productBrand:e.productBrand,
        productImage:e.productImage,
        productPrice:e.productPrice,
        productTitle:e.productTitle,
        reviewsCount:e.reviewsCount,
        reviewsStars:e.reviewsStars,
        originalPrice:e.originalPrice,
        pricePerWeight:e.pricePerWeight,
        productInStock:e.productInStock,
        secondaryImages:e.secondaryImages,
        productDescription:e.productDescription,
        productTitleDetail:e.productTitleDetail,
        promotionDescription:e.promotionDescription
    }});
$$ LANGUAGE plv8;

DROP TABLE IF EXISTS staging.prodv2;
CREATE TABLE staging.prodv2 AS
SELECT product.*
FROM staging.retailer_daily_data11
         CROSS JOIN LATERAL staging.get_retailer_data_02_v8(fetched_data -> 'products') AS product;

SELECT *
FROM staging.prodv2
LIMIT 10;


CREATE TABLE staging.prodv4 AS
SELECT product.*
FROM staging.retailer_daily_data11
         CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(fetched_data -> 'products') AS product;

SELECT *
FROM staging.prodv4
LIMIT 10;


DROP TABLE staging.prodv5;

CREATE TABLE staging.prodv5 AS
SELECT product.*
FROM staging.retailer_daily_data11
         CROSS JOIN LATERAL JSONB_POPULATE_RECORDSET(NULL::staging.retailer_data,
                                                     fetched_data -> 'products') AS product;

