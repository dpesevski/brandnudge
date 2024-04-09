/*
    reviews table is not indexed by date, and the calculation of the "rank" relies on it.
*/
CREATE INDEX reviews_coreRetailerId_date_index
    ON reviews ("coreRetailerId", date);

/*
    Adding the index on date is already an improvement in performance in the query.
    However, as the rank of the record will drop after every new review record is added, all the related records will need to be updated every time.
    Also, the reviews table usually has more than 10 records per coreRetailerId, so it is practical to consider only the first 10.

    As a further improvement, we can aggregate the top 10 coreRetailer reviews in a single field, so we'll keep a single record per coreRetailer.

    "topReviews" is renamed to "latestReviews" as the query ranks the reviews only by their date.

    This table is to be maintained by the ETL at every load of new reviews data.

*/
DROP TABLE IF EXISTS tests."latestReviews";
CREATE TABLE tests."latestReviews" AS
SELECT *
FROM (SELECT "coreRetailerId",
             "comment",
             "date",
             ROW_NUMBER() OVER (PARTITION BY "coreRetailerId" ORDER BY "date" DESC ) AS rank
      FROM "reviews") "reviews"
WHERE rank <= 10;

CREATE INDEX latestReviews_coreRetailerId_index
    ON tests."latestReviews" ("coreRetailerId");

/*  refactored query using the pre-calculated "latestReviews"   */
SELECT "coreProductId", "latestReviews".*, "retailerId"
FROM "coreRetailers" cr
         JOIN tests."latestReviews"
              ON "latestReviews"."coreRetailerId" = cr."id"
WHERE cr."coreProductId" IN
      (1747, 1754, 1760, 1762, 3461, 3763, 3764, 3769, 3920, 4064, 4251, 4261, 4298, 4299, 4300, 4304, 4314, 4331, 4347,
       4364, 4366, 4368, 4369, 4372, 4373, 4377, 4382, 4383, 4389, 4412, 4483, 4498, 4520, 4553, 4572, 4612, 4657, 4691,
       4752, 5015, 5045, 11256, 11267, 11317, 11533, 11540, 11564, 11566, 11574, 11579, 11583, 11673, 11808, 11817,
       11829, 11921, 11930, 13614, 13616, 14398, 14469, 14835, 14851, 16041, 16546, 16547, 16548, 16615, 16633, 16652,
       16936, 16938, 16953, 17039, 17043, 17048, 17126, 17134, 17138, 17247, 17278, 18202, 18338, 19032, 19041, 19105,
       19186, 19258, 19435, 19615, 19800, 20084, 20307, 20321, 20581, 20589, 20598, 21753, 21806, 22836, 23751, 24269,
       24923, 26148, 26155, 26349, 37325, 37606, 37702, 37852, 38006, 41890, 42148, 42338, 42390, 42763, 42764, 42767,
       42878, 43008, 43532, 43601, 43786, 44662, 44825, 45525, 45536, 45750, 45912, 47514, 47913, 48006, 48131, 49263,
       49482, 49873, 49914, 50051, 50663, 51233, 51237, 51239, 51260, 51975, 52452, 52453, 52635, 56410, 56959, 57995,
       58016, 58474, 58475, 58578, 58581, 59255, 62359, 62361, 62386, 63171, 63173, 63192, 63203, 63215, 64020, 64901,
       65587, 67014, 69967, 70167, 74125, 76954, 76955, 79196, 81836, 82042, 82045, 82046, 82800, 83327, 83328, 83337,
       92045, 92582, 94771, 94772, 94778, 94782, 94783, 94784, 103070, 108155, 108165, 108228, 108248, 120284, 120336,
       240260, 240264, 255140, 277565, 311911, 315407, 315416, 317558, 317559, 317560, 317562, 321983, 332545, 332546,
       332548, 332550, 356295, 364807, 364818, 364819, 364820, 424079, 424080, 442818, 466888, 477357, 477360, 486859,
       486860, 486908, 496581, 519356, 540245, 541845, 541846, 541850, 542649, 543683, 547213, 547214, 547285, 550322,
       561431, 561432, 566210, 566211, 566213, 566220, 572216, 572265, 576465, 577337, 584088, 584093, 592488, 635180,
       641051, 654431, 666866, 674692, 679232, 679234, 724209, 724234, 724238, 729377, 729379, 731701, 737617, 737618,
       737619, 739687, 739689, 739703, 739705, 739706, 739709, 754715, 754745, 754802, 755444, 755445, 757575, 757576,
       763541, 763542, 765926, 772033, 779928, 780436, 781601, 783186, 784964, 784965, 790677, 792356, 793114, 798099,
       849813, 849817, 858776, 859464, 863968, 864092, 864095, 865331, 873953, 873964, 874047, 874485, 875933, 878874,
       879772, 879773, 883576, 883582, 883598, 883631, 884563, 887678, 887679, 888041, 895971, 900955, 901444, 922543,
       922562, 969026, 996120, 998175, 998176)
  AND "retailerId" IN (1, 8, 2, 3, 9, 10, 11, 81);

