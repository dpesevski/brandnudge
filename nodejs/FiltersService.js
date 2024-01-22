//MainFilters
export default class FiltersService extends Service {
  static dateFormat = 'YYYY-MM-DD';
  static setTimePeriodByNumber(filters, filtersStartDate) {
    if (typeof filters.timePeriod === 'number' || !isNaN(filters.timePeriod)) {
      const to = moment().subtract(1, 'days');
      const from = moment().subtract(+filters.timePeriod + 1, 'days');
      filters.timePeriod = `custom|${from.format(
        FiltersService.dateFormat,
      )}|${to.format(FiltersService.dateFormat)}`;
    } else {
      const customTimePeriod = filters.timePeriod.split('|');
      if (customTimePeriod.length > 3 && customTimePeriod[3] === 'ytd') {
        filters.timePeriod = `custom|${moment(
          `${moment().year()}-01-01`,
        ).format(FiltersService.dateFormat)}|${moment().subtract(1, 'days').format(
          FiltersService.dateFormat,
        )}|ytd`;
      } else if (customTimePeriod.length > 3 && customTimePeriod[3] === 'ful') {
        const startDate = filtersStartDate || `${moment().year()}-01-01`;
        filters.timePeriod = `custom|${moment(startDate).format(FiltersService.dateFormat)}|${moment().subtract(1, 'days').format(
          FiltersService.dateFormat,
        )}|ful`;
      }
    }
    return filters;
  }

  /**
   * Select manufacturers and brands
   * @param condition
   * @returns {Promise<{brands: [], manufacturers: []}>}
   */
  static async getManufacturersAndBrands(condition) {
    const manufacturersAndBrands = await db.manufacturer.findAll(condition);
    const manufacturers = [];
    const brands = [];
    const parentBrands = {};
    const usedParentBrands = new Set();
    for (const manufacturer of manufacturersAndBrands) {
      manufacturers.push({
        id: manufacturer.id,
        name: manufacturer.name,
        color: manufacturer.color,
      });
      for (const brand of manufacturer.brands) {
        const brandData = {
          id: brand.id,
          name: brand.name,
          color: brand.color,
          manufacturerId: brand.manufacturerId,
          brandId: brand.brandId,
          child: brand.child.map(item => item.toJSON()),
        };
        brands.push(brandData);
        usedParentBrands.add(brand.id);

        if (brand.parent) {
          if (!parentBrands[brand.parent.id]) {
            parentBrands[brand.parent.id] = {
              id: brand.parent.id,
              name: brand.parent.name,
              color: brand.parent.color,
              manufacturerId: brand.parent.manufacturerId,
              child: [],
            };
          }
          parentBrands[brand.parent.id].child.push(brandData);
          // parentBrands[brand.parent.id].child[brand.id] = brandData;
        }
      }
    }
    for (const parentBrand of Object.values(parentBrands)) {
      if (!usedParentBrands.has(parentBrand.id)) {
        brands.push(parentBrand);
      }
    }
    return { brands, manufacturers };
  }

  /**
   * Format user last filter before saving
   * @param data
   * @param filteredData
   * @returns {{}}
   */
  static formatUserLastFilter(data, filteredData) {
    const namesMap = {
      sourceType: 'retailers',
      manufacture: 'manufacturers',
      productBrand: 'brands',
      category: 'categories',
      product: 'products',
      productGroup: 'productGroups',
    };
    const lastFilter = {};
    for (const key of Object.keys(data)) {
      if (key === 'timePeriod' || key === 'newSelected') {
        // eslint-disable-next-line no-continue
        continue;
      }
      if (!namesMap[key]) {
        lastFilter[key] = data[key].join('|');
        // eslint-disable-next-line no-continue
        continue;
      }
      if (
        namesMap[key] === 'productGroups' &&
        (data[key][0] === 'All' || data[key][0] === '')
      ) {
        lastFilter[key] = '';
        // eslint-disable-next-line no-continue
        continue;
      }
      const filteredDataKey = namesMap[key];
      if (data[key][0] === 'All') {
        // if key is all, add to last filter everything from filteredData
        if (Array.isArray(filteredData[filteredDataKey])) {
          lastFilter[key] = filteredData[filteredDataKey].map(({ id }) => id);
        } else {
          lastFilter[key] = Object.keys(filteredData[filteredDataKey]);
        }
      } else {
        let value;
        if (
          data.newSelected &&
          data.newSelected[key] &&
          data.newSelected[key][0] !== 'All'
        ) {
          value = [...data[key], ...data.newSelected[key]];
        } else {
          value = data[key];
        }
        // if key is not all, add to last filter every item received from user
        // that present in filteredData
        if (Array.isArray(filteredData[filteredDataKey])) {
          const set = new Set(
            filteredData[filteredDataKey].map(({ id }) => id),
          );
          lastFilter[key] = value.filter(id => set.has(Number(id)));

          if (lastFilter[key].length < 1) {
            lastFilter[key] = filteredData[filteredDataKey].map(({ id }) => id);
          }
        } else {
          const items = filteredData[filteredDataKey];
          lastFilter[key] = value.filter(id => !!items[id]);

          if (lastFilter[key].length < 1) {
            lastFilter[key] = Object.keys(items);
          }
        }
      }
      // remove all duplicates
      lastFilter[key] = [...new Set(lastFilter[key])].join('|');
    }
    return lastFilter;
  }

