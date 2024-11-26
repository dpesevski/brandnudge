INSERT INTO test.test_load (load_date, data)
SELECT ((c1::json) #>> '{0, date}')::DATE AS load_date,
       JSON_BUILD_OBJECT('retailer', '{
         "id": 1,
         "name": "tesco",
         "color": "#084995",
         "logo": "https://s3.eu-central-1.amazonaws.com/bn.production.avatars/retailerLogo_tesco",
         "countryId": 1,
         "createdAt": "2019-10-11T09:31:50.947Z",
         "updatedAt": "2023-02-13T13:18:09.922Z"
       }'::json, 'products', c1::json)    AS data
FROM test.products_pp_tesco
WHERE c0 = 'products';

SELECT load_date, created_at
FROM test.test_load;

SELECT staging.load_retailer_data(data, flag)
FROM test.test_load
WHERE load_date = '2024-11-25'

