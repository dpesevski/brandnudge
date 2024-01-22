createProducts
    - ProductService.getCreateProductCommonData
        - new db query db.dates.findOrCreate
        - RetailerService.getRetailerByName
            - new db query CountryService.getCountryByISO
            - new db query db.retailer.findOne
    - ProductService.fetchWaitroseProductEAN
    