  /**
   * Get months for last year, starting from previous month this year
   * to same month in the previous year
   * @param monthsInDb
   * @returns {[]}
   */
  static getMonthsForFilters(monthsInDb, companyPossibleOldestDate) {
    const monthsInDbSet = new Set(
      monthsInDb.map(item => {
        const monthDate = moment(item.month);
        return `${monthDate.get('year')}-${monthDate.get('month') + 1}`;
      }),
    );

    const months = {
      6: { id: 7, name: 'Jul' },
      5: { id: 8, name: 'Jun' },
      4: { id: 9, name: 'May' },
      3: { id: 10, name: 'Apr' },
      2: { id: 12, name: 'Mar' },
      1: { id: 13, name: 'Feb' },
      0: { id: 14, name: 'Jan' },
      11: { id: 15, name: 'Dec' },
      10: { id: 16, name: 'Nov' },
      9: { id: 17, name: 'Oct' },
      8: { id: 18, name: 'Sep' },
      7: { id: 19, name: 'Aug' },
    };
    let date = moment().startOf('month');
    const startMonthNumber = date.month();
    let monthNumber = startMonthNumber + 1;

    const preparedMonths = [];
    while (monthNumber !== startMonthNumber) {
      date = date.subtract(1, 'month');
      monthNumber = date.month();
      if (date.isAfter(companyPossibleOldestDate)) {
        preparedMonths.push(months[monthNumber]);
      } else {
        break;
      }
    }
    return preparedMonths;
  }

  /**
   * Returns possible relatives dates
   * @param companyPossibleOldestDate
   * @returns {[]}
   */
  static getRelativeDatesForFilters(companyPossibleOldestDate) {
    const relatives = [
      { id: 2, name: 'Yesterday', subtract: 1 },
      { id: 3, name: 'Last 7 days', subtract: 7 },
      { id: 4, name: 'Last 14 days', subtract: 14 },
      { id: 5, name: 'Last 30 days', subtract: 30 },
      { id: 6, name: 'Last 90 days', subtract: 90 },
      { id: 90, name: 'Last 365 days', subtract: 365 },
      {
        id: 91,
        name: 'Year To Date',
        subtract: moment().diff(moment(`${moment().year()}-01-01`), 'days'),
      },
    ];

    const output = [];
    const now = moment().startOf('day');
    for (const { id, name, subtract } of relatives) {
      if (
        now
          .clone()
          .subtract(subtract, 'day')
          .isAfter(companyPossibleOldestDate)
      ) {
        output.push({ id, name });
      }
    }
    return output;
  }

  /**
   * Calculate years that user can see in filters
   * @param monthsInDb
   * @param companyPossibleOldestDate
   * @returns {[]}
   */
  static getYearsForFilters(monthsInDb, companyPossibleOldestDate) {
    const copyMonthsInDb = [...monthsInDb];
    copyMonthsInDb.sort((a, b) => {
      const aMonth = moment(a.month);
      const bMonth = moment(b.month);
      return bMonth.isBefore(aMonth) ? 1 : -1;
    });

    const years = [];
    const yearsDate = moment(copyMonthsInDb[0].month).startOf('year');
    const now = moment.now();
    // i = 20 because years ids in filters start from 20
    for (let i = 20; yearsDate.isSameOrBefore(now); i += 1) {
      if (companyPossibleOldestDate.isSameOrBefore(yearsDate)) {
        years.push({
          id: i,
          name: yearsDate.format('YYYY'),
        });
      }
      yearsDate.add(1, 'year');
    }

    years.sort((a, b) => b.name - a.name);
    return years;
  }

