/*
CREATE FUNCTION staging.load_retailer_data(value jsonb) RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN;
END;
$$;
 */

SELECT staging.load_retailer_data('{
  "retailer": "sainsburys",


    {
      "ean": "5000168208749",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-milk-chocolate-433g",
      "size": "435",
      "eposId": "7955636",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "45% Wheat and Wholemeal. No Hydrogenated Vegetable Oil. The Nation''s Favourite. No Artificial Colours or Flavours. Suitable for Vegetarians. The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955636",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[{\"key\":\"Energy (kJ)\",\"value\":\"2078\"},{\"key\":\"(kcal)\",\"value\":\"496\"},{\"key\":\"Fat\",\"value\":\"23.6g\"},{\"key\":\"of which Saturates\",\"value\":\"12.4g\"},{\"key\":\"Carbohydrate\",\"value\":\"62.5g\"},{\"key\":\"of which Sugars\",\"value\":\"28.5g\"},{\"key\":\"Fibre\",\"value\":\"3g\"},{\"key\":\"Protein\",\"value\":\"6.7g\"},{\"key\":\"Salt\",\"value\":\"0.94g\"},{\"key\":\"Typical number of biscuits per pack: 26\",\"value\":\"\"}]",
      "productInfo": "Flour (39%) (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Milk Chocolate (30%) [Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Dried Whey (Milk), Butter Oil (Milk), Vegetable Fats (Palm, Shea), Emulsifiers (Soya Lecithin, E476), Natural Flavouring], Vegetable Oil (Palm), Wholemeal Wheat Flour (9%), Sugar, Glucose-Fructose Syrup, Raising Agents (Sodium Bicarbonate, Malic Acid, Ammonium Bicarbonate), Salt",
      "productRank": 11,
      "categoryType": "search",
      "featuredRank": 11,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955636/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "reviewsCount": "26",
      "reviewsStars": "3.9231",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "Wheatmeal Biscuits Covered in Milk Chocolate",
      "productTitleDetail": "McVitie''s Digestives Milk Chocolate Biscuits 433g",
      "promotionDescription": ""
    },
    {
      "ean": "5000168208763",
      "date": "2024-01-04T00:05:00.015Z",
      "href": "https://www.sainsburys.co.uk/shop/gb/groceries/product/details/mcvities-digestives-dark-chocolate-433g",
      "size": "435",
      "eposId": "7955692",
      "status": "listed",
      "bundled": false,
      "category": "Digestives",
      "featured": false,
      "features": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org",
      "multibuy": false,
      "sizeUnit": "g",
      "sourceId": "7955692",
      "inTaxonomy": false,
      "isFeatured": false,
      "pageNumber": 1,
      "promotions": null,
      "screenshot": "https://s3.eu-central-1.amazonaws.com/bn-production.aws.ranking-screenshots/sainsburys/Digestives/1704326868067",
      "sourceType": "sainsburys",
      "taxonomyId": 197411,
      "nutritional": "[]",
      "productInfo": "",
      "productRank": 12,
      "categoryType": "search",
      "featuredRank": 12,
      "productBrand": "McVitie''s",
      "productImage": "https://assets.sainsburys-groceries.co.uk/gol/7955692/1/2365x2365.jpg",
      "productPrice": "3",
      "productTitle": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "reviewsCount": "14",
      "reviewsStars": "4.6429",
      "originalPrice": "3",
      "pricePerWeight": "69p/100g",
      "productInStock": true,
      "secondaryImages": false,
      "productDescription": "The oil palm products contained in this product have been certified to come from RSPO segregated sources and have been produced to stringent environmental and social criteria. www.rspo.org. McVitie''s golden-baked, crunchy wheat biscuits, topped with a layer of smooth, dark chocolate. McVitie''s Chocolate Digestives are the nation''s favourite biscuits.. Enjoy a little break from the everyday, McVitie''s biscuits are too good not to share.. McVitie''s biscuits are Too Good Not to Share.. Find us at www.mcvities.co.ukwww.123healthybalance.co. By Appointment to Her Majesty The Queen Biscuit Manufacturers United Biscuits (UK) Limited, Hayes",
      "productTitleDetail": "McVitie''s Digestives Dark Chocolate Biscuits 433g",
      "promotionDescription": ""
    }
  ]
}');