  /**
   * Prepare filers object v2
   * @param user
   * @param data
   * @param shouldSave - save filters to users last filter
   * @param useWatchlist
   * @returns {Promise<>}
   */
  static async getNewFormattedFilters(user, data, shouldSave, useWatchlist) {
    const filterData = { ...data };
    let applyWatchlist = user.watchlist || false;
    if (useWatchlist !== undefined && !useWatchlist) applyWatchlist = false;
    const { company, countryId } = user;

    const companyPossibleOldestDate = moment(company.filtersStartDate);
    if (filterData.timePeriod) {
      const timePeriodOldDate = moment(filterData.timePeriod.old);
      if (timePeriodOldDate.isBefore(companyPossibleOldestDate)) {
        filterData.timePeriod.old = companyPossibleOldestDate.format(
          FiltersService.dateFormat,
        );
      }
    }

    const options = {
      removeChildBrands: true,
      filterProducts: false,
      filterByDates: !!filterData.timePeriod,
      watchlistFilter: applyWatchlist ? user.watchlistFilter : false,
    };

    // const keyString =`company${company.id}Filter|country${countryId}|${Buffer.from(JSON.stringify(filterData)).toString('base64')}|${Buffer.from(JSON.stringify(options)).toString('base64')}`;
    // const cacheExists = await RedisUtil.isKeyExists(keyString);
    // let result = !cacheExists ? await this.getNewFilters(user, filterData, options) : await RedisUtil.getData(keyString);
    // if (!cacheExists) RedisUtil.cacheData(keyString, result);
    let result = await this.getNewFilters(user, filterData, options);

    if (
      Object.keys(result.manufacturers).every(
        v => !data.manufacture.includes(v),
      )
    ) {
      filterData.sourceType = result.retailers.map(row => row.id);
      filterData.category = Object.keys(result.categories);
      filterData.manufacture = Object.keys(result.manufacturers);
      result = await this.getNewFilters(user, filterData, options);
    }

    if (shouldSave) {
      await this.saveUserLastFilter(filterData, result, user);
    }

    const monthsInDb = await db.dates.findAll({
      attributes: [[fn('date_trunc', 'month', col('date')), 'month']],
      group: [fn('date_trunc', 'month', col('date')), 'month'],
      raw: true,
    });

    const products = Object.values(result.products);
    products.forEach(product => {
      product.color = this.getFilteredItem(
        result,
        'brands',
        product.brandId,
      ).color;
    });

    const returnObject = {
      date: {
        relative: this.getRelativeDatesForFilters(companyPossibleOldestDate),
        monthly: this.getMonthsForFilters(
          monthsInDb,
          companyPossibleOldestDate,
        ),
        yearly: this.getYearsForFilters(monthsInDb, companyPossibleOldestDate),
      },
      sourceType: result.retailers,
      category: Object.values(result.categories),
      manufacture: Object.values(result.manufacturers),
      productBrand: Object.values(result.brands),
      productGroup: {
        userProductGroup: Object.values(result.userProductGroups),
        companyProductGroup: Object.values(result.companyProductGroups),
      },
      product: products,
      productCount: Object.keys(result.products).length,
    };

    CommonUtil.sort(returnObject.category, 'name');
    CommonUtil.sort(returnObject.manufacture, 'name');
    CommonUtil.sort(returnObject.productBrand, 'name');
    CommonUtil.sort(returnObject.productGroup.userProductGroup, 'name');
    CommonUtil.sort(returnObject.productGroup.companyProductGroup, 'name');
    CommonUtil.sort(returnObject.product, 'title');
    return returnObject;
  }

  /**
   * Saves users last filter
   * @param data
   * @param filteredData
   * @param user
   * @returns {Promise<void>}
   */
  static async saveUserLastFilter(data, filteredData, user) {
    const lastFilter = FiltersService.formatUserLastFilter(data, filteredData);
    await user.update({ lastFilter });
    return lastFilter;
  }

  static async getNewFilters(user, data, options = {}) {
    const { id: userId, companyId, countryId } = user;
    // eslint-disable-next-line no-param-reassign
    if (options === false) options = {};
    const {
      removeChildBrands = false,
      filterProducts = true,
      filterByDates = false,
      getAllProducts = false,
      watchlistFilter = {
        sourceType: ['All'],
        manufacture: ['All'],
        productBrand: ['All'],
        category: ['All'],
      },
    } = options;
    const { sourceType } = data;

    const availableProductGroups = await ProductGroupService.cacheUserProductGroups(
      user,
    );

    const categoryIds = await db.companyCoreCategory.findAll({
      attributes: ['categoryId'],
      where: {
        companyId: companyId,
        ...(watchlistFilter &&
          watchlistFilter.category[0] !== 'All' && {
            categoryId: watchlistFilter.category,
          }),
      },
    });
    fs.writeFile (`./check/1-Cats.json`, JSON.stringify({
      categoryIds,
      where:{
        companyId: companyId,
        ...(watchlistFilter &&
          watchlistFilter.category[0] !== 'All' && {
            categoryId: watchlistFilter.category,
          }),
      },
    }, null,'\t'), 'utf8', function(err) {
      if (err) throw err;
      console.log(`availableCoreProducts => complete`);
    }
  );

    const ownLabelManufacturerIds = await db.sequelize.query(`
      select "manufacturers"."id" from "companyManufacturers" 
        Join "manufacturers" on "manufacturers"."id" = "companyManufacturers"."manufacturerId"
        where "companyId" = ${companyId} and "isOwnLabelManufacturer" is true
      `, { raw: true, type: QueryTypes.SELECT },
    ).map(i => i.id);

    options.categoryIds = categoryIds.map(i => i.categoryId);
    options.ownLabelManufacturerIds = ownLabelManufacturerIds;

    const [
      retailersList,
      companyCategoriesCoreProducts,
      companyTaxonomiesCoreRetailers,
      companyRetailers,
      dates,
      ownLabelCoreProducts,
    ] = await this.makeFiltersRequests(user, data, options);
    fs.writeFile (`./check/1-companyCategoriesCoreProducts.json`, JSON.stringify({
      retailersList,
      companyCategoriesCoreProducts,
      companyTaxonomiesCoreRetailers,
      companyRetailers,
      dates,
      ownLabelCoreProducts,
      input: {
        user, data, options,
      }
    }, null,'\t'), 'utf8', function(err) {
      if (err) throw err;
      console.log(`availableCoreProducts => complete`);
    }
  );

    const retailers = retailersList.map(row => ({
      ...row,
      label: row.name.replace(/_/g, ' '),
      title: startCase(row.name.replace(/_/g, ' ')),
    }));

    let availableCoreProducts;

    if (companyCategoriesCoreProducts) {
      const availableCategoriesCoreProducts = new Set(
        companyCategoriesCoreProducts.map(({ id }) => id),
      );
      availableCoreProducts = availableCategoriesCoreProducts;
    }

    if (ownLabelCoreProducts) {
      const combinedAvailableCoreProducts = new Set([
        ...availableCoreProducts,
        ...ownLabelCoreProducts.map(({ coreProductId }) => coreProductId),
      ]);
      availableCoreProducts = combinedAvailableCoreProducts;
    }

    if (companyTaxonomiesCoreRetailers) {
      const availableTaxonomiesCoreProducts = new Set(
        companyTaxonomiesCoreRetailers.map(
          ({ coreProductId }) => coreProductId,
        ),
      );
      availableCoreProducts = CommonUtil.setsIntersection(
        availableCoreProducts,
        availableTaxonomiesCoreProducts,
      );
    }

    let retailersIds = sourceType;
    if (!sourceType || sourceType[0] === 'All') {
      retailersIds = retailers.map(({ id }) => id);
    }

    let filteredRetailers = retailers;
    // filter retailers that not belong to user's company
    if (!getAllProducts) {
      retailersIds = retailersIds.filter(id =>
        companyRetailers.find(({ retailerId }) => Number(id) === retailerId),
      );
      filteredRetailers = filteredRetailers.filter(({ id }) =>
        companyRetailers.find(({ retailerId }) => Number(id) === retailerId),
      );
    }

    const productBeforeFilter = availableCoreProducts;
    if (filterByDates) {
      availableCoreProducts = await this.filterByDates(
        retailersIds,
        availableCoreProducts,
        dates,
      );
    }
    
    fs.writeFile (`./check/availableCoreProducts.json`, JSON.stringify({
        availableCoreProducts,
        productBeforeFilter,
        filterByDates,
        retailersIds,
        dates,
      }, null,'\t'), 'utf8', function(err) {
        if (err) throw err;
        console.log(`availableCoreProducts => complete`);
      }
    );

    const result = {
      countryId,
      retailers: filteredRetailers,
      categories: {},
      manufacturers: {},
      brands: {},
      productGroups: {},
      userProductGroups: {},
      companyProductGroups: {},
      products: [],
      productsCount: 0,
    };

    const filters = {
      categories: 'categoryId',
      manufacturers: 'manufacturerId',
      brands: 'brandId',
      userProductGroups: 'productGroupId',
      companyProductGroups: 'productGroupId',
      productGroups: 'productGroupId',
    };

    availableProductGroups.forEach(productGroup => {
      productGroup.isUserProductGroup = false;
      productGroup.isCompanyProductGroup = false;
      if (productGroup.userId === userId) {
        productGroup.isUserProductGroup = true;
      }
      if (productGroup.companyId === companyId) {
        productGroup.isCompanyProductGroup = true;
      }
    });

    for (const retailerId of retailersIds) {
      const retailerData = await this.getRetailersData(retailerId, data, {
        userCoreProducts: availableCoreProducts,
        availableProductGroups,
        filterProducts,
        countryId,
        ownLabelManufacturerIds,
      });
      const { products } = retailerData;

      for (const filterName of Object.keys(filters)) {
        const retailerFilter = retailerData[filterName];
        for (const id of Object.keys(retailerFilter)) {
          if (watchlistFilter) {
            if (
              filterName === 'brands' &&
              watchlistFilter.productBrand[0] !== 'All' &&
              watchlistFilter.productBrand.length &&
              !watchlistFilter.productBrand.includes(id)
            )
              continue;
            if (
              filterName === 'manufacturers' &&
              watchlistFilter.manufacture[0] !== 'All' &&
              watchlistFilter.manufacture.length &&
              !watchlistFilter.manufacture.includes(id)
            )
              continue;
          }
          if (result[filterName][id]) {
            result[filterName][id].productsIds = new Set([
              ...result[filterName][id].productsIds,
              ...retailerFilter[id].productsIds,
            ]);
          } else {
            result[filterName][id] = retailerFilter[id];
          }
        }
      }

      result.products = { ...result.products, ...products };
    }
    fs.writeFile (`./check/2-result.json`, JSON.stringify({
      result,
      availableCoreProducts,
      productBeforeFilter,
      filterByDates,
      retailersIds,
      dates,
    }, null,'\t'), 'utf8', function(err) {
      if (err) throw err;
      console.log(`availableCoreProducts => complete`);
    }
  );
    // count products for child brands
    for (const id of Object.keys(result.brands)) {
      if (result.brands[id].child.length > 0) {
        for (let childBrand of result.brands[id].child) {
          if (result.brands[childBrand.id]) {
            childBrand = result.brands[childBrand.id];
          } else {
            childBrand.productsIds = new Set();
          }

          result.brands[id].productsIds = new Set([
            ...result.brands[id].productsIds,
            ...childBrand.productsIds,
          ]);
        }
      }
    }

    result.productsCount = Object.keys(result.products).length;

    for (const filterName of Object.keys(filters)) {
      for (const id of Object.keys(result[filterName])) {
        result[filterName][id].productsCount =
          result[filterName][id].productsIds.size;
        delete result[filterName][id].productsIds;
      }
    }

    // delete independent child brands
    for (const id of Object.keys(result.brands)) {
      if (result.brands[id] && result.brands[id].child.length > 0) {
        for (const childBrand of result.brands[id].child) {
          if (result.brands[childBrand.id]) {
            childBrand.productsCount =
              result.brands[childBrand.id].productsCount;
          } else {
            childBrand.productsCount = 0;
          }
          if (removeChildBrands) {
            delete result.brands[childBrand.id];
          }
        }
      }
    }

    const coreBrands = await db.brands.findAll({
      where: {
        brandId: null,
        [Op.or]: {
          manufacturerId: null,
          [Op.and]: { manufacturerId: Object.keys(result.manufacturers) },
        },
      },
      raw: true,
    });

    const newBrands = {};
    Object.keys(result.brands).forEach(key => {
      const brand = result.brands[key];
      if (brand.brandId) {
        const cb = coreBrands.find(b => b.id === brand.brandId);
        if (!cb) return;
        if (newBrands[cb.id]) {
          newBrands[cb.id].child.push(brand);
          newBrands[cb.id].productsCount += brand.productsCount;
        } else {
          newBrands[cb.id] = cb;
          newBrands[cb.id].child = [];
          newBrands[cb.id].productsCount = 0;
          newBrands[cb.id].productsCount += brand.productsCount;
          newBrands[cb.id].child.push(brand);
        }
      } else {
        newBrands[key] = brand;
      }
    });
    result.brands = newBrands;
    result.ownLabelManufacturerIds = new Set(ownLabelManufacturerIds);
    return result;
  }

  /**
   * Checks if product presented in at least on day in a range using coreRetailersDate
   * @param retailersIds
   * @param availableCoreProducts
   * @param dates
   * @returns {Promise<Set<any>>}
   */
  static async filterByDates(retailersIds, availableCoreProducts, dates) {
    const where = {
      retailerId: retailersIds,
    };
    if (availableCoreProducts) {
      where.coreProductId = [...availableCoreProducts];
    }
    const coreProductsWithDates = await db.coreRetailer.findAll({
      attributes: ['coreProductId'],
      where,
      include: [
        {
          attributes: [],
          model: db.coreRetailerDate,
          as: 'coreRetailerDate',
          required: true,
          where: {
            dateId: dates.map(d => d.id),
          },
        },
      ],
      group: ['coreProductId'],
      raw: true,
    });

    fs.writeFile (`./check/coreProductsWithDates.json`, JSON.stringify({
        where,
        coreProductsWithDates,
      }, null,'\t'), 'utf8', function(err) {
        if (err) throw err;
        console.log(`coreProductsWithDates => complete`);
      }
    );

    return new Set(
      coreProductsWithDates.map(({ coreProductId }) => coreProductId),
    );
  }

  /**
   * Gets retailers, company retailers, core products, dates
   * @param user
   * @param data
   * @param options
   * @returns {Promise<unknown[]>}
   */
  static makeFiltersRequests(user, data, options) {
    const { companyId, countryId } = user;
    const {
      filterByDates = false,
      getAllProducts = false,
      inTaxonomies = false,
      watchlistFilter = {
        sourceType: ['All'],
        manufacture: ['All'],
        productBrand: ['All'],
        category: ['All'],
      },
      categoryIds,
      ownLabelManufacturerIds = [],
    } = options;
    const promises = [];

    const retailerWhere = { ...(countryId !== -1 && { countryId }) };
    if (watchlistFilter && watchlistFilter.sourceType[0] !== 'All') {
      retailerWhere.id = watchlistFilter.sourceType;
    }
    const retailersPromise = db.retailer.findAll({
      where: retailerWhere,
      attributes: ['id', 'name', 'color'],
      raw: true,
    });
    promises.push(retailersPromise);

    if (!getAllProducts) {
      const companyCategoriesCoreProducts = db.coreProduct.findAll({
        attributes: ['id'],
        where: {
          categoryId: categoryIds,
        },
      });
      promises.push(companyCategoriesCoreProducts);

      if (inTaxonomies) {
        const companyTaxonomiesCoreRetailers = db.coreRetailer.findAll({
          attributes: ['coreProductId'],
          include: [
            {
              attributes: ['id'],
              model: db.retailerTaxonomy,
              as: 'retailerTaxonomy',
              required: true,
              include: [
                {
                  attributes: [],
                  model: db.companyTaxonomy,
                  as: 'companyTaxonomies',
                  required: true,
                  where: { companyId },
                },
              ],
            },
          ],
        });
        promises.push(companyTaxonomiesCoreRetailers);
      } else {
        promises.push(null);
      }

      const companyRetailers = db.companyRetailer.findAll({
        attributes: ['retailerId'],
        where: { companyId },
        raw: true,
      });
      promises.push(companyRetailers);
    } else {
      // company categories
      promises.push(null);

      // company taxonomies
      promises.push(null);

      // company retailers promise
      promises.push(null);
    }

    if (filterByDates) {
      promises.push(this.getDatesIds(data.timePeriod));
    } else {
      promises.push(null);
    }

    if (!!companyId && companyId !== -1 && ownLabelManufacturerIds.length > 0) {
      const ownLabelCoreProducts = db.coreProductCountryData.findAll({
        attributes: ['coreProductId'],
        where: {
          ownLabelManufacturerId: ownLabelManufacturerIds,
          countryId
        },
        raw: true,
      });
      promises.push(ownLabelCoreProducts);
    } else {
      promises.push(null);
    }

    return Promise.all(promises);
  }

  static async getRetailersData(retailerId, query, userFilters) {
    const {
      manufacture = ['All'],
      productBrand = ['All'],
      category = ['All'],
      productGroup = ['All'],
      product = ['All'],
      newSelected,
    } = query;

    const {
      availableProductGroups,
      userCoreProducts,
      filterProducts,
      countryId,
      ownLabelManufacturerIds = [],
    } = userFilters;

    const result = {
      name: '',
      categories: {},
      manufacturers: {},
      brands: {},
      productGroups: {},
      userProductGroups: {},
      companyProductGroups: {},
      products: [],
    };

    const retailerData = await this.getCachedRetailerData(
      retailerId,
      countryId,
    );
    const availableProductGroupsMap = CommonUtil.arrayToObject(
      availableProductGroups,
      'id',
    );

    const coreProductsProductGroup = this.getCoreProductProductGroupsMap(
      availableProductGroups,
    );

    // assign productGroupId to every core product
    for (const coreProduct of retailerData.coreProducts) {
      coreProduct.productGroupIds =
        coreProductsProductGroup[coreProduct.id] || new Set();
    }

    // add child brands to filter
    const productBrandsWithChildren = [];
    if (productBrand[0] !== 'All') {
      for (const id of productBrand) {
        const brand = retailerData.brands[id];
        if (brand) {
          productBrandsWithChildren.push(brand.id);
          for (const childBrand of brand.child) {
            productBrandsWithChildren.push(childBrand.id);
          }
        }
      }
    }
    query.productBrandsWithChilds = productBrandsWithChildren;

    result.name = retailerData.name;

    let coreProducts = retailerData.coreProducts;

    if (userCoreProducts && (typeof userCoreProducts === 'object') && !Array.isArray(userCoreProducts)) {
      coreProducts = coreProducts.filter(coreProduct => userCoreProducts.has(coreProduct.id));
    }

    let atLeastOneFilter = false;

    result.categories = this.filterCategories(
      coreProducts,
      retailerData,
      query,
    );

    if (category[0] !== 'All') {
      atLeastOneFilter = true;
      coreProducts = coreProducts.filter(coreProduct => {
        const inNewSelected =
          newSelected &&
          newSelected.category &&
          newSelected.category.find(
            id => coreProduct.categoryId === parseInt(id, 10),
          );
        const inCategories = category.find(
          id => coreProduct.categoryId === parseInt(id, 10),
        );
        return inCategories || inNewSelected;
      });
    }

    coreProducts.forEach(coreProduct => {
      coreProduct.manufacturerId  = ownLabelManufacturerIds.some(ownLmId => ownLmId === parseInt(coreProduct.ownLabelManufacturerId, 10)) ?
         coreProduct.ownLabelManufacturerId : coreProduct.manufacturerId;
      const manufacturer =
        retailerData.manufacturers[coreProduct.manufacturerId];
      if (manufacturer) {
        if (!result.manufacturers[manufacturer.id]) {
          result.manufacturers[manufacturer.id] = manufacturer;
          result.manufacturers[manufacturer.id].productsIds = new Set();
        }

        result.manufacturers[manufacturer.id].productsIds.add(coreProduct.id);
      }
    });

    if (manufacture[0] !== 'All') {
      atLeastOneFilter = true;
      coreProducts = coreProducts.filter(coreProduct => {
        const inNewSelected =
          newSelected &&
          newSelected.manufacture &&
          newSelected.manufacture.find(
            id => coreProduct.manufacturerId === parseInt(id, 10),
          );
        const inManufacturers = manufacture.find(
          id => coreProduct.manufacturerId === parseInt(id, 10),
        );
        return inManufacturers || inNewSelected;
      });
    }

    coreProducts.forEach(coreProduct => {
      const brand = retailerData.brands[coreProduct.brandId];
      if (brand) {
        if (!result.brands[brand.id]) {
          result.brands[brand.id] = brand;
          result.brands[brand.id].productsIds = new Set();
        }

        result.brands[brand.id].productsIds.add(coreProduct.id);
      }
    });

    if (productBrand[0] !== 'All') {
      atLeastOneFilter = true;

      coreProducts = coreProducts.filter(coreProduct => {
        const inNewSelected =
          newSelected &&
          newSelected.productBrand &&
          newSelected.productBrand.find(
            id => coreProduct.brandId === parseInt(id, 10),
          );
        const inBrands = productBrandsWithChildren.find(
          id => coreProduct.brandId === id,
        );
        return inBrands || inNewSelected;
      });
    }

    coreProducts.forEach(coreProduct => {
      for (const productGroupId of coreProduct.productGroupIds || []) {
        const filteredProductGroup = availableProductGroupsMap[productGroupId];

        if (filteredProductGroup) {
          if (!result.productGroups[filteredProductGroup.id]) {
            result.productGroups[
              filteredProductGroup.id
            ] = filteredProductGroup;
            result.productGroups[
              filteredProductGroup.id
            ].productsIds = new Set();
          }

          if (filteredProductGroup.isUserProductGroup) {
            if (!result.userProductGroups[filteredProductGroup.id]) {
              result.userProductGroups[filteredProductGroup.id] = {
                id: filteredProductGroup.id,
                name: filteredProductGroup.name,
                color: filteredProductGroup.color,
              };
              result.userProductGroups[
                filteredProductGroup.id
              ].productsIds = new Set();
            }
            result.userProductGroups[filteredProductGroup.id].productsIds.add(
              coreProduct.id,
            );
          }

          if (filteredProductGroup.isCompanyProductGroup) {
            if (!result.companyProductGroups[filteredProductGroup.id]) {
              result.companyProductGroups[filteredProductGroup.id] = {
                id: filteredProductGroup.id,
                name: filteredProductGroup.name,
                color: filteredProductGroup.color,
              };
              result.companyProductGroups[
                filteredProductGroup.id
              ].productsIds = new Set();
            }
            result.companyProductGroups[
              filteredProductGroup.id
            ].productsIds.add(coreProduct.id);
          }
          result.productGroups[filteredProductGroup.id].productsIds.add(
            coreProduct.id,
          );
        }
      }
    });

    if (productGroup[0] !== 'All') {
      atLeastOneFilter = true;
      coreProducts = coreProducts.filter(coreProduct =>
        productGroup.find(id =>
          coreProduct.productGroupIds.has(parseInt(id, 10)),
        ),
      );
    }

    if (filterProducts && product[0] !== 'All') {
      atLeastOneFilter = true;
      coreProducts = coreProducts.filter(coreProduct => product.find(id => coreProduct.id === parseInt(id, 10)));
    }

    if (atLeastOneFilter) {
      coreProducts = coreProducts.filter(
        coreProduct =>
          !(
            coreProduct.brandId === null &&
            coreProduct.categoryId === null &&
            coreProduct.productGroupIds.size === 0
          ),
      );
    }

    const coreProductsMap = {};
    coreProducts.forEach(coreProduct => {
      coreProduct.productGroupIds = [...coreProduct.productGroupIds];
      coreProductsMap[coreProduct.id] = coreProduct;
    });

    result.products = coreProductsMap;

    return result;
  }

  /**
   * Inverts product groups with core products map to core products with product groups map
   * @param productGroups
   * @returns {Promise<{}>}
   */
  static getCoreProductProductGroupsMap(productGroups) {
    const coreProductsProductGroup = {};
    for (const availableProductGroup of productGroups) {
      for (const coreProductId of availableProductGroup.coreProductsIds) {
        if (!coreProductsProductGroup[coreProductId]) {
          coreProductsProductGroup[coreProductId] = new Set();
        }
        coreProductsProductGroup[coreProductId].add(availableProductGroup.id);
      }
    }
    return coreProductsProductGroup;
  }

  static async getCachedRetailerData(retailerId, countryId) {
    const data = await RedisUtil.getData(`retailer_${retailerId}_${countryId}`);

    if (data) {
      return data;
    }

    const { id, name, color } = await RetailerService.getRetailer(retailerId);
    const retailerData = { id, name, color };

    const coreProducts = await db.coreProduct.findAll({
      where: {
        [Op.or]: {
          [Op.not]: { disabled: true },
          disabled: null,
        },
      },
      include: [
        {
          model: db.coreProductCountryData,
          as: 'countryData',
          required: false,
          where: {
            countryId,
          },
        },
        {
          attributes: [],
          model: db.coreRetailer,
          as: 'coreRetailers',
          required: true,
          where: {
            retailerId,
          },
          group: ['retailerId', 'coreProductId'],
        },
      ],
      raw: true,
      nest: true,
      attributes: [
        [col('"coreProduct".id'), 'id'],
        'ean',
        'image',
        'title',
        'brandId',
        'categoryId',
        'secondaryImages',
      ],
    });
    retailerData.coreProducts = coreProducts;

    const categoriesIds = new Set();
    const brandsIds = new Set();

    for (const coreProduct of coreProducts) {
      categoriesIds.add(coreProduct.categoryId);
      brandsIds.add(coreProduct.brandId);
    }

    const categories = await db.categories.findAll({
      attributes: ['id', 'name', 'color'],
      where: {
        id: [...categoriesIds],
      },
      raw: true,
    });

    retailerData.categories = {};
    for (const category of categories) {
      retailerData.categories[category.id] = category;
    }

    const brandsAndManufacturersCondition = {
      include: [
        {
          model: db.brands,
          as: 'brands',
          where: {
            id: [...brandsIds],
          },
          include: [
            {
              as: 'child',
              model: db.brands,
              attributes: ['id', 'name', 'color', 'brandId', 'manufacturerId'],
            },
            {
              as: 'parent',
              model: db.brands,
              attributes: ['id', 'name', 'color', 'brandId', 'manufacturerId'],
            },
          ],
          attributes: ['id', 'name', 'brandId', 'color', 'manufacturerId'],
        },
      ],
      attributes: ['id', 'name', 'color'],
    };

    const { brands, manufacturers } = await this.getManufacturersAndBrands(
      brandsAndManufacturersCondition,
    );
    retailerData.brands = {};
    for (const brand of brands) {
      retailerData.brands[brand.id] = brand;
    }

    retailerData.manufacturers = {};
    for (const manufacturer of manufacturers) {
      retailerData.manufacturers[manufacturer.id] = manufacturer;
    }

    const brandsManufacturerMap = {};
    brands.forEach(brand => {
      brandsManufacturerMap[brand.id] = brand.manufacturerId;
    });

    for (const coreProduct of coreProducts) {
      coreProduct.manufacturerId = brandsManufacturerMap[coreProduct.brandId];
    }

    const coreProductsFields = [
      'id',
      'title',
      'ean',
      'image',
      'brandId',
      'categoryId',
      'manufacturerId',
      'secondaryImages',
    ];

    retailerData.coreProducts = coreProducts.map(coreProduct => ({
        ...pick(
          CoreProductService.getProductCountryData(coreProduct),
          coreProductsFields,
        ),
        ownLabelManufacturerId: coreProduct.countryData.ownLabelManufacturerId,
      })
    );

    retailerData.allBrands = brands;
    await RedisUtil.cacheData(`retailer_${id}_${countryId}`, retailerData);

    return retailerData;
  }

  static async clearCachedRetailerData(retailerId, countryId) {
    await RedisUtil.clearByKey(`retailer_${retailerId}_${countryId}`);
  };

  static filterCategories(coreProducts, retailerData) {
    const categories = {};
    coreProducts.forEach(coreProduct => {
      const filteredCategory = retailerData.categories[coreProduct.categoryId];
      if (filteredCategory) {
        if (!categories[filteredCategory.id]) {
          categories[filteredCategory.id] = filteredCategory;
          categories[filteredCategory.id].productsIds = new Set();
        }

        categories[filteredCategory.id].productsIds.add(coreProduct.id);
      }
    });
    return categories;
  }

  static getFilteredItem(filteredData, filterName, id) {
    const item = filteredData[filterName][id];
    if (item) {
      return item;
    }
    const color = '#777777';
    let name = 'No date';
    if (filterName === 'brands') {
      name = 'No brand';
    } else if (filterName === 'manufacturers') {
      name = 'No manufacturer';
    }
    return {
      id: name,
      name,
      color,
    };
  }

  static async updateLastFilterOnLogin(user) {
    const applyWatchlist = user.watchlist || false;

    const filterData = {
      product: ['All'],
      productGroup: ['All'],
      productBrand: ['All'],
      category: ['All'],
      sourceType: ['All'],
      manufacture: user.company.manufacturer.map(({ id }) => `${id}`),
      date: ['4'],
      timePeriod: {
        new: moment()
          .subtract(1, 'days')
          .format(FiltersService.dateFormat),
        old: moment()
          .subtract(15, 'days')
          .format(FiltersService.dateFormat),
      },
    };

    const options = {
      removeChildBrands: true,
      filterProducts: false,
      filterByDates: !!filterData.timePeriod,
      watchlistFilter: applyWatchlist ? user.watchlistFilter : false,
    };

    let result = await this.getNewFilters(user, filterData, options);

    if (
      Object.keys(result.manufacturers).every(
        v => !filterData.manufacture.includes(v),
      )
    ) {
      filterData.sourceType = result.retailers.map(row => row.id);
      filterData.category = Object.keys(result.categories);
      filterData.manufacture = Object.keys(result.manufacturers);
      result = await this.getNewFilters(user, filterData, options);
    }

    return this.saveUserLastFilter(filterData, result, user);
  }
}

