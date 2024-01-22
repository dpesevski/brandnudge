
static async createProducts(products) {
    let result = [];
    let countP = 0;
    if (!products.length) {
        console.log('No products!');
        return result;
    }
    const {
        dates,
        retailer,
        sourceCategoryType,
    } = await ProductService.getCreateProductCommonData(products);
    const dateId = dates[0].id;
    const expandProduct = ({
        promotions,
        productPrice,
        originalPrice,
        status,
        ...product
    }) => ({
        product,
        promotions,
        productPrice,
        originalPrice,
        status,
    });
    for (const row of products) {
        try {
            const {
                product,
                promotions,
                productPrice,
                originalPrice,
                status,
            } = expandProduct(row);
            product.promotions = !!promotions;
            product.promotionDescription = promotions
                ? promotions[0].description
                : '';
            product.basePrice = originalPrice;
            product.shelfPrice = originalPrice;
            product.promotedPrice = originalPrice;
            product.retailerId = retailer.id;
            product.dateId = dateId;
            if (!product.featured) product.featured = false;
            if (
                product.sourceType === 'waitrose' &&
                !CompareUtil.checkEAN(product.ean)
            ) {
                const waitroseEAN = await ProductService.fetchWaitroseProductEAN(
                    product.sourceId,
                );
                if (waitroseEAN) product.ean = waitroseEAN;
            }
            const exists = await db.product.findOne({
                where: {
                    sourceId: product.sourceId,
                    retailerId: product.retailerId,
                    dateId: product.dateId,
                },
            });
            if (exists) {
                // const [sourceCategoryOrg] = await ProductService.setSourceCategory({
                //   name: product.category,
                //   type: sourceCategoryType,
                // });
                // const sourceCategory = await DbUtil.execDbFunc('ins_sourceCategories', {
                //   name: product.category,
                //   type: sourceCategoryType,
                // });
                await this.createProductsData({ ...product, productId: exists.id });
                await this.createAmazonProduct(product, exists.id);
                countP += 1;
                // eslint-disable-next-line no-continue
                // continue;
            }
            const brand = await this.getBrandBy(product.productBrand);
            let core = await ProductService.findCreateProductCore(
                product,
                retailer,
            );
            const coreProductData = {
                ean: product.ean,
                title: product.productTitle,
                image: product.productImage,
                brandId: brand.id,
                bundled: product.bundled,
                secondaryImages: product.secondaryImages,
                description: product.productDescription,
                features: product.features,
                ingredients: product.productInfo,
                size: product.size,
                specification: product.nutritional,
                productOptions: product.productOptions || false,
                eanIssues: !CompareUtil.checkEAN(product.ean),
            };
            let freshCore = false;
            if (!core) {
                core = await this.createCoreBy(coreProductData);
                freshCore = true;
            }
            if (!core.countryData || !core.countryData.id) {
                await CoreProductService.createProductCountryData(
                    core,
                    retailer.countryId,
                    coreProductData,
                    freshCore,
                );
            }
            if (core.productOptions !== product.productOptions) {
                await core.update({
                    productOptions: product.productOptions,
                });
            }
            product.coreProductId = core.id;
            // const [sourceCategory] = await ProductService.setSourceCategory({
            //   name: product.category,
            //   type: sourceCategoryType,
            // });
            // =====
            // const sourceCategory = await DbUtil.execDbFunc('sel_ins_sourceCategories', [
            //   product.category,
            //   sourceCategoryType,
            // ]);
            const saved = await this.createProductBy(product);
            // const [coreRetailer] = await ProductService.setCoreRetailer({
            //   coreProductId: core.id,
            //   retailerId: retailer.id,
            //   productId: product.sourceId,
            // });
            const coreRetailer = await DbUtil.execDbFunc('sel_ins_coreRetailers', [
                core.id,
                retailer.id,
                product.sourceId,
            ]);
            const taxonomy = await db.retailerTaxonomy.findOne({
                where: { id: product.taxonomyId },
            });
            if (taxonomy) {
                // await ProductService.setCoreRetailerTaxonomy({
                //   coreRetailerId: coreRetailer.id,
                //   retailerTaxonomyId: taxonomy.id,
                // });
                const coreRetailerTaxonomies = await DbUtil.execDbFunc('sel_ins_coreRetailerTaxonomies', [
                    coreRetailer.id,
                    taxonomy.id,
                ]);
                console.log('!!coreRetailerTaxonomies=', JSON.stringify(coreRetailerTaxonomies));
            }
            //await this.saveProductStatus(saved, status, product.screenshot);
            if (promotions) {
                const promo = await PromotionService.processProductPromotions(
                    promotions,
                    saved,
                );
                console.log('!!promo=', JSON.stringify(promo))
                const multibuy = promo.find(item => item.mechanic === 'Multibuy');
                if (multibuy) {
                    // eslint-disable-next-line max-len
                    saved.promotedPrice = PromotionService.calculateMultibuyPrice(
                        multibuy.description,
                        saved.promotedPrice,
                    );
                } else {
                    const tescoClubcardPromo = promo.find(item =>
                        /clubcard price/i.test(item.description),
                    );
                    if (!(saved.sourceType === 'tesco' && tescoClubcardPromo)) {
                        saved.shelfPrice = productPrice;
                    }
                    saved.promotedPrice = productPrice;
                }
                await saved.save();
            }
            const aggredated = await this.calculateAggregated(saved);
            aggredated.productId = saved.id;
            console.log('!!aggredated=', JSON.stringify(aggredated))
            //await db.aggregatedProduct.create(aggredated);
            await DbUtil.execDbFunc('ins_aggregatedProducts', [
                aggredated.productId,
                ${ aggredated.titleMatch },
            ])
            await ProductService.setCoreRetailerDate({
                coreRetailerId: coreRetailer.id,
                dateId: saved.dateId,
            });
            //await ProductService.setCoreSourceCategory({
            // coreProductId: core.id,
            // sourceCategoryId: sourceCategory.id,
            //});
            result = [...result, saved];
        } catch (error) {
            console.log(error);
            console.log(row.sourceId);
        }
    }
    console.log('PRODUCTS CREATED', countP, result.length);
    return result;
}
static async execDbFunc(fName, params = []) {
    const [result] = await db.sequelize.query(`SELECT "${fName}"(${params.map((_, i) => `:para${i}`).join(',')}) as result`, {
        replacements: params.reduce((acc, p, i) => {
            return {
                ...acc,
                [`para${i}`]: p,
            }
        }, {}),
        type: db.sequelize.QueryTypes.SELECT,
    });
    return result && result['result'];
}
  static async createProductsData(product) {
    // const productsData = {
    //   productId: product.productId,
    //   category: product.category,
    //   categoryType: product.categoryType,
    //   featured: product.featured,
    //   featuredRank: Number(product.featuredRank),
    //   productRank: Number(product.productRank),
    //   parentCategory: product.parentCategory ? product.parentCategory : '',
    //   pageNumber: String(product.pageNumber),
    //   screenshot: product.screenshot,
    //   taxonomyId: product.taxonomyId || 0,
    //   sourceCategoryId: sourceCategory.id,
    // };
    const productsData = [
        product.productId,
        product.category,
        product.categoryType,
        product.featured,
        Number(product.featuredRank),
        Number(product.productRank),
        product.parentCategory ? product.parentCategory : '',
        String(product.pageNumber),
        product.screenshot,
        product.taxonomyId || 0,
    ];
    // let savedProductsData = await db.productsData.findOne({
    //   where: productsData,
    // });
    // if (!savedProductsData) {
    //   savedProductsData = await db.productsData.create(productsData);
    // }
    return await DbUtil.execDbFunc('sel_ins_productsData', productsData);
}
static async findCreateProductCore(product, retailer) {
    let core = false;
    let barcode = false;
    const { id: retailerId, countryId } = retailer;
    const include = [
        {
            model: db.coreProductCountryData,
            as: 'countryData',
            where: { countryId },
            required: false,
        },
    ];
    // if (CompareUtil.checkEAN(product.ean)) {
    barcode = await db.coreProductBarcode.findOne({
        where: { barcode: product.ean },
    });
    // }
    if (barcode) {
        core = await db.coreProduct.scope('withMaster').findOne({
            where: { id: barcode.coreProductId },
            include,
        });
    } else {
        core = await db.coreProduct.scope('withMaster').findOne({
            where: { ean: product.ean },
            include,
        });
        if (core) {
            // barcode = await db.coreProductBarcode.findOne({
            //   where: { coreProductId: core.id },
            // });
            // if (!barcode || (barcode && barcode.barcode !== product.ean)) {
            //   barcode = await db.coreProductBarcode.create({
            //     coreProductId: core.id,
            //     barcode: product.ean,
            //   });
            // }
            //const where = { coreProductId: core.id, barcode: product.ean };
            // await db.coreProductBarcode.findOrCreate({
            //   where,
            //   defaults: where,
            // });
            //barcode = await DbUtil.execDbFunc('ins_coreProductBarcodes', where);
            barcode = await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
        }
    }
    if (core) {
        if (core.disabled) await core.update({ disabled: false });
        return core;
    }
    const cr = await db.coreRetailer.findOne({
        where: {
            retailerId,
            productId: product.sourceId,
        },
        include: [
            {
                model: db.coreProduct,
                as: 'coreProduct',
                where: { disabled: { [Op.or]: [false, null] } },
                required: true,
            },
        ],
        order: [['createdAt', 'DESC']],
    });
    if (!cr) return core;
    core = await db.coreProduct.scope('withMaster').findOne({
        where: { id: cr.coreProductId },
        include,
    });
    if (core) {
        //const where = { coreProductId: core.id, barcode: product.ean };
        // await db.coreProductBarcode.findOrCreate({
        //   where,
        //   defaults: where,
        // });
        await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
    }
    return core;
}

static async getCreateProductCommonData(products) {
    const result = {
        dates: [],
        retailer: null,
        sourceCategoryType: 'taxonomy',
    };
    if (!products || !products.length) return result;
    const product = products[0];
    const time = new Date(new Date(product.date).setHours(0, 0, 0, 0))
        .toISOString()
        .toString();
    result.dates = await db.dates.findOrCreate({
        where: { date: time },
    });
    result.retailer = await RetailerService.getRetailerByName(
        product.sourceType,
    );
    result.sourceCategoryType =
        product.categoryType === 'search' ? 'search' : 'taxonomy';
    return result;
}
  
static async findCreateProductCore(product, retailer) {
    let core = false;
    let barcode = false;
    const { id: retailerId, countryId } = retailer;
    const include = [
        {
            model: db.coreProductCountryData,
            as: 'countryData',
            where: { countryId },
            required: false,
        },
    ];
    // if (CompareUtil.checkEAN(product.ean)) {
    barcode = await db.coreProductBarcode.findOne({
        where: { barcode: product.ean },
    });
    // }
    if (barcode) {
        core = await db.coreProduct.scope('withMaster').findOne({
            where: { id: barcode.coreProductId },
            include,
        });
    } else {
        core = await db.coreProduct.scope('withMaster').findOne({
            where: { ean: product.ean },
            include,
        });
        if (core) {
            // barcode = await db.coreProductBarcode.findOne({
            //   where: { coreProductId: core.id },
            // });
            // if (!barcode || (barcode && barcode.barcode !== product.ean)) {
            //   barcode = await db.coreProductBarcode.create({
            //     coreProductId: core.id,
            //     barcode: product.ean,
            //   });
            // }
            //const where = { coreProductId: core.id, barcode: product.ean };
            // await db.coreProductBarcode.findOrCreate({
            //   where,
            //   defaults: where,
            // });
            //barcode = await DbUtil.execDbFunc('ins_coreProductBarcodes', where);
            barcode = await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
        }
    }
    if (core) {
        if (core.disabled) await core.update({ disabled: false });
        return core;
    }
    const cr = await db.coreRetailer.findOne({
        where: {
            retailerId,
            productId: product.sourceId,
        },
        include: [
            {
                model: db.coreProduct,
                as: 'coreProduct',
                where: { disabled: { [Op.or]: [false, null] } },
                required: true,
            },
        ],
        order: [['createdAt', 'DESC']],
    });
    if (!cr) return core;
    core = await db.coreProduct.scope('withMaster').findOne({
        where: { id: cr.coreProductId },
        include,
    });
    if (core) {
        //const where = { coreProductId: core.id, barcode: product.ean };
        // await db.coreProductBarcode.findOrCreate({
        //   where,
        //   defaults: where,
        // });
        await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
    }
    return core;
}
static async createProductCountryData(
    product,
    countryId,
    coreProductData,
    freshCore = false,
) {
    const countryData = await db.coreProductCountryData.findOne({
        where: {
            coreProductId: product.id,
            countryId,
        },
    });
    if (!countryData) {
        const data = {
            countryId,
            coreProductId: product.id,
            ...countryDataProperties.reduce(
                (acc, property) => ({
                    ...acc,
                    [property]: coreProductData[property] || product[property],
                }),
                {},
            ),
        };
        if (freshCore) {
            data.image = product.image;
        } else {
            data.image = await AWSUtil.uploadImage({
                bucket: 'coreImages',
                key: `${product.ean}_c${countryId}`,
                link: coreProductData.image,
            });
        }
        return db.coreProductCountryData.create(data);
    }
    countryDataProperties.forEach(property => {
        countryData[property] = countryData[property] || product[property];
    });
    return countryData.save();
}

static async processProductPromotions(promotions, product) {
    const result = [];
    if (!promotions || !product) return result;
    const findRetailerPromotion = await PromotionService.findRetailerPromotion(
        product.retailerId,
    );
    for (const promotion of promotions.filter(Boolean)) {
        try {
            const promo = await findRetailerPromotion(promotion);
            if (!promo) continue;
            const startDate = parseDate(promotion.startDate || product.date);
            const endDate = parseDate(promotion.endDate || product.date);
            const promoId =
                promotion.promoId ||
                PromotionService.getDefaultPromoId(product, {
                    ...promotion,
                    startDate,
                });
            const data = {
                promoId: `${promoId}`,
                productId: product.id,
                retailerPromotionId: promo.id,
                description: promotion.description,
                startDate: startDate
                    ? new Date(startDate).toLocaleDateString()
                    : promotion.startDate,
                endDate: endDate
                    ? new Date(endDate).toLocaleDateString()
                    : promotion.endDate,
            };
            // eslint-disable-next-line max-len
            const value = await PromotionService.comparePromotionWithPreviousProduct(
                promotion,
                data,
                product,
            );
            await db.promotion.findOrCreate({ where: value, defaults: value });
            result.push({ ...value, mechanic: promo.mechanic.name });
        } catch (e) {
            console.error('Promotion create failure!', e);
        }
    }
    return result;
} (edited) 


export default class PromotionService extends Service {
    /**
     * calendar products selection
     * @param filteredData
     * @param data
     * @param timePeriod
     * @returns {Promise<<Model[]>>}
     */
    static async getCalendarProducts(filteredData, data, timePeriod) {
      const dates = await this.getDatesIds(timePeriod);
  
      const where = {
        coreProductId: Object.keys(filteredData.products),
        dateId: dates.map(d => d.id),
      };
  
      where.retailerId = CommonUtil.getRetailersIdsForQuery(
        data.sourceType,
        filteredData,
      );
  
      return db.product.findAll({
        attributes: [
          'productTitle',
          'promotedPrice',
          'basePrice',
          'coreProductId',
          'date',
          'promotionDescription',
          'sourceId',
          ['sourceType', 'retailerId'],
        ],
        where,
        include: [
          'retailer',
          {
            model: db.promotion,
            as: 'productPromotions',
            required: true,
            include: [
              {
                model: db.retailerPromotion,
                as: 'retailerPromotion',
                required: true,
                include: [
                  {
                    model: db.promotionMechanic,
                    required: true,
                    as: 'promotionMechanic',
                  },
                ],
                where: {
                  ...(data.mechanic &&
                    data.mechanic[0] !== 'All' && {
                      promotionMechanicId: {
                        [Op.in]: data.mechanic[0].split('|'),
                      },
                    }),
                },
              },
            ],
          },
          {
            model: db.coreProduct,
            as: 'coreProduct',
            required: true,
            include: [
              {
                model: db.coreProductCountryData,
                as: 'countryData',
                required: false,
                where: {
                  countryId: filteredData.countryId,
                },
              },
              {
                model: db.brands,
                as: 'productBrand',
                required: true,
              },
            ],
          },
        ],
      });
    }
  
    /**
     * prepare calendaer result from grouped promotions
     * @param grouped
     * @param range
     * @returns {{period: *, total: *, discountPercent: *|number, children: *, label: *, id: *,
     * discountValue: *|number}[]}
     */
    static prepareCalendarResult(grouped, range) {
      return Object.values(grouped)
        .map(row => {
          const children = Object.values(row.children)
            .map(row2 => {
              const children2 = Object.values(row2.products)
                // eslint-disable-next-line max-len
                .map(obj => ({
                  promotions: Object.values(obj.promotions),
                  product: obj.product,
                }));
              const promotionsGroup = children2.reduce((acc, child) => {
                child.promotions.forEach(promo => {
                  if (!acc[promo.mechanic]) {
                    acc[promo.mechanic] = {
                      period: range.reduce(
                        (obj, date) => ({ ...obj, [date]: false }),
                        {},
                      ),
                      discountPercent: [],
                      discountValue: [],
                    };
                  }
                  Object.keys(promo.period).forEach(date => {
                    if (promo.period[date] === true)
                      acc[promo.mechanic].period[date] = true;
                  });
                  acc[promo.mechanic].discountPercent.push(promo.discountPercent);
                  acc[promo.mechanic].discountValue.push(promo.discountValue);
                });
                return acc;
              }, {});
              const promotions = Object.keys(promotionsGroup).map(label => {
                const promo = promotionsGroup[label];
                const dp = promo.discountPercent.filter(num => +num > 0);
                const dv = promo.discountValue.filter(num => +num > 0);
                return {
                  label,
                  period: promo.period,
                  discountPercent: dp.length ? CommonUtil.average(dp) : 0,
                  discountValue: dv.length ? CommonUtil.average(dv) : 0,
                };
              });
  
              const pp = promotions.filter(
                ({ discountPercent }) => +discountPercent > 0,
              );
              const discountPercent = pp.length
                ? CommonUtil.average(pp.map(item => item.discountPercent))
                : 0;
              const discountValue = pp.length
                ? CommonUtil.average(pp.map(item => item.discountValue))
                : 0;
              return {
                id: `${row.item.name}_${row2.item.name}`,
                color: row2.item.color,
                label: row2.item.name,
                discountPercent,
                discountValue,
                promotions,
                total: children2.length,
                children: children2,
              };
            })
            .sort((a, b) => a.label.localeCompare(b.label));
          const period = range.reduce(
            (obj, date) => ({ ...obj, [date]: false }),
            {},
          );
          children.forEach(brand => {
            brand.promotions.forEach(promo => {
              Object.keys(promo.period).forEach(date => {
                if (promo.period[date] === true) period[date] = true;
              });
            });
          });
          const bdp = children.filter(
            ({ discountPercent }) => +discountPercent > 0,
          );
          const bdv = children.filter(({ discountValue }) => +discountValue > 0);
          // eslint-disable-next-line max-len
          const totalDiscountPercent = CommonUtil.average(
            bdp.map(({ discountPercent }) => discountPercent),
          );
          // eslint-disable-next-line max-len
          const totalDiscountValue = CommonUtil.average(
            bdv.map(({ discountValue }) => discountValue),
          );
          const total = children.reduce((sum, ch) => ch.children.length + sum, 0);
          // eslint-disable-next-line max-len
          return {
            color: row.item.color,
            label: row.item.name,
            id: row.item.id,
            discountPercent: totalDiscountPercent,
            discountValue: totalDiscountValue,
            period,
            total,
            children,
          };
        })
        .sort((a, b) => a.label.localeCompare(b.label));
    }
  
    /**
     * Promotions calendar
     * @param user
     * @param data
     * @returns {Promise<{productsCount: number, rows: *, avgDiscountValue: (*|number),
     * avgDiscountPercent: (*|number)}>}
     */
    static async getPromotionCalendar(user, data) {
      const { retailers: retailersOrder } = user;
      const dateFormat = 'M/D/YYYY';
      const timePeriod = CommonUtil.timePeriodToObject(data.timePeriod);
      const range = CommonUtil.getTimePeriodDays(timePeriod, dateFormat);
      const filteredData = await FiltersService.getNewFilters(user, data);
      // eslint-disable-next-line max-len
      const products = await PromotionService.getCalendarProducts(
        filteredData,
        data,
        timePeriod,
      );
      // eslint-disable-next-line max-len
      const getProductData = ({
        coreProduct,
        retailer,
        productPromotions,
        ...product
      }) => {
        const countryData = CoreProductService.getProductCountryData(coreProduct);
        return {
          ...product,
          id: coreProduct.id || product.coreProductId,
          productTitle: countryData.title || product.productTitle,
          productImage: countryData.image || product.productImage,
          color: coreProduct.productBrand.color,
        };
      };
  
      const productsCount = new Set();
      const grouped = products.reduce((acc, row) => {
        const product = row.toJSON();
        const item1 =
          data.groupBy === 'brand' ? row.coreProduct.productBrand : row.retailer;
        const item2 =
          data.groupBy === 'brand' ? row.retailer : row.coreProduct.productBrand;
  
        if (!acc[item1.id]) acc[item1.id] = { item: item1, children: {} };
        // eslint-disable-next-line max-len
        if (!acc[item1.id].children[item2.id]) {
          acc[item1.id].children[item2.id] = { item: item2, products: {} };
        }
        if (!acc[item1.id].children[item2.id].products[row.coreProductId]) {
          acc[item1.id].children[item2.id].products[row.coreProductId] = {
            product: getProductData(product),
            promotions: {},
          };
          productsCount.add(row.coreProductId);
        }
  
        row.productPromotions.forEach(p => {
          const promo = p.toJSON();
          const startDate = moment(new Date(promo.startDate || row.date)).format(
            dateFormat,
          );
          const endDate = moment(new Date(promo.endDate || row.date)).format(
            dateFormat,
          );
          const promoId =
            promo.promoId ||
            PromotionServiceV1.getDefaultPromoId(product, {
              ...promo,
              startDate,
            });
          // eslint-disable-next-line max-len
          const promotions =
            acc[item1.id].children[item2.id].products[row.coreProductId]
              .promotions;
          const promotionKey = PromotionServiceV1.getPromoKey(
            promotions,
            product,
            promo,
            promoId,
          );
  
          let promoItem = promotions[promotionKey];
          if (!promoItem) {
            const basePrice = CommonUtil.preparePrice(row.basePrice);
            const promotedPrice = CommonUtil.preparePrice(row.promotedPrice);
            promoItem = {
              promoId,
              promotionKey,
              id: promo.id,
              label: promo.description,
              mechanic: promo.retailerPromotion.promotionMechanic.name,
              discountPercent: (
                ((basePrice - promotedPrice) / basePrice) *
                100
              ).toFixed(2),
              discountValue: (basePrice - promotedPrice).toFixed(2),
              promotedPrice,
              startDate,
              endDate,
              period: range.reduce(
                (obj, date) => ({ ...obj, [date]: false }),
                {},
              ),
            };
          }
          promoItem.startDate = moment
            .min([
              moment(promoItem.startDate, dateFormat, true),
              moment(startDate, dateFormat, true),
            ])
            .format(dateFormat);
          promoItem.endDate = moment
            .max([
              moment(promoItem.endDate, dateFormat, true),
              moment(endDate, dateFormat, true),
            ])
            .format(dateFormat);
          const diff = moment(endDate, dateFormat, true).diff(
            moment(startDate, dateFormat, true),
            'days',
          );
          // eslint-disable-next-line no-plusplus
          for (let i = 0; i <= diff; i++) {
            const date = moment(startDate, dateFormat, true)
              .add(i, 'days')
              .format(dateFormat);
            if (date in promoItem.period) promoItem.period[date] = true;
          }
          // eslint-disable-next-line max-len
          acc[item1.id].children[item2.id].products[row.coreProductId].promotions[
            promotionKey
          ] = promoItem;
        });
        return acc;
      }, {});
  
      const rows = PromotionService.prepareCalendarResult(grouped, range);
  
      if (data.groupBy === 'brand') {
        rows.sort((a, b) => a.label.localeCompare(b.label));
      } else {
        const retailersMap = CommonUtil.arrayToObject(
          filteredData.retailers,
          'name',
        );
  
        CommonUtil.sortRetailers(rows, retailersOrder, retailersMap, 'label');
      }
      return {
        productsCount: productsCount.size,
        // eslint-disable-next-line max-len
        avgDiscountPercent: CommonUtil.average(
          rows.map(({ discountPercent }) => discountPercent).filter(Boolean),
        ),
        // eslint-disable-next-line max-len
        avgDiscountValue: CommonUtil.average(
          rows.map(({ discountValue }) => discountValue).filter(Boolean),
        ),
        rows,
      };
    }
  
    /**
     * Makes query to get promotions based on available core products
     * @param userId
     * @param data - user query
     * @param filteredData - filtered data on user filters
     * @returns {Promise<[]>}
     */
    static async getPromotions(user, data, filteredData) {
      const dateFormat = 'MM/DD/YYYY';
      const timePeriod = CommonUtil.timePeriodToObject(data.timePeriod);
      const dates = await this.getDatesIds(timePeriod);
  
      const productWhere = {
        coreProductId: Object.keys(filteredData.products),
        dateId: dates.map(d => d.id),
      };
  
      productWhere.retailerId = CommonUtil.getRetailersIdsForQuery(
        data.sourceType,
        filteredData,
      );
  
      const retailerPromotionsWhere = {};
  
      if (data.mechanic[0] !== 'All') {
        retailerPromotionsWhere.promotionMechanicId = data.mechanic;
      }
  
      const products = await db.product.findAll({
        attributes: [
          'coreProductId',
          'productTitle',
          'basePrice',
          'promotedPrice',
          'date',
          'ean',
          'sourceId',
          'retailerId',
        ],
        where: productWhere,
        required: true,
        include: [
          {
            attributes: { exclude: ['updatedAt'] },
            model: db.promotion,
            as: 'productPromotions',
            required: true,
            include: [
              {
                attributes: ['retailerId', 'promotionMechanicId'],
                model: db.retailerPromotion,
                as: 'retailerPromotion',
                include: [
                  {
                    attributes: ['name'],
                    model: db.promotionMechanic,
                    as: 'promotionMechanic',
                    required: true,
                  },
                ],
                where: retailerPromotionsWhere,
                required: true,
              },
            ],
          },
        ],
      });
  
      const promotions = {};
      for (const product of products) {
        for (const productPromotion of product.productPromotions) {
          const startDate = moment(
            new Date(productPromotion.startDate || product.date),
          ).format(dateFormat);
          const endDate = moment(
            new Date(productPromotion.endDate || product.date),
          ).format(dateFormat);
          const promoId =
            productPromotion.promoId ||
            PromotionServiceV1.getDefaultPromoId(product.toJSON(), {
              ...productPromotion.toJSON(),
              startDate,
            });
          const promotionKey = PromotionServiceV1.getPromoKey(
            promotions,
            product,
            productPromotion,
            promoId,
          );
  
          if (!promotions[promotionKey]) {
            promotions[promotionKey] = {
              promoId,
              promotionKey,
              description: productPromotion.description,
              products: [],
              dates: [],
              retailerPromotion: productPromotion.retailerPromotion.toJSON(),
            };
          }
          const promotion = promotions[promotionKey];
          promotion.products.push({
            basePrice: CommonUtil.preparePrice(product.basePrice),
            promotedPrice: CommonUtil.preparePrice(product.promotedPrice),
            coreProductId: product.coreProductId,
            productTitle: product.productTitle,
            sourceId: product.sourceId,
            ean: product.ean,
            date: product.date,
            startDate,
            endDate,
            description: productPromotion.description,
          });
  
          promotion.dates.push({ startDate, endDate });
        }
      }
  
      return Object.values(promotions);
    }
  
    /**
     * Get summary about promotions
     * @param user
     * @param data
     * @returns {Promise<{byRetailer: {}, byBrand: {}}>}
     */
    static async getSummary(user, data) {
      const { retailers: retailersOrder } = user;
      const { discountRange, discountType = ['percent'] } = data;
  
      const filteredData = await FiltersService.getNewFilters(user, data);
      const promotions = await this.getPromotions(user, data, filteredData);
      const timePeriod = CommonUtil.timePeriodToObject(data.timePeriod);
      const days = CommonUtil.getTimePeriodDays(data.timePeriod);
  
      const parsedPromotions = this.parsePromotions(
        promotions,
        filteredData,
        timePeriod,
        promotion => promotion.promotionKey,
      );
  
      const { range, filteredPromotions } = this.filterPromotions(
        parsedPromotions,
        days,
        discountType,
        discountRange,
      );
  
      const overallData = this.getAverageDiscount(filteredPromotions, days);
  
      const groupedSummaryData = this.groupSummaryData(
        filteredPromotions,
        days,
        filteredData,
      );
  
      const byRetailer = this.getSummaryByType(
        groupedSummaryData,
        filteredData,
        'retailer',
      );
  
      const retailersMap = CommonUtil.arrayToObject(
        filteredData.retailers,
        'name',
      );
  
      CommonUtil.sortRetailers(
        byRetailer.data,
        retailersOrder,
        retailersMap,
        'title',
      );
  
      const byBrand = this.getSummaryByType(
        groupedSummaryData,
        filteredData,
        'brand',
      );
  
      return { ...overallData, range, byRetailer, byBrand };
    }
  
    /**
     * Parse database promotions and group them
     * @param promotions
     * @param filteredData
     * @param timePeriod
     * @param keyFunction
     * @returns {{}}
     */
    static parsePromotions(promotions, filteredData, timePeriod, keyFunction) {
      const parsedPromotions = this.calculatePromotionsDates(
        promotions,
        timePeriod,
        keyFunction,
      );
  
      // group products of promotions by core products
      for (const promotion of promotions) {
        const parsedPromotion = parsedPromotions[keyFunction(promotion)];
        const promotionProducts = {};
        for (const product of promotion.products) {
          const filteredProduct = filteredData.products[product.coreProductId];
          if (filteredProduct && !promotionProducts[product.coreProductId]) {
            promotionProducts[product.coreProductId] = {
              ...filteredProduct,
              retailerId: promotion.retailerPromotion.retailerId,
              productTitle: product.productTitle,
              sourceId: product.sourceId,
              ean: product.ean,
              prices: [],
            };
          }
          if (promotionProducts[product.coreProductId]) {
            const date = moment(product.date).startOf('day');
            if (
              date.isSameOrAfter(parsedPromotion.startDate) &&
              date.isSameOrBefore(parsedPromotion.endDate)
            ) {
              promotionProducts[product.coreProductId].prices.push({
                basePrice: product.basePrice,
                promotedPrice: product.promotedPrice,
                date: date.format('YYYY-MM-DD'),
              });
            }
          }
        }
        parsedPromotion.products = promotionProducts;
      }
      return parsedPromotions;
    }
  
    /**
     * Calculates promotions dates
     * @param promotions
     * @param timePeriod
     * @param keyFunction
     * @param canDateBeOutsideOfRange
     * @returns {{}}
     */
    static calculatePromotionsDates(
      promotions,
      timePeriod,
      keyFunction,
      canDateBeOutsideOfRange = false,
    ) {
      const dateFormat = 'M/D/YYYY';
      const parsedPromotions = {};
      // group promotions by promoId and get their dates
      for (const promotion of promotions) {
        const parsedPromotion = {
          promotion,
          promoId: `${promotion.promoId}`,
          description: promotion.description,
          retailerId: promotion.retailerPromotion.retailerId,
          mechanicId: promotion.retailerPromotion.promotionMechanicId,
          mechanicName: promotion.retailerPromotion.promotionMechanic.name,
        };
  
        const timePeriodNew = moment(timePeriod.new);
        const timePeriodOld = moment(timePeriod.old);
        let promotionStartDate = moment().format(dateFormat);
        let promotionEndDate = moment(0).format(dateFormat);
  
        for (const date of promotion.dates) {
          const { startDate, endDate } = date;
  
          const startDay = moment(startDate, dateFormat, true);
          const endDay = moment(endDate, dateFormat, true);
          const start = moment(promotionStartDate, dateFormat, true);
          const end = moment(promotionEndDate, dateFormat, true);
          promotionStartDate = moment.min(start, startDay);
          promotionEndDate = moment.max(end, endDay);
        }
        if (canDateBeOutsideOfRange) {
          parsedPromotion.startDate = promotionStartDate || timePeriodNew;
          parsedPromotion.endDate = promotionEndDate || timePeriodOld;
        } else {
          parsedPromotion.startDate = moment.max(
            moment(promotionStartDate),
            timePeriodOld,
          );
          parsedPromotion.endDate = moment.min(
            moment(promotionEndDate),
            timePeriodNew,
          );
        }
  
        parsedPromotion.actualPromotionStartDate = promotionStartDate;
        parsedPromotion.actualPromotionEndDate = promotionEndDate;
  
        parsedPromotions[keyFunction(promotion)] = parsedPromotion;
      }
      return parsedPromotions;
    }
  
    /**
     * Get price trend by groupKey, including topPromotioners
     * @param promotions
     * @param days
     * @param groupKey - all promotions will be grouped by this key
     * @param fieldsMap
     * @returns {{data: [], promotioners: {}}}
     */
    static getPromotionsByItem(promotions, days, groupKey, fieldsMap) {
      const { groupedMap, discounts } = this.groupPromotionsByKey(
        promotions,
        days,
        groupKey,
        fieldsMap,
      );
  
      const formattedData = this.formatPromotionSummaryByKey(
        discounts,
        groupedMap,
      );
  
      return {
        promotioners: this.getPromotioners(formattedData),
        data: formattedData,
      };
    }
  
    static groupSummaryData(promotions, days, filteredData) {
      const brandsData = this.groupPromotionsByKey(
        promotions,
        days,
        (product, promotion) =>
          `${product.retailerId}_${product.brandId}_${promotion.mechanicId}`,
        {
          title: product => {
            const retailerName = filteredData.retailers.find(
              ({ id }) => id === product.retailerId,
            ).name;
            const brandName = FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).name;
            return `${retailerName} > ${brandName}`;
          },
          color: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).color,
          brandId: 'brandId',
          retailerId: 'retailerId',
          mechanicId: (product, promotion) => promotion.mechanicId,
        },
      );
  
      return this.groupPromotionsByRetailerBrands(brandsData);
    }
  
    static getSummaryByType(brandsDiscounts, filteredData, by = 'retailer') {
      const parentDiscounts = {};
      for (const itemKey of Object.keys(brandsDiscounts)) {
        const brandDiscount = brandsDiscounts[itemKey];
        const keyProperty = by === 'retailer' ? 'retailerId' : 'brandId';
        const groupKey = brandDiscount[keyProperty];
  
        if (!parentDiscounts[groupKey]) {
          parentDiscounts[groupKey] = {
            [keyProperty]: groupKey,
            productsIds: new Set(),
            promotions: brandDiscount.promotions,
            startDate: brandDiscount.startDate,
            endDate: brandDiscount.endDate,
            discounts: [],
            discountsPercents: [],
          };
        }
  
        parentDiscounts[groupKey].productsIds = new Set([
          ...parentDiscounts[groupKey].productsIds,
          ...brandDiscount.productsIds,
        ]);
        parentDiscounts[groupKey].promotions = new Set([
          ...parentDiscounts[groupKey].promotions,
          ...brandDiscount.promotions,
        ]);
        parentDiscounts[groupKey].startDate = moment.min(
          parentDiscounts[groupKey].startDate,
          brandDiscount.startDate,
        );
        parentDiscounts[groupKey].endDate = moment.max(
          parentDiscounts[groupKey].endDate,
          brandDiscount.endDate,
        );
  
        const averageDiscount = CommonUtil.average(brandDiscount.discounts);
        const averageDiscountPercent = CommonUtil.average(
          brandDiscount.discountsPercents,
        );
  
        parentDiscounts[groupKey].discounts.push(averageDiscount);
        parentDiscounts[groupKey].discountsPercents.push(averageDiscountPercent);
      }
  
      let retailersBrandsSummaries;
      if (by === 'retailer') {
        retailersBrandsSummaries = this.getSummaryForRetailerBrands(
          brandsDiscounts,
        );
      }
  
      const formattedRetailersDiscounts = [];
      for (const key of Object.keys(parentDiscounts)) {
        const parentDiscount = parentDiscounts[key];
        let promotionsByKey;
        if (parentDiscount.promotions) {
          promotionsByKey = parentDiscount.promotions.size;
        }
  
        let duration;
        if (parentDiscount.endDate) {
          duration = parentDiscount.endDate.diff(parentDiscount.startDate, 'day');
        }
  
        const averageDiscount = CommonUtil.average(parentDiscount.discounts);
        const averageDiscountPercent = CommonUtil.average(
          parentDiscount.discountsPercents,
        );
  
        let parent;
        if (by === 'retailer') {
          parent = filteredData.retailers.find(
            r => r.id === parentDiscount.retailerId,
          );
        } else {
          parent = FiltersService.getFilteredItem(
            filteredData,
            'brands',
            parentDiscount.brandId,
          );
        }
  
        const item = {
          title: parent.name,
          color: parent.color,
          products: parentDiscount.productsIds.size,
          promotions: promotionsByKey,
          duration,
          averageDiscount,
          averageDiscountPercent,
        };
  
        if (by === 'retailer') {
          const retailersBrandsDiscount =
            retailersBrandsSummaries[parentDiscount.retailerId];
  
          item.brands = {
            data: retailersBrandsDiscount,
            promotioners: this.getPromotioners(
              retailersBrandsDiscount.map(brand => ({
                ...brand,
                title: brand.title.split(' > ')[1],
              })),
            ),
          };
        }
        formattedRetailersDiscounts.push(item);
      }
  
      return {
        data: formattedRetailersDiscounts,
        promotioners: this.getPromotioners(formattedRetailersDiscounts),
      };
    }
  
    static getSummaryForRetailerBrands(brandsDiscounts) {
      const retailersBrandsDiscounts = {};
      for (const key of Object.keys(brandsDiscounts)) {
        const brandDiscount = brandsDiscounts[key];
        let promotionsByKey;
        if (brandDiscount.promotions) {
          promotionsByKey = brandDiscount.promotions.size;
        }
  
        let duration;
        if (brandDiscount.endDate) {
          duration = brandDiscount.endDate.diff(brandDiscount.startDate, 'day');
        }
  
        const averageDiscount = CommonUtil.average(brandDiscount.discounts);
        const averageDiscountPercent = CommonUtil.average(
          brandDiscount.discountsPercents,
        );
  
        const item = {
          title: brandDiscount.title,
          color: brandDiscount.color,
          products: brandDiscount.productsIds.size,
          promotions: promotionsByKey,
          duration,
          averageDiscount,
          averageDiscountPercent,
        };
  
        if (!retailersBrandsDiscounts[brandDiscount.retailerId]) {
          retailersBrandsDiscounts[brandDiscount.retailerId] = [];
        }
        retailersBrandsDiscounts[brandDiscount.retailerId].push(item);
      }
      return retailersBrandsDiscounts;
    }
  
    static groupPromotionsByRetailerBrands(brandsData) {
      const brandsMechanicDiscounts = {};
      for (const discountKey of Object.keys(brandsData.discounts)) {
        const coreProducts = brandsData.discounts[discountKey];
        const dataByKey = brandsData.groupedMap.get(discountKey);
  
        for (const coreProductId of Object.keys(coreProducts)) {
          const averageDiscounts = coreProducts[coreProductId].averageDiscounts;
          const averageDiscountsPercent =
            coreProducts[coreProductId].averageDiscountsPercent;
  
          const key = `${dataByKey.brandId}_${dataByKey.retailerId}_${dataByKey.mechanicId}`;
          if (!brandsMechanicDiscounts[key]) {
            brandsMechanicDiscounts[key] = {
              ...dataByKey,
              discounts: [],
              discountsPercents: [],
              productsIds: new Set(),
            };
          }
  
          brandsMechanicDiscounts[key].productsIds.add(coreProductId);
          brandsMechanicDiscounts[key].discounts.push(...averageDiscounts);
          brandsMechanicDiscounts[key].discountsPercents.push(
            ...averageDiscountsPercent,
          );
        }
      }
  
      const brandsDiscounts = {};
      for (const brandMechanicKey of Object.keys(brandsMechanicDiscounts)) {
        const brandMechanicDiscount = brandsMechanicDiscounts[brandMechanicKey];
  
        const key = `${brandMechanicDiscount.brandId}_${brandMechanicDiscount.retailerId}`;
        if (!brandsDiscounts[key]) {
          brandsDiscounts[key] = {
            ...brandMechanicDiscount,
            productsIds: new Set(),
            discounts: [],
            discountsPercents: [],
          };
        }
  
        brandsDiscounts[key].productsIds = new Set([
          ...brandsDiscounts[key].productsIds,
          ...brandMechanicDiscount.productsIds,
        ]);
        brandsDiscounts[key].promotions = new Set([
          ...brandsDiscounts[key].promotions,
          ...brandMechanicDiscount.promotions,
        ]);
        brandsDiscounts[key].startDate = moment.min(
          brandsDiscounts[key].startDate,
          brandMechanicDiscount.startDate,
        );
        brandsDiscounts[key].endDate = moment.max(
          brandsDiscounts[key].endDate,
          brandMechanicDiscount.endDate,
        );
  
        const averageDiscount = CommonUtil.average(
          brandMechanicDiscount.discounts,
        );
        const averageDiscountPercent = CommonUtil.average(
          brandMechanicDiscount.discountsPercents,
        );
  
        brandsDiscounts[key].discounts.push(averageDiscount);
        brandsDiscounts[key].discountsPercents.push(averageDiscountPercent);
      }
      return brandsDiscounts;
    }
  
    static formatSinglePromotionSummaryByKey(coreProducts, dataByKey) {
      const discounts = [];
      const discountsPercent = [];
  
      for (const coreProductId of Object.keys(coreProducts)) {
        const { averageDiscounts, averageDiscountsPercent } = coreProducts[
          coreProductId
        ];
        discounts.push(...averageDiscounts);
        discountsPercent.push(...averageDiscountsPercent);
      }
  
      const averageDiscount = CommonUtil.average(discounts);
      const averageDiscountPercent = CommonUtil.average(discountsPercent);
  
      let promotions;
      if (dataByKey.promotions) {
        promotions = dataByKey.promotions.size;
      }
  
      let duration;
      if (dataByKey.endDate) {
        duration = dataByKey.endDate.diff(dataByKey.startDate, 'day');
      }
  
      return {
        title: dataByKey.title,
        color: dataByKey.color,
        products: Object.keys(coreProducts).length,
        promotions,
        duration,
        averageDiscount,
        averageDiscountPercent,
      };
    }
  
    static formatPromotionSummaryByKey(discounts, groupedMap) {
      const formattedData = [];
      for (const key of Object.keys(discounts)) {
        const item = this.formatSinglePromotionSummaryByKey(
          discounts[key],
          groupedMap.get(key),
        );
        formattedData.push(item);
      }
      return formattedData;
    }
  
    /**
     * Filter promotions by highest and lowest values base on discount type
     * @param promotions
     * @param days - array of days
     * @param type - discount type. percent or value
     * @param discountRange
     * @returns {{}}
     */
    static filterPromotions(promotions, days, type = ['percent'], discountRange) {
      const range = {
        percent: { min: 0, max: 0 },
        value: { min: 0, max: 0 },
      };
      const filteredPromotions = {};
      for (const promotionKey of Object.keys(promotions)) {
        const promotion = promotions[promotionKey];
        const {
          averageDiscount,
          averageDiscountPercent,
        } = this.getPromotionAverageDiscount(promotion, days);
  
        let discount;
        if (type[0] === 'percent') {
          discount = averageDiscountPercent || '0';
        } else if (type[0] === 'value') {
          discount = averageDiscount || '0';
        }
  
        // eslint-disable-next-line max-len
        if (range.percent.min > averageDiscountPercent || !range.percent.min)
          range.percent.min = averageDiscountPercent;
        if (range.percent.max < averageDiscountPercent)
          range.percent.max = averageDiscountPercent;
        if (range.value.min > averageDiscount || !range.value.min)
          range.value.min = averageDiscount;
        if (range.value.max < averageDiscount) range.value.max = averageDiscount;
  
        let promotionShouldStay = true;
  
        if (discountRange[0] !== 'All') {
          const [lowestValue, highestValue] = discountRange[0].split('-');
          if (parseFloat(lowestValue) > discount) {
            promotionShouldStay = false;
          }
          if (discount > parseFloat(highestValue)) {
            promotionShouldStay = false;
          }
        }
  
        if (promotionShouldStay) {
          filteredPromotions[promotionKey] = promotion;
        }
      }
      return { range, filteredPromotions };
    }
  
    /**
     * Get average discount for one coreproduct in one promotion
     * @param coreProduct
     * @returns {{averageDiscount: (*|number), averageDiscountPercent: (*|number)}}
     */
    static getPromotionCoreProductAverageDiscount(coreProduct) {
      const coreProductPrice = coreProduct.prices[0];
      if (!coreProductPrice) {
        return { averageDiscount: 0, averageDiscountPercent: 0 };
      }
      let basePrice = 0;
      let promotedPrice = 0;
      if (coreProductPrice.basePrice) {
        basePrice = parseFloat(coreProductPrice.basePrice.replace('£', ''));
      }
      if (coreProductPrice.promotedPrice) {
        promotedPrice = parseFloat(
          coreProductPrice.promotedPrice.replace('£', ''),
        );
      }
  
      let discount = basePrice - promotedPrice;
      let discountPercent = ((basePrice - promotedPrice) / basePrice) * 100;
      if (discount < 0) {
        discount = 0;
        discountPercent = 0;
      }
  
      return {
        averageDiscount: discount,
        averageDiscountPercent: discountPercent,
      };
    }
  
    /**
     * Group products and prices by groupKey
     * @param promotions
     * @param days
     * @param {function|string} groupKey - all promotions will be grouped by this key
     * @param fieldsMap
     * @returns {{groupedMap: Map<any, any>, discounts: {}}}
     */
    static groupPromotionsByKey(promotions, days, groupKey, fieldsMap = {}) {
      const groupedMap = new Map();
      const discounts = {};
  
      for (const promoId of Object.keys(promotions)) {
        const promotion = promotions[promoId];
  
        for (const coreProductId of Object.keys(promotion.products)) {
          const coreProduct = promotion.products[coreProductId];
  
          let mapKey;
          if (typeof groupKey === 'function') {
            mapKey = groupKey(coreProduct, promotion);
          } else {
            mapKey = get(coreProduct, groupKey, 'No brand');
          }
          if (!mapKey) {
            // eslint-disable-next-line no-continue
            continue;
          }
          mapKey = mapKey.toString();
  
          let groupedData = groupedMap.get(mapKey);
  
          if (!groupedMap.has(mapKey)) {
            groupedData = {
              promotions: new Set(),
              startDate: promotion.startDate,
              endDate: promotion.endDate,
            };
            for (const field of Object.keys(fieldsMap)) {
              const property = fieldsMap[field];
              if (typeof property === 'function') {
                groupedData[field] = property(coreProduct, promotion);
              } else {
                groupedData[field] = get(coreProduct, property);
              }
            }
            groupedMap.set(mapKey, groupedData);
            discounts[mapKey] = {};
          }
          if (!groupedData.promotions.has(promoId)) {
            groupedData.promotions.add(promoId);
          }
          groupedData.startDate = moment.min(
            groupedData.startDate,
            promotion.startDate,
          );
          groupedData.endDate = moment.max(
            groupedData.endDate,
            promotion.endDate,
          );
  
          const {
            averageDiscount,
            averageDiscountPercent,
          } = this.getPromotionCoreProductAverageDiscount(coreProduct);
  
          if (averageDiscount !== 0) {
            if (!discounts[mapKey][coreProductId]) {
              discounts[mapKey][coreProductId] = {
                averageDiscounts: [],
                averageDiscountsPercent: [],
              };
            }
  
            discounts[mapKey][coreProductId].averageDiscounts.push(
              averageDiscount,
            );
            discounts[mapKey][coreProductId].averageDiscountsPercent.push(
              averageDiscountPercent,
            );
          }
        }
      }
  
      return { discounts, groupedMap };
    }
  
    /**
     * Gets all types of promotioners
     * @param formattedData
     * @returns {{byProductsMax: *, byDurationMax: *, byDiscountMax: *, byDiscountMin: *,
     * byProductsMin: *, byDiscountPercentMax: *, byDurationMin: *, byDiscountPercentMin: *}}
     */
    static getPromotioners(formattedData) {
      const byProductsMax = this.getPromotionersByField(
        formattedData,
        'products',
        'asc',
      );
      const byDurationMax = this.getPromotionersByField(
        formattedData,
        'duration',
        'asc',
      );
      const byDiscountMax = this.getPromotionersByField(
        formattedData,
        'averageDiscount',
        'asc',
      );
      const byDiscountPercentMax = this.getPromotionersByField(
        formattedData,
        'averageDiscountPercent',
        'asc',
      );
      const byProductsMin = this.getPromotionersByField(
        formattedData,
        'products',
        'desc',
      );
      const byDurationMin = this.getPromotionersByField(
        formattedData,
        'duration',
        'desc',
      );
      const byDiscountMin = this.getPromotionersByField(
        formattedData,
        'averageDiscount',
        'desc',
      );
      const byDiscountPercentMin = this.getPromotionersByField(
        formattedData,
        'averageDiscountPercent',
        'desc',
      );
  
      return {
        byProductsMax,
        byDurationMax,
        byDiscountMax,
        byDiscountPercentMax,
        byProductsMin,
        byDurationMin,
        byDiscountMin,
        byDiscountPercentMin,
      };
    }
  
    /**
     * Sorts discount data by field and gets top 10 promotioners
     * @param promotioners
     * @param field
     * @param order
     * @returns {*}
     */
    static getPromotionersByField(promotioners, field, order = 'asc') {
      return promotioners
        .sort((a, b) => {
          if (order.toLowerCase() === 'asc') {
            return b[field] - a[field];
          }
          return a[field] - b[field];
        })
        .map(item =>
          pick(item, [
            'title',
            'color',
            'products',
            'promotions',
            'duration',
            'averageDiscount',
            'averageDiscountPercent',
          ]),
        )
        .slice(0, 10);
    }
  
    /**
     * Gets promotions breakdown
     * @param user
     * @param data
     * @returns {Promise<{byRetailer: {}, byBrand: {}}>}
     */
    static async getPromotionsBreakdown(user, data) {
      const { retailers: retailersOrder } = user;
  
      const { discountRange, discountType = ['percent'] } = data;
  
      const filteredData = await FiltersService.getNewFilters(user, data);
      const promotions = await this.getPromotions(user, data, filteredData);
      const timePeriod = CommonUtil.timePeriodToObject(data.timePeriod);
      const days = CommonUtil.getTimePeriodDays(data.timePeriod);
  
      const parsedPromotions = this.parsePromotions(
        promotions,
        filteredData,
        timePeriod,
        promotion => promotion.promotionKey,
      );
  
      const { range, filteredPromotions } = this.filterPromotions(
        parsedPromotions,
        days,
        discountType,
        discountRange,
      );
  
      const overallData = this.getAverageDiscount(filteredPromotions, days);
      const promotionMechanics = await db.promotionMechanic.findAll({
        raw: true,
      });
  
      const byRetailer = this.getBreakdownByItem(
        filteredPromotions,
        days,
        'retailerId',
        {
          title: product =>
            filteredData.retailers.find(({ id }) => id === product.retailerId)
              .name,
          color: product =>
            filteredData.retailers.find(({ id }) => id === product.retailerId)
              .color,
        },
        promotionMechanics,
      );
  
      const retailersMap = CommonUtil.arrayToObject(
        filteredData.retailers,
        'name',
      );
  
      CommonUtil.sortRetailers(
        byRetailer.data,
        retailersOrder,
        retailersMap,
        'title',
      );
      byRetailer.data = byRetailer.data.map(r => ({
        ...r,
        id: retailersMap[r['title']].id,
      }));
  
      CommonUtil.sortRetailers(
        byRetailer.totalRatio,
        retailersOrder,
        retailersMap,
        'title',
      );
      byRetailer.totalRatio = byRetailer.totalRatio.map(r => ({
        ...r,
        id: retailersMap[r['title']].id,
      }));
  
      const byBrand = this.getBreakdownByItem(
        filteredPromotions,
        days,
        product => product.brandId || 'No brand',
        {
          title: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).name,
          color: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).color,
        },
        promotionMechanics,
      );
  
      CommonUtil.sort(byBrand.data, 'title');
      CommonUtil.sort(byBrand.totalRatio, 'title');
  
      return { ...overallData, range, byRetailer, byBrand, success: true };
    }
  
    /**
     * Gets promotion breakdown by groupKey
     * @param promotions
     * @param days
     * @param groupKey - all promotions will be grouped by this key
     * @param fieldsMap
     * @param promotionMechanics
     * @returns {{data: [], promotioners: {}}}
     */
    static getBreakdownByItem(
      promotions,
      days,
      groupKey,
      fieldsMap,
      promotionMechanics,
    ) {
      const { groupedMap, prices } = this.groupPromotionsBreakdownByKey(
        promotions,
        days,
        groupKey,
        fieldsMap,
      );
  
      let overall = 0;
      const formattedData = [];
      const totalRatio = {};
  
      // calculate totalRation for circle chart
      for (const key of groupedMap.keys()) {
        const groupedValue = groupedMap.get(key);
        totalRatio[key] = {
          title: groupedValue.title,
          color: groupedValue.color,
          products: groupedValue.products.size,
        };
        overall += groupedValue.products.size;
      }
  
      for (const key of Object.keys(totalRatio)) {
        totalRatio[key].percent = (
          (totalRatio[key].products / overall) *
          100
        ).toFixed(2);
      }
  
      for (const key of groupedMap.keys()) {
        const groupedValue = groupedMap.get(key);
  
        const {
          averageDiscount,
          averageDiscountPercent,
        } = this.formatSinglePromotionSummaryByKey(prices[key], groupedValue);
  
        const formattedItem = {
          title: groupedValue.title,
          color: groupedValue.color,
          promotionActivity: totalRatio[key].percent,
          activity: [],
          averageDiscount,
          averageDiscountPercent,
        };
  
        for (const mechanic of promotionMechanics) {
          const productsByPromotionTypes =
            groupedValue.productsByPromotionTypes[mechanic.id];
          formattedItem.activity.push({
            id: mechanic.id,
            title: mechanic.name,
            products: productsByPromotionTypes
              ? productsByPromotionTypes.size
              : 0,
          });
        }
        formattedData.push(formattedItem);
      }
      return {
        overall,
        totalRatio: Object.values(totalRatio),
        data: formattedData,
      };
    }
  
    /**
     * Group promotions by groupKey and promotion type
     * @param promotions
     * @param days
     * @param {function|string} groupKey - all promotions will be grouped by this key
     * @param fieldsMap
     * @returns {{groupedMap: Map<any, any>}}
     */
    static groupPromotionsBreakdownByKey(
      promotions,
      days,
      groupKey,
      fieldsMap = {},
    ) {
      const groupedMap = new Map();
      const prices = {};
  
      for (const promoId of Object.keys(promotions)) {
        const promotion = promotions[promoId];
  
        for (const coreProductId of Object.keys(promotion.products)) {
          const coreProduct = promotion.products[coreProductId];
  
          let mapKey;
          if (typeof groupKey === 'function') {
            mapKey = groupKey(coreProduct);
          } else {
            mapKey = get(coreProduct, groupKey);
          }
          if (!mapKey) {
            // eslint-disable-next-line no-continue
            continue;
          }
          mapKey = mapKey.toString();
  
          let groupedData = groupedMap.get(mapKey);
  
          if (!groupedMap.has(mapKey)) {
            groupedData = {
              promotions: new Set(),
              productsByPromotionTypes: {},
              products: new Set(),
            };
            for (const field of Object.keys(fieldsMap)) {
              const property = fieldsMap[field];
              if (typeof property === 'function') {
                groupedData[field] = property(coreProduct);
              } else {
                groupedData[field] = get(coreProduct, property);
              }
            }
            groupedMap.set(mapKey, groupedData);
            prices[mapKey] = {};
          }
          groupedData.promotions.add(promoId);
          groupedData.products.add(coreProductId);
  
          if (!groupedData.productsByPromotionTypes[promotion.mechanicId]) {
            groupedData.productsByPromotionTypes[
              promotion.mechanicId
            ] = new Set();
          }
          groupedData.productsByPromotionTypes[promotion.mechanicId].add(
            coreProductId,
          );
  
          const {
            averageDiscount,
            averageDiscountPercent,
          } = this.getPromotionCoreProductAverageDiscount(coreProduct);
  
          if (!prices[mapKey][coreProductId]) {
            prices[mapKey][coreProductId] = {
              averageDiscounts: [],
              averageDiscountsPercent: [],
            };
          }
          prices[mapKey][coreProductId].averageDiscounts.push(averageDiscount);
          prices[mapKey][coreProductId].averageDiscountsPercent.push(
            averageDiscountPercent,
          );
        }
      }
      return { prices, groupedMap };
    }
  
    /**
     * Gets discount cut by retailers and brands
     * @param user
     * @param data
     * @returns {Promise<{byRetailer: {}, byBrand: {}}>}
     */
    static async getDiscountCut(user, data) {
      const { retailers: retailersOrder } = user;
  
      const { discountRange, discountType = ['percent'] } = data;
  
      const filteredData = await FiltersService.getNewFilters(user, data);
      const promotions = await this.getPromotions(user, data, filteredData);
  
      const timePeriod = CommonUtil.timePeriodToObject(data.timePeriod);
  
      const parsedPromotions = this.parsePromotions(
        promotions,
        filteredData,
        timePeriod,
        promotion => promotion.promotionKey,
      );
  
      const days = CommonUtil.getTimePeriodDays(data.timePeriod);
  
      const { range, filteredPromotions } = this.filterPromotions(
        parsedPromotions,
        days,
        discountType,
        discountRange,
      );
  
      const overallData = this.getAverageDiscount(filteredPromotions, days);
      const promotionMechanics = await db.promotionMechanic.findAll({
        raw: true,
      });
      const filteredRetailers = CommonUtil.getFilteredItems(
        filteredData.retailers,
        data.sourceType,
      );
      const filteredBrands = CommonUtil.getFilteredItems(
        filteredData.brands,
        data.productBrand,
      );
  
      const make = row => ({
        title: row.name,
        color: row.color,
        promotions: [
          {
            id: 1,
            title: 'Price Cut',
            averageDiscount: 0,
            averageDiscountPercent: 0,
          },
          {
            id: 2,
            title: 'Multibuy',
            averageDiscount: 0,
            averageDiscountPercent: 0,
          },
          {
            id: 3,
            title: 'Other',
            averageDiscount: 0,
            averageDiscountPercent: 0,
          },
        ],
        averageDiscount: 0,
        averageDiscountPercent: 0,
      });
  
      const byRetailer = this.getDiscountCutByItem(
        filteredPromotions,
        days,
        (product, promotion) => `${product.retailerId}_${promotion.mechanicId}`,
        {
          id: product =>
            filteredData.retailers.find(({ id }) => id === product.retailerId).id,
          title: product =>
            filteredData.retailers.find(({ id }) => id === product.retailerId)
              .name,
          color: product =>
            filteredData.retailers.find(({ id }) => id === product.retailerId)
              .color,
        },
        promotionMechanics,
      );
      byRetailer.data = CommonUtil.fillFilteredItems(
        filteredRetailers,
        byRetailer.data,
        make,
      );
  
      const retailersMap = CommonUtil.arrayToObject(
        filteredData.retailers,
        'name',
      );
  
      CommonUtil.sortRetailers(
        byRetailer.data,
        retailersOrder,
        retailersMap,
        'title',
      );
      byRetailer.data = byRetailer.data.map(r => ({
        ...r,
        id: retailersMap[r['title']].id,
      }));
  
      const byBrand = this.getDiscountCutByItem(
        filteredPromotions,
        days,
        (product, promotion) => `${product.brandId}_${promotion.mechanicId}`,
        {
          id: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).id,
          title: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).name,
          color: product =>
            FiltersService.getFilteredItem(
              filteredData,
              'brands',
              product.brandId,
            ).color,
        },
        promotionMechanics,
      );
      byBrand.data = CommonUtil.fillFilteredItems(
        filteredBrands,
        byBrand.data,
        make,
      );
  
      return { ...overallData, range, byRetailer, byBrand, success: true };
    }
  
    /**
     * Get promotions discount cut grouped by groupKey
     * @param promotions
     * @param days
     * @param groupKey - all promotions will be grouped by this key
     * @param fieldsMap
     * @param promotionMechanics
     * @returns {{data: unknown[]}}
     */
    static getDiscountCutByItem(
      promotions,
      days,
      groupKey,
      fieldsMap,
      promotionMechanics,
    ) {
      const { discounts, groupedMap } = this.groupPromotionsByKey(
        promotions,
        days,
        groupKey,
        fieldsMap,
      );
  
      // store average discount divided by promotions mechanics
      const averageDiscountByKeyAndMechanic = {};
      // store average discount by key
      const discountsByKey = {};
  
      // calculate average prices for each key and mechanic
      for (const priceKey of Object.keys(discounts)) {
        const [key, promotionType] = priceKey.split('_');
        if (!averageDiscountByKeyAndMechanic[key]) {
          averageDiscountByKeyAndMechanic[key] = {
            id: groupedMap.get(priceKey).id,
            title: groupedMap.get(priceKey).title,
            color: groupedMap.get(priceKey).color,
            promotions: [],
          };
  
          for (const { id, name } of promotionMechanics) {
            averageDiscountByKeyAndMechanic[key].promotions.push({
              id,
              title: name,
              averageDiscount: 0,
              averageDiscountPercent: 0,
            });
          }
        }
  
        if (!discountsByKey[key]) {
          discountsByKey[key] = {
            averageDiscounts: [],
            averageDiscountsPercent: [],
          };
        }
  
        const discountsValues = [];
        const discountsPercents = [];
        for (const coreProductId of Object.keys(discounts[priceKey])) {
          const { averageDiscounts, averageDiscountsPercent } = discounts[
            priceKey
          ][coreProductId];
          // average below is average for all days for one product
          const productAverageDiscount = CommonUtil.average(averageDiscounts);
          const productAverageDiscountPercent = CommonUtil.average(
            averageDiscountsPercent,
          );
          discountsValues.push(productAverageDiscount);
          discountsPercents.push(productAverageDiscountPercent);
  
          discountsByKey[key].averageDiscounts.push(productAverageDiscount);
          discountsByKey[key].averageDiscountsPercent.push(
            productAverageDiscountPercent,
          );
        }
  
        const promotionTypes = averageDiscountByKeyAndMechanic[
          key
        ].promotions.find(
          mechanic => mechanic.id === parseInt(promotionType, 10),
        );
  
        const averageDiscount = CommonUtil.average(discountsValues);
        const averageDiscountPercent = CommonUtil.average(discountsPercents);
  
        promotionTypes.averageDiscount = averageDiscount;
        promotionTypes.averageDiscountPercent = averageDiscountPercent;
      }
  
      for (const key of Object.keys(discountsByKey)) {
        const keyDiscounts = discountsByKey[key];
        const averageDiscount = CommonUtil.average(keyDiscounts.averageDiscounts);
        const averageDiscountPercent = CommonUtil.average(
          keyDiscounts.averageDiscountsPercent,
        );
  
        averageDiscountByKeyAndMechanic[key].averageDiscount = averageDiscount;
        averageDiscountByKeyAndMechanic[
          key
        ].averageDiscountPercent = averageDiscountPercent;
      }
  
      return {
        data: Object.values(averageDiscountByKeyAndMechanic),
      };
    }
  
    /**
     * Gets average discount for all promotions and amount of products in all promotions
     * @param promotions
     * @param days
     * @returns {{averageDiscount: *, products: number}}
     */
    static getAverageDiscount(promotions) {
      const products = new Set();
  
      // group by brand+retailer+promotionMechanic
      const brandsMechanicDiscounts = {};
      for (const promotionKey of Object.keys(promotions)) {
        const promotion = promotions[promotionKey];
  
        for (const coreProductId of Object.keys(promotion.products)) {
          const coreProduct = promotion.products[coreProductId];
  
          const coreProductDiscount = this.getPromotionCoreProductAverageDiscount(
            coreProduct,
          );
  
          if (coreProductDiscount.averageDiscount === 0) {
            // eslint-disable-next-line no-continue
            continue;
          }
  
          const key = `${coreProduct.brandId}_${coreProduct.retailerId}_${promotion.mechanicId}`;
          if (!brandsMechanicDiscounts[key]) {
            brandsMechanicDiscounts[key] = {
              brandId: coreProduct.brandId,
              retailerId: coreProduct.retailerId,
              discounts: [],
              discountsPercents: [],
            };
          }
          brandsMechanicDiscounts[key].discounts.push(
            coreProductDiscount.averageDiscount,
          );
          brandsMechanicDiscounts[key].discountsPercents.push(
            coreProductDiscount.averageDiscountPercent,
          );
        }
        Object.keys(promotion.products).forEach(id => products.add(id));
      }
  
      // group by brand+retailer
      const brandsDiscounts = {};
      for (const brandMechanicKey of Object.keys(brandsMechanicDiscounts)) {
        const brandMechanicDiscount = brandsMechanicDiscounts[brandMechanicKey];
        const retailerId = brandMechanicDiscount.retailerId;
  
        const key = `${brandMechanicDiscount.brandId}_${brandMechanicDiscount.retailerId}`;
        if (!brandsDiscounts[key]) {
          brandsDiscounts[key] = {
            retailerId,
            discounts: [],
            discountsPercents: [],
          };
        }
        const averageDiscount = CommonUtil.average(
          brandMechanicDiscount.discounts,
        );
        const averageDiscountPercent = CommonUtil.average(
          brandMechanicDiscount.discountsPercents,
        );
  
        brandsDiscounts[key].discounts.push(averageDiscount);
        brandsDiscounts[key].discountsPercents.push(averageDiscountPercent);
      }
  
      // group by retailer
      const retailerDiscounts = {};
      for (const key of Object.keys(brandsDiscounts)) {
        const brandDiscount = brandsDiscounts[key];
        const retailerId = brandDiscount.retailerId;
  
        if (!retailerDiscounts[retailerId]) {
          retailerDiscounts[retailerId] = {
            retailerId,
            discounts: [],
            discountsPercents: [],
          };
        }
        const averageDiscount = CommonUtil.average(brandDiscount.discounts);
        const averageDiscountPercent = CommonUtil.average(
          brandDiscount.discountsPercents,
        );
  
        retailerDiscounts[retailerId].discounts.push(averageDiscount);
        retailerDiscounts[retailerId].discountsPercents.push(
          averageDiscountPercent,
        );
      }
  
      const promotionsDiscounts = [];
      const promotionsDiscountsPercent = [];
      for (const retailerDiscount of Object.values(retailerDiscounts)) {
        promotionsDiscounts.push(CommonUtil.average(retailerDiscount.discounts));
        promotionsDiscountsPercent.push(
          CommonUtil.average(retailerDiscount.discountsPercents),
        );
      }
  
      return {
        averageDiscount: CommonUtil.average(promotionsDiscounts) || 0,
        averageDiscountPercent:
          CommonUtil.average(promotionsDiscountsPercent) || 0,
        products: products.size,
      };
    }
  
    /**
     * Gets average discount for one promotion
     * @param promotion
     * @param days
     * @returns {*}
     */
    static getPromotionAverageDiscount(promotion) {
      const promotionDiscounts = [];
      const promotionDiscountsPercents = [];
  
      for (const coreProductId of Object.keys(promotion.products)) {
        const coreProduct = promotion.products[coreProductId];
  
        const {
          averageDiscount,
          averageDiscountPercent,
        } = this.getPromotionCoreProductAverageDiscount(coreProduct);
  
        promotionDiscounts.push(averageDiscount);
        promotionDiscountsPercents.push(averageDiscountPercent);
      }
  
      const averagePromotionDiscountPercent =
        CommonUtil.average(promotionDiscountsPercents) || '0';
      const averagePromotionDiscount =
        CommonUtil.average(promotionDiscounts) || '0';
      return {
        averageDiscount: averagePromotionDiscount,
        averageDiscountPercent: averagePromotionDiscountPercent,
      };
    }
  }

export default class ProductService {
    /**
     * get core retailers by condition
     * @param where
     * @returns {Promise<Model | null> | Promise<Model>}
     */
    static getCoreRetailer(where) {
      return db.coreRetailer.findOne({ where });
    }
  
    /**
     * set core retailers by core products
     * @param values
     * @returns {Promise<*|<Model[]>|boolean>}
     */
    static async setCoreRetailersOnce(values) {
      const isEmpty = db.coreRetailer.findAndCountAll();
      if (!isEmpty) return true;
      return db.coreRetailer.bulkCreate(values, {
        ignoreDuplicates: true,
      });
    }
  
    /**
     * find or create core retailer
     * @param value
     * @returns {Promise<[Model, boolean]>}
     */
    static setCoreRetailer(value) {
      return db.coreRetailer.findOrCreate({
        where: value,
        defaults: value,
      });
    }
  
    /**
     * find or create core retailer date
     * @param value
     * @returns {Promise<[Model, boolean]>}
     */
    static setCoreRetailerDate(value) {
      return db.coreRetailerDate.findOrCreate({
        where: value,
        defaults: value,
      });
    }
  
    /**
     * find or create core source category
     * @param value
     * @returns {Promise<[Model, boolean]>}
     */
    static setSourceCategory(value) {
      return db.sourceCategory.findOrCreate({
        where: value,
        defaults: value,
      });
    }
  
    /**
     * find or create core retailer taxonomy
     * @param value
     * @returns {Promise<[Model, boolean]>}
     */
    static setCoreRetailerTaxonomy(value) {
      return db.coreRetailerTaxonomy.findOrCreate({
        where: value,
        defaults: value,
      });
    }
  
    /**
     * find or create core product source category
     * @param value
     * @returns {Promise<[Model, boolean]>}
     */
    static setCoreSourceCategory(value) {
      return db.coreProductSourceCategory.findOrCreate({
        where: value,
        defaults: value,
      });
    }
  
    /**
     * find and format core retailers
     * @returns {Promise<Model[]>}
     */
    static searchCoreRetailers() {
      return db.product.findAll({
        attributes: ['retailerId', 'sourceId'],
        include: [
          {
            model: db.coreProduct,
            as: 'coreProduct',
            required: true,
            attributes: ['id'],
          },
        ],
        group: ['coreProduct.id', 'retailerId', 'sourceId'],
        order: [
          [COL('coreProduct.id'), 'DESC'],
          ['retailerId', 'DESC'],
        ],
      });
    }
  
    
    /**
     * get product with related objects by id
     * @param id
     * @returns {Promise<Model | null> | Promise<Model>}
     */
    static getProduct(id) {
      return db.coreProduct.scope('withMaster').findOne({
        where: { id },
        include: [
          {
            model: db.product,
            as: 'products',
            include: ['aggregated', 'productsData'],
          },
          {
            model: db.mappingSuggestion,
            as: 'suggestions',
            include: [
              'suggestedCore',
              {
                model: db.product,
                as: 'suggestedProduct',
                include: ['image'],
              },
            ],
          },
        ],
      });
    }
  
    /**
     * get all products by filters
     * @param ean
     * @param title
     * @param retailers
     * @param page
     * @param perPage
     * @returns {Promise<Model[]>}
     */
    static getAllProducts(ean, title, retailers, page, perPage) {
      const offset = perPage * (page - 1);
      const where = {};
      if (ean) where.ean = { [Op.iLike]: `%${ean}%` };
      if (title) where.title = { [Op.iLike]: `%${title}%` };
  
      if (retailers) {
        const retailersSplit = retailers.replace(' ', '').split(',');
        retailersSplit.forEach(retailer => {
          where[retailer] = { [Op.ne]: null };
        });
      }
      return db.coreProduct.scope('withMaster').findAll({
        where,
        include: [
          {
            model: db.product,
            as: 'products',
            include: ['aggregated'],
          },
          {
            model: db.mappingSuggestion,
            as: 'suggestions',
            include: [
              'suggestedCore',
              {
                model: db.product,
                as: 'suggestedProduct',
                include: ['image'],
              },
            ],
          },
        ],
        order: ['createdAt'],
        limit: perPage,
        offset,
      });
    }
  
    /**
     * create banners
     * @param banners
     * @returns {Promise<[]>}
     */
    static async createBanners(banners) {
      let results = [];
      for (const banner of banners) {
        const retailer = await RetailerService.getRetailerByName(
          banner.sourceType,
        );
        const query =
          'select * from banners where category = :category and "categoryType" = :categoryType and "retailerId" = :retailerId and "bannerId" = :bannerId GROUP BY id HAVING date_trunc(\'day\', "createdAt") = date_trunc(\'day\', NOW())';
        const queryParams = {
          raw: true,
          type: QueryTypes.SELECT,
          replacements: {
            categoryType: banner.categoryType,
            category: banner.category,
            retailerId: retailer.id,
            bannerId: banner.id,
          },
        };
        const exists = await db.sequelize.query(query, queryParams);
        if (exists.length) continue;
  
        const bannerAWSKey = `${banner.sourceType}/${+new Date()}`;
        let image = banner.image;
        if (!banner.image.includes('banner-images')) {
          const uploadedImage = await AWSUtil.uploadImage({
            key: bannerAWSKey,
            bucket: 'bannerImages',
            link: banner.image,
          });
          if (uploadedImage) image = uploadedImage;
        }
  
        const yesterday = moment()
          .subtract(1, 'days')
          .startOf('day')
          .format();
  
        const data = {
          image,
          category: banner.category,
          retailerId: retailer.id,
          categoryType: banner.categoryType,
          title: banner.title,
          screenshot: banner.screenshot,
          bannerId: banner.id,
          startDate: banner.date,
          endDate: banner.date,
        };
  
        let bannerItem = await db.banners.findOne({
          where: {
            bannerId: data.bannerId,
            retailerId: data.retailerId,
            endDate: {
              [Op.gte]: yesterday,
            },
          },
        });
  
        if (bannerItem) {
          await bannerItem.update({ endDate: banner.date });
          data.startDate = bannerItem.startDate;
        } else {
          bannerItem = await db.banners.create(data);
          const coreRetailers = await db.coreRetailer.findAll({
            where: {
              productId: {
                [Op.in]: banner.products,
              },
              retailerId: data.retailerId,
            },
          });
  
          for (const coreRetailer of coreRetailers) {
            await db.bannersProducts.create({
              coreRetailerId: coreRetailer.id,
              bannerId: bannerItem.id,
            });
          }
        }
  
        results = [...results, data];
      }
      return results;
    }
  
    /**
     *
     * download banner image
     * @param imageURL
     * @returns {Promise<void>}
     */
    static async getBannerImage(imageURL) {
      if (!imageURL || !imageURL.length) return '';
      const publicPathImagesBanners = 'bannerImages';
      const fileDate = new Date();
      const directoryPath = path.join(
        path.resolve(__dirname, '../..'),
        `/public/${publicPathImagesBanners}`,
      );
      const i = (await fs.readdirSync(directoryPath))
        ? fs.readdirSync(directoryPath).length
        : 1;
      const name = fileDate.toDateString() + i + 1;
      return new Promise((resolve, reject) => {
        https
          .get(imageURL, response => {
            if (response.statusCode !== 200) {
              return reject(`Status code: ${response.statusCode}`);
            }
            const file = fs.createWriteStream(`${directoryPath}/${name}.png`);
            response.pipe(file);
            file.on('finish', () => {
              resolve(`${publicPathImagesBanners}/${name}.png`);
            });
            file.on('error', reject);
          })
          .on('error', reject);
      }).catch(error => {
        console.log(
          `Download banner image failure! Error: ${error}. \nLink: ${imageURL}`,
        );
        return '';
      });
    }
  
    /**
     * refresh banners images
     * @param bannerImage
     * @returns {Promise<string>}
     */
    static async getBannerScreenshot(bannerImage) {
      const image = bannerImage.toString();
      const publicPathImagesBanners = 'bannerScreenshots';
      const fileDate = new Date();
      const directoryPath = path.join(
        path.resolve(__dirname, '../..'),
        `/public/${publicPathImagesBanners}`,
      );
      const i = (await fs.readdirSync(directoryPath))
        ? fs.readdirSync(directoryPath).length
        : 1;
      const name = fileDate.toDateString() + i + 1;
      await this.writeFile(`${directoryPath}/${name}.png`, image);
      return `${publicPathImagesBanners}/${name}.png`;
    }
  
    /**
     * write file from base64
     * @param savePath
     * @param data
     * @returns {Promise<void>}
     */
    static async writeFile(savePath, data) {
      await new Promise((resolve, reject) => {
        // eslint-disable-next-line new-cap
        fs.writeFile(savePath, new Buffer.from(data, 'base64'), err => {
          if (err) reject(err);
          else resolve();
        });
      });
    }
  
    /**
     * create core products from data
     * @param data
     * @returns {Promise<void>}
     */
    static async createCoreProducts(data) {
      for (let iter = 0; iter < data.length; iter += 1) {
        try {
          const product = data[iter];
          const condition = this.setCreateCondition(product.ean);
          const core = await this.coreByCondition(condition);
          if (core) {
            core.update(product);
          } else {
            await this.createCoreBy(product);
          }
        } catch (error) {
          console.log(error);
        }
      }
    }
  
    /**
     * update product categories
     * @param data
     * @returns {Promise<[]>}
     */
    static async updateCategories(data) {
      const pro = [];
      for (const p in data) {
        const product = data[p];
        const core = await db.coreProduct
          .scope('withMaster')
          .findOne({ where: { ean: `${product.ean}` } });
        if (core) {
          let category = await db.categories.findOne({
            where: { name: product.category },
          });
          console.log(category);
          if (!category) {
            category = await db.categories.create({
              name: product.category,
              categoryId: null,
            });
          }
          let subCategory = await db.categories.findOne({
            where: { name: product.subCat },
          });
          if (!subCategory) {
            subCategory = await db.categories.create({
              name: product.subCat,
              categoryId: category.id,
            });
          }
  
          let aisle = await db.categories.findOne({
            where: { name: product.aisle },
          });
          if (!aisle) {
            aisle = await db.categories.create({
              name: product.aisle,
              categoryId: subCategory.id,
            });
          }
          fs.appendFile (`./check/create-product.json`, JSON.stringify({
            dates,
            retailer,
            sourceCategoryType,
          }, null,'\t'), 'utf8', function(err) {
            if (err) throw err;
            console.log(`create-product => complete`);
          }
        );
          const pc = await core.update({ categoryId: aisle.id });
          pro.push(pc);
        }
      }
  
      return pro;
    }
  
    /**
     * update product group data
     * @param data
     * @returns {Promise<<Model[]>>}
     */
    static async updateProductGroup(data) {
      for (const g in data) {
        let productGroup = await db.productGroup.findOne({
          where: { name: data[g].productGroup },
        });
        if (!productGroup) {
          productGroup = await db.productGroup.create({
            name: data[g].productGroup,
          });
        }
        const product = await db.coreProduct
          .scope('withMaster')
          .findOne({ where: { ean: `${data[g].ean}` } });
        if (product) {
          await product.update({ productGroupId: productGroup.id });
        }
      }
      return db.productGroup.findAll();
    }
  
    /**
     * update brands by data
     * @param data
     * @returns {Promise<[]>}
     */
    static async updateBrands(data) {
      const br = [];
      for (const b in data) {
        const brandObj = data[b];
        let old = await db.brands.findOne({
          where: { name: brandObj.oldBrand },
        });
        if (!old) {
          old = await db.brands.create({ name: brandObj.oldBrand });
        }
        let newBrand = await db.brands.findOne({
          where: { name: brandObj.newBrand },
        });
        if (!newBrand) {
          newBrand = await db.brands.create({
            name: brandObj.newBrand,
          });
        }
        let manufacturer = await db.manufacturer.findOne({
          where: { name: brandObj.manufacturer },
        });
        if (!manufacturer) {
          manufacturer = await db.manufacturer.create({
            name: brandObj.manufacturer,
          });
        }
        let list = JSON.parse(newBrand.checkList);
        if (list === null) {
          list = [];
        }
        const n = list.includes(brandObj.oldBrand);
        if (!n) {
          list.push(brandObj.oldBrand);
          newBrand = await newBrand.update({
            checkList: JSON.stringify(list),
            manufacturerId: manufacturer.id,
          });
        }
        const products = await db.coreProduct
          .scope('withMaster')
          .findAll({ where: { brandId: old.id } });
        for (const prod in products) {
          const product = products[prod];
          await product.update({ brandId: newBrand.id });
        }
        if (old.name !== newBrand.name) {
          await old.destroy();
        }
        br.push(newBrand);
      }
  
      return br;
    }
  
    /**
     * refresh brands
     * @returns {Promise<void>}
     */
    static async refreshBrands() {
      const nullBrands = await db.brands.findAll({
        where: { checkList: null },
      });
      const listBrands = await db.brands.findAll({
        where: { checkList: { [Op.ne]: null } },
      });
      for (const n in nullBrands) {
        const nl = nullBrands[n];
        for (const nn in listBrands) {
          const list = listBrands[nn];
          if (JSON.parse(list.checkList).includes(nl.name)) {
            const products = await db.coreProduct
              .scope('withMaster')
              .findAll({ where: { brandId: nl.id } });
            for (const prod in products) {
              const product = products[prod];
              await product.update({ brandId: list.id });
            }
            await nl.destroy();
          }
        }
      }
    }
  
    /**
     * refresh images
     * @returns {Promise<void>}
     */
    static async refreshImages() {
      const directoryPath = path.join(
        path.resolve(__dirname, '../..'),
        '/public/images',
      );
      fs.readdir(directoryPath, (err, files) => {
        if (err) {
          return console.log(`Unable to scan directory: ${err}`);
        }
        files.forEach(file => {
          const mars = file.split('_');
          const ean = mars[0].split('.');
          const condition = this.setCreateCondition(ean[0]);
          this.coreByCondition(condition).then(async core => {
            if (core) {
              const img = path.join(directoryPath, file);
              const image = await AWSUtil.uploadImage({
                key: core.ean,
                bucket: 'coreImages',
                file: img,
              });
              fs.unlinkSync(img);
              core.update({ image });
            }
          });
        });
      });
    }
  
    static async createProductsTax(productsList) {
      let result = [];
      const countP = 0;
      for (let iter = 0; iter < productsList.length; iter += 1) {
        try {
          const {
            product,
            // eslint-disable-next-line no-shadow
          } = (({
            promotions,
            productPrice,
            originalPrice,
            status,
            ...product
          }) => ({
            product,
            promotions,
            productPrice,
            originalPrice,
            status,
          }))(productsList[iter]);
          const retailer = await RetailerService.getRetailerByName(
            product.sourceType,
          );
          const time = new Date(new Date(product.date).setHours(0, 0, 0, 0))
            .toISOString()
            .toString();
          const dates = await db.dates.findOrCreate({
            where: { date: time },
          });
  
          if (
            product.sourceType === 'waitrose' &&
            !CompareUtil.checkEAN(product.ean)
          ) {
            // eslint-disable-next-line max-len
            product.ean =
              (await ProductService.fetchWaitroseProductEAN(product.sourceId)) ||
              product.ean;
          }
  
          let core = await db.coreProduct.scope('withMaster').findOne({
            where: {
              ean: product.ean,
              disabled: { [Op.or]: [false, null] },
            },
          });
          const crCondition = {
            where: {
              retailerId: retailer.id,
              productId: product.sourceId,
            },
            include: [
              {
                model: db.coreProduct,
                as: 'coreProduct',
                where: { disabled: false },
                required: true,
              },
            ],
          };
          if (core && !CompareUtil.checkEAN(core.ean)) {
            crCondition.where.coreProductId = { [Op.ne]: core.id };
            const cr = await db.coreRetailer.findOne(crCondition);
            if (cr) {
              core = await db.coreProduct
                .scope('withMaster')
                .findOne({ where: { id: cr.coreProductId } });
            }
          } else if (!core) {
            const cr = await db.coreRetailer.findOne(crCondition);
            if (cr) {
              core = await db.coreProduct
                .scope('withMaster')
                .findOne({ where: { id: cr.coreProductId } });
            }
          }
  
          product.dateId = dates[0].id;
  
          const [coreRetailer] = await ProductService.setCoreRetailer({
            coreProductId: core.id,
            retailerId: retailer.id,
            productId: product.sourceId,
          });
          await ProductService.setCoreRetailerDate({
            coreRetailerId: coreRetailer.id,
            dateId: product.dateId,
          });
          const taxonomy = await db.retailerTaxonomy.findOne({
            where: { id: product.taxonomyId },
          });
  
          if (taxonomy) {
            await ProductService.setCoreRetailerTaxonomy({
              coreRetailerId: coreRetailer.id,
              retailerTaxonomyId: taxonomy.id,
            });
          }
          result = [...result];
        } catch (error) {
          console.log(error);
          console.log(productsList[iter].sourceId);
        }
      }
      console.log('PRODUCTS CREATED', countP);
      return result;
    }
  
 
  
    static async findCreateProductCore(product, retailer) {
      let core = false;
      let barcode = false;
      const { id: retailerId, countryId } = retailer;
      const include = [
        {
          model: db.coreProductCountryData,
          as: 'countryData',
          where: { countryId },
          required: false,
        },
      ];
      // if (CompareUtil.checkEAN(product.ean)) {
      barcode = await db.coreProductBarcode.findOne({
        where: { barcode: product.ean },
      });
      // }
      if (barcode) {
        core = await db.coreProduct.scope('withMaster').findOne({
          where: { id: barcode.coreProductId },
          include,
        });
      } else {
        core = await db.coreProduct.scope('withMaster').findOne({
          where: { ean: product.ean },
          include,
        });
        if (core) {
          // barcode = await db.coreProductBarcode.findOne({
          //   where: { coreProductId: core.id },
          // });
          // if (!barcode || (barcode && barcode.barcode !== product.ean)) {
          //   barcode = await db.coreProductBarcode.create({
          //     coreProductId: core.id,
          //     barcode: product.ean,
          //   });
          // }
          //const where = { coreProductId: core.id, barcode: product.ean };
          // await db.coreProductBarcode.findOrCreate({
          //   where,
          //   defaults: where,
          // });
          //barcode = await DbUtil.execDbFunc('ins_coreProductBarcodes', where);
          barcode = await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
  
        }
      }
      if (core) {
        if (core.disabled) await core.update({ disabled: false });
        return core;
      }
      const cr = await db.coreRetailer.findOne({
        where: {
          retailerId,
          productId: product.sourceId,
        },
        include: [
          {
            model: db.coreProduct,
            as: 'coreProduct',
            where: { disabled: { [Op.or]: [false, null] } },
            required: true,
          },
        ],
        order: [['createdAt', 'DESC']],
      });
      if (!cr) return core;
      core = await db.coreProduct.scope('withMaster').findOne({
        where: { id: cr.coreProductId },
        include,
      });
      if (core) {
        //const where = { coreProductId: core.id, barcode: product.ean };
        // await db.coreProductBarcode.findOrCreate({
        //   where,
        //   defaults: where,
        // });
        await DbUtil.execDbFunc('sel_ins_coreProductBarcodes', [core.id, product.ean]);
      }
      return core;
    }
  
    /**
     * create core products from products list
     * @param products
     * @returns {Promise<[]>}
     */
    static async createProducts(products) {
      let result = [];
      let countP = 0;
  
      if (!products.length) {
        console.log('No products!');
        return result;
      }
      const {
        dates,
        retailer,
        sourceCategoryType,
      } = await ProductService.getCreateProductCommonData(products);
      const dateId = dates[0].id;
      const expandProduct = ({
        promotions,
        productPrice,
        originalPrice,
        status,
        ...product
      }) => ({
        product,
        promotions,
        productPrice,
        originalPrice,
        status,
      });
      for (const row of products) {
        try {
          const {
            product,
            promotions,
            productPrice,
            originalPrice,
            status,
          } = expandProduct(row);
  
          product.promotions = !!promotions;
          product.promotionDescription = promotions
            ? promotions[0].description
            : '';
          product.basePrice = originalPrice;
          product.shelfPrice = originalPrice;
          product.promotedPrice = originalPrice;
          product.retailerId = retailer.id;
          product.dateId = dateId;
          if (!product.featured) product.featured = false;
          if (
            product.sourceType === 'waitrose' &&
            !CompareUtil.checkEAN(product.ean)
          ) {
            const waitroseEAN = await ProductService.fetchWaitroseProductEAN(
              product.sourceId,
            );
            // eslint-disable-next-line max-len
            if (waitroseEAN) product.ean = waitroseEAN;
          }
  
          const exists = await db.product.findOne({
            where: {
              sourceId: product.sourceId,
              retailerId: product.retailerId,
              dateId: product.dateId,
            },
          });
  
          // console.log(`!!setSourceCategory=> name:${product.category}, type:${sourceCategoryType}`)
          // return exists;
  
          if (exists) {
            // const [sourceCategoryOrg] = await ProductService.setSourceCategory({
            //   name: product.category,
            //   type: sourceCategoryType,
            // });
            // console.log(`!!sourceCategoryOrg=> ${sourceCategoryOrg.name}`)
  
            // const sourceCategory = await DbUtil.execDbFunc('ins_sourceCategories', {
            //   name: product.category,
            //   type: sourceCategoryType,
            // });
            // =======
            // const sourceCategory = await DbUtil.execDbFunc('sel_ins_sourceCategories', [
            //   product.category,
            //   sourceCategoryType,
            // ]);
  
            await this.createProductsData({ ...product, productId: exists.id });
  
            await this.createAmazonProduct(product, exists.id);
            countP += 1;
  
            // eslint-disable-next-line no-continue
            // continue;
  
          }
  
          const brand = await this.getBrandBy(product.productBrand);
  
          let core = await ProductService.findCreateProductCore(
            product,
            retailer,
          );
  
          const coreProductData = {
            ean: product.ean,
            title: product.productTitle,
            image: product.productImage,
            brandId: brand.id,
            bundled: product.bundled,
            secondaryImages: product.secondaryImages,
            description: product.productDescription,
            features: product.features,
            ingredients: product.productInfo,
            size: product.size,
            specification: product.nutritional,
            productOptions: product.productOptions || false,
            eanIssues: !CompareUtil.checkEAN(product.ean),
          };
          let freshCore = false;
  
          if (!core) {
            core = await this.createCoreBy(coreProductData);
            freshCore = true;
          }
          if (!core.countryData || !core.countryData.id) {
            await CoreProductService.createProductCountryData(
              core,
              retailer.countryId,
              coreProductData,
              freshCore,
            );
          }
          if (core.productOptions !== product.productOptions) {
            await core.update({
              productOptions: product.productOptions,
            });
          }
          product.coreProductId = core.id;
          // const [sourceCategory] = await ProductService.setSourceCategory({
          //   name: product.category,
          //   type: sourceCategoryType,
          // });
          // =====
          // const sourceCategory = await DbUtil.execDbFunc('sel_ins_sourceCategories', [
          //   product.category,
          //   sourceCategoryType,
          // ]);
          const saved = await this.createProductBy(product);
  
          // const [coreRetailer] = await ProductService.setCoreRetailer({
          //   coreProductId: core.id,
          //   retailerId: retailer.id,
          //   productId: product.sourceId,
          // });
          const coreRetailer = await DbUtil.execDbFunc('sel_ins_coreRetailers', [
            core.id,
            retailer.id,
            product.sourceId,
          ]);
  
          const taxonomy = await db.retailerTaxonomy.findOne({
            where: { id: product.taxonomyId },
          });
  
          if (taxonomy) {
            // await ProductService.setCoreRetailerTaxonomy({
            //   coreRetailerId: coreRetailer.id,
            //   retailerTaxonomyId: taxonomy.id,
            // });
            const coreRetailerTaxonomies = await DbUtil.execDbFunc('sel_ins_coreRetailerTaxonomies', [
              coreRetailer.id,
              taxonomy.id,
            ]);
            console.log('!!coreRetailerTaxonomies=', JSON.stringify(coreRetailerTaxonomies));
          }
  
          //await this.saveProductStatus(saved, status, product.screenshot);
  
          if (promotions) {
            const promo = await PromotionService.processProductPromotions(
              promotions,
              saved,
            );
            console.log('!!promo=', JSON.stringify(promo))
  
            const multibuy = promo.find(item => item.mechanic === 'Multibuy');
            if (multibuy) {
              // eslint-disable-next-line max-len
              saved.promotedPrice = PromotionService.calculateMultibuyPrice(
                multibuy.description,
                saved.promotedPrice,
              );
            } else {
              const tescoClubcardPromo = promo.find(item =>
                /clubcard price/i.test(item.description),
              );
              if (!(saved.sourceType === 'tesco' && tescoClubcardPromo)) {
                saved.shelfPrice = productPrice;
              }
              saved.promotedPrice = productPrice;
            }
            await saved.save();
          }
          const aggredated = await this.calculateAggregated(saved);
          aggredated.productId = saved.id;
  
          console.log('!!aggredated=', JSON.stringify(aggredated))
  
          //await db.aggregatedProduct.create(aggredated);
  
          await DbUtil.execDbFunc('ins_aggregatedProducts', [
            aggredated.productId,
            `${aggredated.titleMatch}`,
          ])
          //return aggredated;
  
          await ProductService.setCoreRetailerDate({
            coreRetailerId: coreRetailer.id,
            dateId: saved.dateId,
          });
          // await ProductService.setCoreSourceCategory({
          //   coreProductId: core.id,
          //   sourceCategoryId: sourceCategory.id,
          // });
          result = [...result, saved];
        } catch (error) {
          console.log(error);
          console.log(row.sourceId);
        }
      }
      console.log('PRODUCTS CREATED', countP, result.length);
      return result;
    }
  
    static async createProductsPP(products, retailer) {
      if (!products.length) return products.length;
      const replacePPProductsMap = {
        date: ['date', null],
        ean: ['ean', null],
        sourceId: ['sourceId', null],
        href: ['skuURL', ''],
        productTitle: ['title', ''],
        productTitleDetail: ['title', ''],
        productBrand: ['brand', ''],
        productImage: ['imageURL', ''],
        productInStock: ['inStock', true],
        productPrice: ['shelfPrice', null],
        originalPrice: ['wasPrice', null],
        promotions: ['promoData', []],
        bundled: ['bundled', false],
        productOptions: ['masterSku', false],
        promotionDescription: [null, ''],
        category: [null, ''],
        categoryType: [null, 'taxonomy'],
        sourceType: [null, retailer.name],
        screenshot: [null, ''],
        nutritional: [null, ''],
        size: [null, ''],
        productInfo: [null, ''],
        features: [null, ''],
        productDescription: [null, ''],
        secondaryImages: [null, false],
        status: [null, 'listing'],
        pageNumber: [null, 1],
      };
      const replacePPProductPromoMap = {
        description: ['promo_description', ''],
        mechanic: ['promo_type', null],
        promoId: ['promo_id', ''],
        multibuyPrice: ['multibuy_price', null],
        startDate: [null, null],
        endDate: [null, null],
      };
      let count = 0;
      const zeroTime = new Date(
        products[0][replacePPProductsMap.date[0]],
      ).setHours(0, 0, 0, 0);
      const time = new Date(zeroTime).toISOString().toString();
      const dates = await db.dates.findOrCreate({
        where: { date: time },
      });
      const dateId = dates[0].id;
      const replaceKeys = (obj, map) =>
        Object.keys(map).reduce((acc, key) => {
          const [k, d] = map[key];
          let value = k in obj ? obj[k] : d;
          if (value === d && key in obj) value = obj[key];
          return { ...acc, [key]: value };
        }, {});
      // eslint-disable-next-line max-len
      const expandProduct = ({
        ean,
        promotions,
        productPrice,
        originalPrice,
        status,
        ...product
      }) => {
        const productOptions =
          typeof product.productOptions === 'string'
            ? product.productOptions === 'true'
            : !!product.productOptions;
        const EANs = productOptions
          ? [`${retailer.name}_${product.sourceId}`]
          : ean.split(',');
        const promo = Array.isArray(promotions) ? promotions : [];
        return {
          EANs,
          status,
          productPrice,
          product: { ...product, productOptions, ean: EANs[0] },
          originalPrice: originalPrice || productPrice,
          promotions: promo.map(row =>
            replaceKeys(row, replacePPProductPromoMap),
          ),
        };
      };
      for (const [index, p] of products.entries()) {
        const row = replaceKeys(p, replacePPProductsMap);
        try {
          row.productRank = index + 1;
          row.featuredRank = index + 1;
          // eslint-disable-next-line max-len
          const {
            EANs,
            product,
            promotions,
            productPrice,
            originalPrice,
            status,
          } = expandProduct(row);
  
          product.promotions = !!promotions.length;
          product.promotionDescription = promotions.length
            ? promotions.map(promo => promo.description).join(';')
            : '';
          product.basePrice = originalPrice;
          product.shelfPrice = originalPrice;
          product.promotedPrice = originalPrice;
          product.retailerId = retailer.id;
          product.dateId = dateId;
          if (!product.featured) product.featured = false;
  
          const exists = await db.product.findOne({
            where: {
              sourceId: product.sourceId,
              retailerId: product.retailerId,
              dateId: product.dateId,
            },
          });
  
          if (exists) {
            await this.createProductsData({ ...product, productId: exists.id });
            // eslint-disable-next-line no-continue
            continue;
          }
  
          const brand = await this.getBrandBy(product.productBrand);
          let core = await ProductService.findCreateProductCore(
            product,
            retailer,
          );
          const coreProductData = {
            ean: product.ean,
            title: product.productTitle,
            image: product.productImage,
            brandId: brand.id,
            bundled: product.bundled,
            secondaryImages: product.secondaryImages,
            description: product.productDescription,
            features: product.features,
            ingredients: product.productInfo,
            size: product.size,
            specification: product.nutritional,
            productOptions: product.productOptions || false,
            eanIssues: !CompareUtil.checkEAN(product.ean),
          };
          let freshCore = false;
          if (!core) {
            core = await this.createCoreBy(coreProductData, EANs);
            freshCore = true;
          }
          if (!core.countryData || !core.countryData.id) {
            await CoreProductService.createProductCountryData(
              core,
              retailer.countryId,
              coreProductData,
              freshCore,
            );
          }
          if (core.productOptions !== product.productOptions) {
            await core.update({
              productOptions: product.productOptions,
            });
          }
          product.coreProductId = core.id;
          const saved = await this.createProductBy(product);
          count += 1;
          const [coreRetailer] = await ProductService.setCoreRetailer({
            coreProductId: core.id,
            retailerId: retailer.id,
            productId: product.sourceId,
          });
          await this.saveProductStatus(saved, status, product.screenshot);
          if (promotions) {
            const promo = await PromotionService.processProductPromotions(
              promotions,
              saved,
            );
            const multibuy = promo.find(item => item.mechanic === 'Multibuy');
            if (multibuy) {
              const mPromo = promotions.find(
                item => item.description === multibuy.description,
              );
              // eslint-disable-next-line max-len
              saved.promotedPrice =
                mPromo &&
                mPromo.multibuyPrice &&
                !Number.isNaN(mPromo.multibuyPrice)
                  ? mPromo.multibuyPrice
                  : PromotionService.calculateMultibuyPrice(
                      multibuy.description,
                      saved.promotedPrice,
                    );
            } else {
              saved.promotedPrice = productPrice;
              saved.shelfPrice = productPrice;
            }
            await saved.save();
          }
          const aggregated = await this.calculateAggregated(saved);
          aggregated.productId = saved.id;
          await db.aggregatedProduct.create(aggregated);
          await ProductService.setCoreRetailerDate({
            coreRetailerId: coreRetailer.id,
            dateId: saved.dateId,
          });
        } catch (error) {
          console.log(error);
          console.log(row.sourceId);
        }
      }
      return count;
    }
  
    static async processReviews(reviews, retailerId) {
      const reviewMap = reviews.reduce(
        (map, [id, list]) => map.set(id, list),
        new Map(),
      );
  
      const coreRetailers = await db.coreRetailer.findAll({
        attributes: ['id', 'productId'],
        where: {
          retailerId,
          productId: {
            [Op.in]: [...reviewMap.keys()],
          },
        },
        order: [['createdAt', 'desc']],
        raw: true,
      });
  
      const filtered = coreRetailers.reduce(
        (map, { id: coreRetailerId, productId }) => {
          if (map.has(productId)) return map;
          const list = reviewMap.get(productId);
          return map.set(productId, { coreRetailerId, list });
        },
        new Map(),
      );
  
      for (const { list, coreRetailerId } of filtered.values()) {
        const ids = await db.review.findAll({
          attributes: [['reviewId', 'id']],
          where: {
            coreRetailerId,
            reviewId: {
              [Op.in]: list.map(({ reviewId }) => reviewId),
            },
          },
          raw: true,
        });
        const filteredReviews = list.filter(
          ({ reviewId }) => !ids.find(({ id }) => id === reviewId),
        );
        for (const review of filteredReviews) {
          const obj = {
            coreRetailerId,
            title: review.title,
            rating: review.rating,
            comment: review.comment,
            reviewId: review.reviewId,
            date: review.date ? new Date(review.date) : null,
          };
          try {
            await db.review.create(obj);
          } catch (e) {
            console.dir({ obj });
            console.error(e);
          }
        }
      }
    }
  
    /**
     * get brand by products checklist
     * @param productBrand
     * @returns {Promise<{id: null}|*>}
     */
    static async getBrandBy(productBrand) {
      const brand = await BrandService.getBrandByCheckList(productBrand);
      if (brand) {
        return brand;
      }
      return { id: null };
    }
  
    /**
     * update aggregated products calculations
     * @returns {Promise<void>}
     */
    static async updateCalculations() {
      const products = await db.product.findAll({
        attributes: ['id', 'productTitle', 'features', 'coreProductId'],
      });
      for (let iter = 0; iter < products.length; iter += 1) {
        const aggredated = await this.calculateAggregated(products[iter]);
        const prod = await db.product.findOne({
          where: { id: products[iter].id },
          include: ['aggregated'],
        });
        await prod.aggregated.update(aggredated);
      }
    }
  
    /**
     * get core by condition
     * @param condition
     * @returns {Promise<Model | null> | Promise<Model>}
     */
    static coreByCondition(condition) {
      return db.coreProduct.scope('withMaster').findOne(condition);
    }
  
    /**
     * create core by condition with image creation
     * @param product
     * @param EANs
     * @returns {Promise<*>}
     */
    static async createCoreBy(product, EANs = [product.ean]) {
      const img = product.image;
      product.image = await AWSUtil.uploadImage({
        bucket: 'coreImages',
        key: product.ean,
        link: img,
      });
      const coreProduct = await CoreProductService.createProduct(product);
      for (const barcode of EANs) {
        await CoreProductService.createBarcode(coreProduct, barcode);
      }
      return coreProduct;
    }
  
    /**
     * create product from data
     * @param product
     * @param sourceCategory
     * @returns {Promise<null|any>}
     */
    static async createProductBy(product) {
      if (
        Object.keys(retailerLinkMap).includes(product.sourceType) &&
        !product.productImage.includes(retailerLinkMap[product.sourceType])
      ) {
        product.productImage = `${retailerLinkMap[product.sourceType]}${
          product.productImage
        }`;
      }
      let newImg = product.productImage.replace(
        'https://www.sainsburys.co.ukhttps://www.sainsburys.co.uk',
        'https://www.sainsburys.co.uk',
      );
      newImg = newImg.replace(
        'https://www.sainsburys.co.ukhttps://assets.sainsburys-groceries.co.uk',
        'https://assets.sainsburys-groceries.co.uk',
      );
      newImg = newImg.replace(
        'https://www.ocado.comhttps://ocado.com',
        retailerLinkMap.ocado,
      );
      product.productImage = newImg;
      let savedProduct = await db.product.findOne({
        where: {
          sourceId: product.sourceId,
          retailerId: product.retailerId,
          dateId: product.dateId,
        },
      });
      if (!savedProduct) {
        savedProduct = await db.product.create(product);
      }
      await this.createProductsData({ ...product, productId: savedProduct.id });
      await this.createAmazonProduct(product, savedProduct.id);
      return savedProduct;
    }
  
    static async createAmazonProduct(product, productId) {
      if (!product.sourceType.toLowerCase().includes('amazon')) return;
      // const data = {
      //   productId,
      //   shop: product.amazonShop || product.shop || '',
      //   choice: product.amazonChoice || product.choice || '',
      //   lowStock: product.lowStock || false,
      //   sellParty: product.amazonSellParty || product.sellParty || '',
      //   sell: product.amazonSell || product.sell || '',
      //   fulfilParty: product.amazonFulfilParty || product.fulfilParty || '',
      // };
      const data = [
        productId,
        product.amazonShop || product.shop || '',
        product.amazonChoice || product.choice || '',
        product.lowStock || false,
        product.amazonSellParty || product.sellParty || '',
        product.amazonSell || product.sell || '',
        product.amazonFulfilParty || product.fulfilParty || '',
      ];
      // const saved = await db.amazonProduct.findOne({
      //   where: data,
      // });
      // if (!saved) {
      //   await db.amazonProduct.create(data);
      // }
  
      // console.log('!!data=', data);
  
      // console.log('!!SEL_ins_amazonProducts=', DbUtil.makeSelectStatement('amazonProducts', data))
      // console.log('!!INS_ins_amazonProducts=', DbUtil.makeInsertStatement('amazonProducts', data, true))
  
      // // console.log('!!savedProductsData=', savedProductsData)
      // const test = await DbUtil.execDbFunc('ins_amazonProducts', data);
      // console.log('!!test=', test)
      await DbUtil.execDbFunc('sel_ins_amazonProducts', data);
    }
  
    /**
     *
     * @param product
     * @param status
     * @param screenshot
     * @returns {Promise<*>}
     */
    static async saveProductStatus(product, status, screenshot = '') {
      if (status === 'newly') {
        const count = await db.product.count({
          where: { sourceId: product.sourceId },
        });
        // eslint-disable-next-line no-param-reassign
        if (count > 1) status = 're-listed';
      }
      // return db.productStatus.create({
      //   productId: product.id,
      //   status,
      //   screenshot,
      // });
  
      // const test = await DbUtil.execDbFunc('ins_productStatuses', {
      //   productId: product.id,
      //   status,
      //   screenshot,
      // });
      // console.log('!!test=', test)
      return DbUtil.execDbFunc('ins_productStatuses', [
        product.id,
        status,
        screenshot,
      ]);
    }
  
    /**
     * create products data from product
     * @param product
     * @returns {Promise<void>}
     */
    static async createProductsData(product) {
      // const productsData = {
      //   productId: product.productId,
      //   category: product.category,
      //   categoryType: product.categoryType,
      //   featured: product.featured,
      //   featuredRank: Number(product.featuredRank),
      //   productRank: Number(product.productRank),
      //   parentCategory: product.parentCategory ? product.parentCategory : '',
      //   pageNumber: String(product.pageNumber),
      //   screenshot: product.screenshot,
      //   taxonomyId: product.taxonomyId || 0,
      //   sourceCategoryId: sourceCategory.id,
      // };
      const productsData = [
        product.productId,
        product.category,
        product.categoryType,
        product.featured,
        Number(product.featuredRank),
        Number(product.productRank),
        product.parentCategory ? product.parentCategory : '',
        String(product.pageNumber),
        product.screenshot,
        product.taxonomyId || 0,
      ];
      // let savedProductsData = await db.productsData.findOne({
      //   where: productsData,
      // });
      // if (!savedProductsData) {
      //   savedProductsData = await db.productsData.create(productsData);
      // }
      
      // console.log('!!makeSelectStatement=', DbUtil.makeSelectStatement('productsData', productsData))
      // console.log('!!makeInsertStatement=', DbUtil.makeInsertStatement('productsData', productsData))
  
      // console.log('!!savedProductsData=', savedProductsData)
      return await DbUtil.execDbFunc('sel_ins_productsData', productsData);
    
      // return savedProductsData;
    }
  
    /**
     * get core product by id
     * @param pk
     * @returns {Promise<Model | null> | Promise<Model>}
     */
    static getCoreById(pk) {
      return db.coreProduct.scope('withMaster').findByPk(pk);
    }
  
    /**
     * get core products by id's
     * @param ids
     * @returns {Promise<Model[]>}
     */
    static getCoreByIds(ids) {
      return db.coreProduct
        .scope('withMaster')
        .findAll({ where: { id: { [Op.in]: ids } } });
    }
  
    /**
     * get products by retailer
     * @returns {Promise<*>}
     */
    static async getAllRetailerProducts() {
      const queryParams = {
        raw: true,
        type: QueryTypes.SELECT,
      };
      return db.sequelize.query(
        'SELECT "coreProducts"."id" AS "core->id", "coreProducts"."createdAt" AS "core->created", "coreProducts"."ean" AS "core->ean", "products"."id", "products"."ean", "products"."sourceId", "products"."sourceType",  "products"."productTitle", "products"."productImage", "products"."promotedPrice", "products"."basePrice", "products"."productInfo", "products"."nutritional", "products"."size", "products"."promotions" FROM "coreProducts" INNER JOIN (SELECT * FROM "products" WHERE id IN (SELECT MAX(id) AS id FROM "products" WHERE "productTitle" != \'\' AND "productInfo" != \'\' GROUP BY "coreProductId", "sourceType" ORDER BY id DESC)) "products" ON "coreProducts"."id"="products"."coreProductId" WHERE "coreProducts"."disabled" IS NOT TRUE ORDER BY "core->id" DESC',
        queryParams,
      );
    }
  
    /**
     * get weights by user
     * @param userId
     * @returns {Promise<Model[]>}
     */
    static getWeights(userId) {
      return db.weights.findAll({ where: { userId } });
    }
  
    /**
     * product create condition
     * @param ean
     * @returns {{where: {}}}
     */
    static setCreateCondition(ean) {
      return {
        where: {
          [Op.or]: [{ ean }],
        },
      };
    }
  
    /**
     * calculate aggregated products percents
     * @param saved
     * @returns {Promise<{
     * imageMatch: number,
     * features: number,
     * secondaryImages: number,
     * reviews: number,
     * top: number,
     * richContent: number,
     * titleMatch: number,
     * stars: number,
     * stock: number}>}
     */
  static async calculateAggregated(saved) {
      const products = await db.product.findOne({
        attributes: ['id', 'retailerId', 'coreProductId'],
        where: saved.id,
        include: [
          {
            model: db.retailer,
            as: 'retailer',
            attributes: ['id', 'countryId'],
          },
        ],
      });
      const parentProdCountryData = await db.coreProductCountryData.findOne({
        where: {
          coreProductId: products.coreProductId,
          countryId: products.retailer.countryId
        },
      });
      const titleParent = parentProdCountryData.title;
  
      return {
        titleMatch: TitleUtil.compareTwoStrings(
          titleParent.toUpperCase(),
          saved.productTitle.toUpperCase(),
        ),
      };
    }
    
  
    static async prepareProductImage(product) {
      if (product.productImage === '' || product.coreProduct.image === null)
        return;
      try {
        await ProductService.delay(10);
        const {
          coreProduct: { ean },
          productImage: originalPath,
        } = product;
        let image = await db.images.findOne({ where: { originalPath } });
        const productImage = ProductService.prepareImageLink(product);
        const ressemblePath = await ProductService.getImageRessemblePath(
          product,
          productImage,
        );
        let coreImageLink = await AWSUtil.getImage(ean, 'coreImages');
        if (!coreImageLink) coreImageLink = product.coreProduct.image;
        // console.dir({ originalPath, productImage, coreImageLink, ressemblePath });
        const imageLinks = [productImage, coreImageLink];
        const imagesPath = await ProductService.downloadImages(imageLinks, ean);
        const { lowerSize, images } = await CompareUtil.findLowerSizeOfImages(
          imagesPath,
        );
        for (const { image: filePath, size } of images) {
          if (
            !size ||
            Number(size.width) === lowerSize.width ||
            Number(size.height) === lowerSize.height
          ) {
            // eslint-disable-next-line no-continue
            continue;
          }
          const img = await Jimp.read(filePath);
          img.resize(lowerSize.width, lowerSize.height).write(filePath);
        }
        const score = await this.compareImages(...imagesPath);
        // console.dir({ score, title: product.productTitle, images }, { depth: 3 });
        if (!image) {
          image = await db.images.create({
            ressemblePath,
            modifiedPath: productImage,
            originalPath: product.productImage,
            score,
          });
          await product.update({ imageId: image.id });
        } else {
          await image.update({ ressemblePath, score });
        }
        await product.update({ imageId: image.id });
        await product.aggregated.update({ imageMatch: score });
      } catch (e) {
        console.error('prepareProductImage failure!', e);
      } finally {
        await ProductService.delay(10);
      }
    }
  
    static async downloadImages(links, ean) {
      const downloadPromises = links.map(
        (link, i) =>
          new Promise((resolve, reject) => {
            if (!link) return resolve(false);
            const filePath = `${publicDir}/tmpImages/${ean}_${i}.jpg`;
            const exists = fs.existsSync(filePath);
            // console.dir({ link, filePath, exists });
            if (exists) return resolve(filePath);
            const url = new URL(link);
            const options = {
              hostname: url.hostname,
              path: url.pathname,
              method: 'GET',
              headers: {
                'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36',
              },
            };
            https
              .get(options, response => {
                if (response.statusCode !== 200) {
                  const err = new Error('Image request failure!');
                  return reject(err);
                }
                const file = fs.createWriteStream(filePath);
                response.pipe(file);
                file.on('finish', () => {
                  resolve(filePath);
                });
                file.on('error', reject);
              })
              .on('error', reject);
          }),
      );
      return Promise.all(downloadPromises);
    }
  
    static async getImageRessemblePath(product, productImage) {
      let ressemblePath = false;
      try {
        const bucket = 'ressembleImages';
        const key = `${product.sourceType}/${product.sourceId}`;
        ressemblePath = await AWSUtil.getImage(key, bucket);
        if (!ressemblePath) {
          ressemblePath = await AWSUtil.uploadImage({
            key,
            bucket,
            link: productImage,
          });
        }
      } catch (e) {
        console.error('getImageRessemblePath failure!', e);
      } finally {
        ProductService.delay(300);
      }
      return ressemblePath;
    }
  
    
    /**
     * upload and compare images for perfect product trend
     * @param pathDate
     * @param companyIds
     * @returns {Promise<void>}
     */
    static async prepareImagesDaily(pathDate, companyIds = []) {
      let date = pathDate;
      if (pathDate === undefined || Number.isInteger(pathDate)) {
        const now = new Date();
        const today = new Date(
          new Date(now.getFullYear(), now.getMonth(), now.getDate()).setHours(
            0,
            0,
            0,
            0,
          ),
        );
        if (Number.isInteger(pathDate)) {
          today.setDate(today.getDate() + pathDate);
        }
        date = new Date(today).toISOString().toString();
      }
      const dateEntity = await db.dates.findOne({
        attributes: ['id'],
        where: { date },
        raw: true,
      });
      if (!dateEntity) throw new Error(`Date '${date}' not found`);
      const { id: dateId } = dateEntity;
  
      const contentOpts = {
        attributes: ['companyId'],
        include: [
          {
            model: db.section,
            as: 'section',
            required: true,
            where: { name: 'content' },
          },
        ],
        raw: true,
      };
      if (companyIds.length) contentOpts.where = { companyId: companyIds };
      const contentCompanies = await db.companySection.findAll(contentOpts);
      const contentCompanyIds = contentCompanies.map(row => row.companyId);
  
      const manufacturers = (
        await db.companyManufacturer.findAll({
          attributes: ['manufacturerId'],
          where: { companyId: contentCompanyIds },
          group: ['manufacturerId'],
          raw: true,
        })
      ).map(m => m.manufacturerId);
  
      const manufacturersOwnLabel = (
        await db.manufacturer.findAll({
          where: {
            id: manufacturers,
            isOwnLabelManufacturer: true,
          },
          raw: true,
        })
      ).map(m => m.id);
  
      const products = await db.product.findAll({
        where: { imageId: null, dateId },
        include: [
          {
            model: db.coreProduct,
            as: 'coreProduct',
            required: true,
            include: [
              {
                model: db.brands,
                as: 'productBrand',
                required: true,
                where: {
                  manufacturerId: manufacturers,
                },
              },
            ],
          },
          {
            model: db.aggregatedProduct,
            as: 'aggregated',
            required: true,
          },
          {
            model: db.retailer,
            as: 'retailer',
            required: true,
          },
        ],
      });
      const productsOwnLabel = await db.product.findAll({
        where: { imageId: null, dateId },
        include: [
          {
            model: db.coreProduct,
            as: 'coreProduct',
            required: true,
            include: [
              {
                model: db.coreProductCountryData,
                as: 'countryData',
                required: true,
                where: {
                  ownLabelManufacturerId: manufacturersOwnLabel,
                },
              },
            ],
          },
          {
            model: db.aggregatedProduct,
            as: 'aggregated',
            required: true,
          },
          {
            model: db.retailer,
            as: 'retailer',
            required: true,
          },
        ],
      });
      const count = products.length;
      const countOwnLabel = productsOwnLabel.length;
      console.dir({ count });
      console.dir({ countOwnLabel });
      const combinedProducts = [
        ...products,
        ...productsOwnLabel,
      ];
      for (const [index, product] of combinedProducts.entries()) {
        const prodCountryData = await db.coreProductCountryData.findOne({
          where: {
            coreProductId: product.coreProductId,
            countryId: product.retailer.countryId
          },
        });
        product.coreProduct.image = prodCountryData ? prodCountryData.image : null;
        const label = `PrepareImagesDaily ${index + 1}/${count + countOwnLabel}`;
        console.log(label);
        console.time(label);
        // eslint-disable-next-line no-continue
        if (product.productImage === '' || product.coreProduct.image === null) {
          console.timeEnd(label);
          continue;
        }
        try {
          await ProductService.compareProductImages(product);
        } catch (e) {
          console.error('compareProductImages failure!', e);
        } finally {
          console.timeEnd(label);
          await this.delay(10);
        }
      }
    }
  

  
    static async prepareCores() {
      console.log('prepare aggregated scores');
  
      const products = await CoreProductService.getAllCoreProducts();
      for (const product of products) {
        const data = {};
        data.secondaryImages = product['product->secondaryImages'];
        data.description =
          product.description.length > 2
            ? product.description
            : product['product->description'];
        data.features =
          product.features.length > 2
            ? product.features
            : product['product->features'];
        data.ingredients =
          product.ingredients.length > 2
            ? product.ingredients
            : product['product->ingredients'];
        data.specification = product['product->specification'];
        data.size = product['product->size'];
        await CoreProductService.updateOne(product.id, data);
      }
      return true;
    }
  
    static async prepareAggregatedScore() {
      const generalProductsCount = await db.product.count({
        where: {
          [Op.not]: { imageId: null },
          date: {
            [Op.gte]: '2020-09-01',
          },
        },
        include: ['aggregated', 'image'],
      });
      console.log(generalProductsCount);
  
      for (let i = 0; i <= Math.floor(generalProductsCount / 10000); i += 1) {
        const generalProducts = await db.product.findAll({
          where: {
            [Op.not]: { imageId: null },
            date: {
              [Op.gte]: '2020-09-01',
            },
          },
          include: ['aggregated', 'image'],
          limit: 10000,
          offset: i * 10000,
        });
  
        generalProducts.forEach(async prod => {
          if (prod.aggregated) {
            const aggregatedData = await this.calculateAggregated(prod);
            // eslint-disable-next-line no-nested-ternary
            aggregatedData.imageMatch = prod.image
              ? prod.image.score === null
                ? '0'
                : prod.image.score
              : '0';
            prod.aggregated.update(aggregatedData);
          }
        });
  
        console.log('iteration', i);
      }
  
      return true;
    }
  
    static async prepareImagesWithoutScore() {
      console.log('prepareImagesWithoutScore');
      const products = await db.product.findAll({
        include: [
          {
            model: db.coreProduct,
            as: 'coreProduct',
            attributes: ['image', 'ean'],
          },
          {
            model: db.aggregatedProduct,
            as: 'aggregated',
          },
          {
            model: db.images,
            as: 'image',
            where: {
              score: null,
              ressemblePath: { [Op.like]: '%amazonaws%' },
            },
          },
        ],
      });
      const core = path.join(path.resolve(__dirname, '../..'), '/public');
  
      console.log(`PRODUCTS: ${products.length}`);
      for (const product of products) {
        // eslint-disable-next-line no-continue
        if (product.productImage === '' || product.coreProduct.image === null) {
          continue;
        }
        const imageDb = await db.images.findOne({
          where: { id: product.imageId },
        });
  
        if (imageDb.score !== null) {
          await product.aggregated.update({
            imageMatch: imageDb.score,
          });
          // eslint-disable-next-line no-continue
          continue;
        }
  
        try {
          const ressemblePath = await AWSUtil.getImage(
            `${product.sourceType}/${product.sourceId}`,
            'ressembleImages',
          );
          const coreImageLink = await AWSUtil.getImage(
            product.coreProduct.ean,
            'coreImages',
          );
          const params = await Promise.all(
            [ressemblePath, coreImageLink].map(
              (imageURL, i) =>
                new Promise((resolve, reject) => {
                  if (!imageURL) return resolve(false);
                  https
                    .get(imageURL, response => {
                      if (response.statusCode !== 200) return false;
                      const filePath = `${core}/tmpImages/${product.coreProduct.ean}_${i}.jpg`;
                      const file = fs.createWriteStream(filePath);
                      response.pipe(file);
                      file.on('finish', () => {
                        resolve(filePath);
                      });
                      file.on('error', reject);
                    })
                    .on('error', reject);
                }),
            ),
          );
          const score = await this.compareImages(...params);
          await db.images.update({ score }, { where: { id: product.imageId } });
          await product.aggregated.update({ imageMatch: score });
          params.filter(Boolean).forEach(fs.unlinkSync);
        } catch (e) {
          console.error('this error >>>', e);
        }
      }
    }
  
    /**
     * delay execution of script
     * @param ms
     * @returns {Promise<unknown>}
     */
    static delay(ms) {
      // console.log('wait ms: '+ ms);
      return new Promise(res => setTimeout(res, ms));
    }
  
    /**
     * get image size
     * @param prImg
     * @returns {Promise<{width: number, height: number}>}
     */
    static readImageSize(prImg) {
      return Jimp.read(prImg).then(image => {
        const vars = {
          width: image.getWidth(),
          height: image.getHeight(),
        };
        console.log(vars, '12344');
        return vars;
      });
    }
  
    /**
     * compare images using resemble library
     * @param img1
     * @param img2
     * @returns {Promise<unknown>}
     */
    static async compareImages(img1, img2) {
      let score = 0;
      const images = [img1, img2];
      if (!images.every(Boolean)) return score;
      const mimeMap = {
        jpg: { mime: 'image/jpg', ext: '.jpg' },
        png: { mime: 'image/png', ext: '.png' },
      };
      const renamePromises = images.map(async img => {
        const ext = path.extname(img).substring(1);
        let mime = mimeMap[ext];
        return new Promise(resolve => {
          magic.detectFile(img, (err, result) => {
            let src = img;
            if (err) resolve(src);
            if (result === mimeMap.png.mime) mime = mimeMap.png;
            try {
              src = img.replace(mimeMap[ext].ext, mime.ext);
              console.dir({ img, src });
              fs.renameSync(img, src);
            } catch (e) {
              console.error(e);
              src = false;
            }
            resolve(src);
          });
        });
      });
      const renamedImages = await Promise.all(renamePromises);
      if (!renamedImages.every(Boolean)) return score;
      const [image1, image2] = renamedImages;
      try {
        const jimage1 = await Jimp.read(image1);
        const jimage2 = await Jimp.read(image2);
        const jimpDiff = Jimp.diff(jimage1.grayscale(), jimage2.grayscale(), 0.1);
        score = 100 - jimpDiff.percent * 100;
      } catch (e) {
        console.error('Jimp diff failure!', e);
        throw e;
      } finally {
        renamedImages.forEach((src, index) => {
          if (!src) {
            console.error(`File path ${index + 1} is falsy value`, src);
            return;
          }
          if (!fs.existsSync(src)) {
            console.error(`File ${src} is not exists!`);
            return;
          }
          try {
            fs.unlinkSync(src);
          } catch (e) {
            console.error(`File ${src} has not been deleted!`, e);
          }
        });
      }
      return score;
    }
  
    /**
     * unzip images archive
     * @param archivePath
     * @returns {Promise<void>}
     */
    static unzipArchive(archivePath) {
      const imagesDirectoryPath = path.join(
        path.resolve(__dirname, '../..'),
        '/public/images',
      );
  
      const upload = {
        queue: [],
        inProgress: false,
        add: function(key, img) {
          this.queue.push({ key, img });
          return this.next();
        },
        next: async function() {
          if (this.inProgress || !this.queue.length) return;
          try {
            const { key, img } = this.queue[0];
            this.inProgress = true;
            await AWSUtil.uploadImage({
              key,
              bucket: 'coreImages',
              file: img,
            });
            fs.unlinkSync(img);
          } catch (e) {
            console.log(`Extracted image uploading failure! ${e}`);
          } finally {
            this.inProgress = false;
          }
          // eslint-disable-next-line fp/no-mutating-methods
          this.queue.shift();
          return this.next();
        },
      };
  
      return extract(archivePath, {
        dir: imagesDirectoryPath,
        onEntry: async entry => {
          try {
            const key = path.basename(entry.fileName);
            const img = path.join(imagesDirectoryPath, entry.fileName);
            if (fs.existsSync(img)) upload.add(key, img);
            else console.log(`File ${entry.fileName} not extracted!`);
          } catch (e) {
            console.error(e);
          }
        },
      });
    }
  
    /**
     * set own retailer products {retailer}_product_id
     * @returns {Promise<void>}
     */
    static async markOwnProducts() {
      const retailers = await db.product
        .findAll({
          attributes: ['sourceType'],
          group: ['sourceType'],
          raw: true,
        })
        .map(({ sourceType }) => sourceType);
      for (const retailer of retailers) {
        const retailerProducts = await this.getOwnProducts(retailer);
        for (const product of retailerProducts) {
          await this.markOwnProduct(retailer, product);
        }
      }
    }
  
    /**
     * get retailer products
     * @param retailer
     * @returns {Promise<Model[]>}
     */
    static getOwnProducts(retailer) {
      return db.product.findAll({
        attributes: [
          'ean',
          'coreProductId',
          'sourceId',
          'retailerId',
          'sourceType',
        ],
        where: {
          sourceType: retailer,
          productTitle: this.ownProductTitleCondition(retailer),
          ean: { [Op.notLike]: `${retailer}_%` },
        },
        raw: true,
        group: ['ean', 'coreProductId', 'sourceId', 'retailerId', 'sourceType'],
      });
    }
  
    /**
     * title condition to find own products
     * @param retailer
     * @returns {{}}
     */
    static ownProductTitleCondition(retailer) {
      switch (retailer) {
        case 'ocado':
          // there are a lot of products with name avocado
          return {
            [Op.or]: [
              { [Op.like]: '%Ocado%' },
              { [Op.iLike]: '% ocado %' },
              { [Op.iLike]: 'ocado %' },
            ],
          };
        default:
          return { [Op.iLike]: `%${retailer}%` };
      }
    }
  
    /**
     * mark retailer products
     * @param retailer
     * @param product
     * @returns {Promise<void>}
     */
    static async markOwnProduct(retailer, product) {
      const { ean, coreProductId, retailerId, sourceId, sourceType } = product;
      const newEan = `${retailer}_${ean}`;
  
      let core = await this.coreByCondition({ where: { ean: newEan } });
      if (!core) {
        const oldCore = await this.coreByCondition({
          where: { ean },
          raw: true,
        });
        oldCore.ean = newEan;
        const newCore = omit(oldCore, ['id', 'createdAt', 'updatedAt']);
        core = await this.createCoreBy(newCore);
      }
      await ProductService.setCoreRetailer({
        coreProductId: core.id,
        retailerId,
        productId: sourceId,
      });
  
      await db.product.update(
        {
          ean: newEan,
          coreProductId: core.id,
        },
        {
          where: { ean, coreProductId, sourceType },
        },
      );
  
      const productsWithOldCoreProduct = await db.product.count({
        where: { coreProductId },
      });
      if (productsWithOldCoreProduct === 0) {
        await db.coreRetailer.destroy({
          where: { coreProductId },
        });
        await db.taxonomyProduct.update(
          {
            coreProductId: core.id,
          },
          {
            where: { coreProductId },
          },
        );
        await db.coreProduct
          .scope('withMaster')
          .destroy({ where: { id: coreProductId } });
      }
    }
  
    /**
     * process mapping suggestions script
     * @param coreProducts
     * @returns {Promise<void>}
     */
    static async findSuggestions(coreProducts) {
      const cores = CompareUtil.prepareProductsData(coreProducts);
      const images = await CompareUtil.prepareProductImageAll(cores);
  
      const suggestionList = await db.mappingSuggestion.findAll({
        where: {
          coreProductId: {
            [Op.in]: [...cores.wrong.keys()],
          },
        },
      });
  
      const suggestions = suggestionList.reduce((acc, row) => {
        const item = acc.get(row.coreProductId) || new Set();
        item.add(row.suggestedProductId);
        acc.set(row.coreProductId, item);
        return acc;
      }, new Map());
  
      let wrongCoreIndex = 0;
      const wrongCoreSize = cores.wrong.size;
  
      for (const wrongCore of cores.wrong.values()) {
        const wc = await ProductService.getCoreById(wrongCore.id);
        // eslint-disable-next-line no-continue
        if (CompareUtil.checkEAN(wc.ean)) continue;
        let results = [];
        const suggestionCores = suggestions.get(wrongCore.id) || new Set();
        // eslint-disable-next-line no-plusplus
        console.log(
          `============= WRONG CORE ${++wrongCoreIndex} of ${wrongCoreSize}; PRODUCTS: ${
            wrongCore.products.size
          }; CORRECT: ${cores.correct.size}`,
        );
  
        for (const wrongProduct of wrongCore.products.values()) {
          const wrongImage = images.get(`${wrongCore.id}_${wrongProduct.id}`);
  
          for (const core of cores.correct.values()) {
            // eslint-disable-next-line no-continue
            if (suggestionCores.has(core.id)) continue; // Skip exists suggestion
  
            for (const product of core.products.values()) {
              const matches = {
                title: CompareUtil.compareStrings(
                  wrongProduct.title,
                  product.title,
                ),
                weight:
                  isNaN(wrongProduct.size) || isNaN(product.size)
                    ? CompareUtil.compareStrings(
                        wrongProduct.productWeight,
                        product.productWeight,
                      )
                    : CompareUtil.comparePercent(wrongProduct.size, product.size),
                price: CompareUtil.comparePercent(
                  wrongProduct.promotedPrice,
                  product.promotedPrice,
                ),
                // eslint-disable-next-line max-len
                ingredients: CompareUtil.compareStrings(
                  wrongProduct.productInfo,
                  product.productInfo,
                ),
                nutritional: CompareUtil.compareObjects(
                  wrongProduct.nutritional,
                  product.nutritional,
                  ['fat', 'protein', 'carbohydrate'],
                ),
              };
              // eslint-disable-next-line no-continue
              if (matches.title < 0.3 || matches.ingredients < 0.3) {
                continue;
              }
              const correctImage = images.get(`${core.id}_${product.id}`);
              matches.image = await CompareUtil.compareImages(
                wrongImage,
                correctImage,
              );
              const matchesArray = Object.values(matches).filter(
                value => Number(value) > 0,
              );
              const match =
                matchesArray.reduce((a, b) => a + (b || 0), 0) /
                matchesArray.length;
  
              // eslint-disable-next-line no-continue
              if (match < 0.75) continue;
              results = [
                ...results,
                {
                  coreProductId: wrongCore.id,
                  coreProductProduct: wrongProduct.id,
                  suggestedProductId: core.id,
                  suggestedProductProduct: product.id,
                  match,
                  matchTitle: matches.title,
                  matchIngredients: matches.ingredients,
                  matchNutritional: matches.nutritional,
                  matchImage: matches.image,
                  matchWeight: matches.weight,
                  matchPrice: matches.price,
                },
              ];
            }
          }
        }
  
        // eslint-disable-next-line no-continue
        if (!results.length) continue;
        const rows = results.reduce((acc, obj) => {
          if (ProductService.replaceCoreCondition(obj)) {
            const index = acc.findIndex(
              item =>
                item.coreProductId === obj.coreProductId &&
                item.match === obj.match,
            );
            if (index >= 0 && acc[index].matchImage < obj.matchImage) {
              acc[index] = obj;
            }
            // eslint-disable-next-line no-param-reassign
            else acc = [obj];
          } else {
            if (acc.find(item => ProductService.replaceCoreCondition(item))) {
              return acc;
            }
            const index = acc.findIndex(
              item =>
                item.coreProductId === obj.coreProductId &&
                item.suggestedProductId === obj.suggestedProductId,
            );
            // eslint-disable-next-line no-param-reassign
            if (index < 0) acc = [...acc, obj];
            else if (index >= 0 && acc[index].matchImage < obj.matchImage) {
              acc[index] = obj;
            }
          }
          return acc;
        }, []);
        await ProductService.addSuggestions(rows);
      }
    }
  
    /**
     * add new mapping suggestion
     * @param rows
     * @returns {Promise<*[]|boolean[][]>}
     */
    static async addSuggestions(rows) {
      let match = null;
      const suggestions = [];
      for (const row of rows) {
        const core = await db.coreProduct.findOne({
          where: { id: row.coreProductId },
        });
        if (!CompareUtil.checkEAN(core.ean)) {
          if (ProductService.replaceCoreCondition(row)) {
            match = row;
            break;
          } else suggestions.push(row);
        }
      }
  
      if (match) {
        await ProductService.replaceCore(
          match.coreProductId,
          match.suggestedProductId,
          'id',
          true,
        );
        await db.mappingLog.create({ log: match });
        console.log(
          '======================== SET CORE PRODUCT ===============================',
          match,
        );
        return [[match, false]];
      }
      return Promise.all(
        suggestions.map(row => MappingSuggestionService.create(row)),
      );
    }
  
    /**
     * replace wrong core product with the new one
     * @param id
     * @param suggestedId
     * @param key
     * @param auto
     * @returns {Promise<boolean|{error: string, status: boolean}>}
     */
    static async replaceCore(id, suggestedId, key, auto = false) {
      const wrongCore = await db.coreProduct.findOne({
        where: { id },
        include: [
          {
            model: db.coreRetailer,
            as: 'coreRetailers',
            required: false,
            include: [
              {
                model: db.review,
                as: 'reviews',
                required: false,
              },
            ],
          },
          'countryData',
        ],
      });
      const correctCore = await db.coreProduct.findOne({
        where: { [key]: suggestedId },
        include: [
          {
            model: db.coreRetailer,
            as: 'coreRetailers',
            required: false,
            include: [
              {
                model: db.review,
                as: 'reviews',
                required: false,
              },
            ],
          },
          'countryData',
        ],
      });
      const wrongCoreRetailers = wrongCore.get({ plain: true });
      let suggestion;
  
      const log = {
        coreProductId: 0,
        coreProductProduct: 0,
        suggestedProductId: 0,
        suggestedProductProduct: 0,
        match: 0,
        matchTitle: 0,
        matchIngredients: 0,
        matchNutritional: 0,
        matchImage: 0,
        matchWeight: 0,
        matchPrice: 0,
      };
  
      if (key === 'id') {
        suggestion = await db.mappingSuggestion.findOne({
          where: {
            coreProductId: Number(id),
            suggestedProductId: Number(suggestedId),
          },
        });
        if (suggestion) {
          log.match = suggestion.match;
          log.matchTitle = suggestion.matchTitle;
          log.matchIngredients = suggestion.matchIngredients;
          log.matchNutritional = suggestion.matchNutritional;
          log.matchImage = suggestion.matchImage;
          log.matchWeight = suggestion.matchWeight;
          log.matchPrice = suggestion.matchPrice;
        }
      }
  
      if (!auto) {
        const coreId = correctCore ? correctCore.id : wrongCore.id;
        log.coreProductId = wrongCore.id;
        log.suggestedProductId = coreId;
        const suggestedProductProduct = await this.getProduct(coreId);
        const coreProductProduct = await this.getProduct(wrongCore.id);
        log.suggestedProductProduct = suggestedProductProduct
          ? suggestedProductProduct.id
          : null;
        log.coreProductProduct = coreProductProduct
          ? coreProductProduct.id
          : null;
        await db.mappingLog.create({ log, manual: true });
      }
  
      if (!correctCore && key === 'ean') {
        await wrongCore.update({ ean: suggestedId, eanIssues: false });
        await db.mappingSuggestion.destroy({
          where: { coreProductId: id },
        });
        await db.product.update(
          { ean: suggestedId },
          { where: { coreProductId: id } },
        );
        logger.log({
          name: 'EAN and no Core',
          suggestedId,
          id,
          cr: wrongCoreRetailers.coreRetailers,
        });
      } else if (correctCore && key === 'ean') {
        await db.mappingSuggestion.destroy({
          where: { coreProductId: id },
        });
        await db.product.update(
          { coreProductId: correctCore.id, ean: correctCore.ean },
          { where: { coreProductId: id } },
        );
        logger.log({
          name: 'EAN and Core Exists',
          suggestedId,
          id,
          cr: wrongCoreRetailers.coreRetailers,
        });
        try {
          for (const coreRetailer of wrongCore.coreRetailers) {
            const exists = correctCore.coreRetailers.find(
              row =>
                row.productId === wrongCore.productId &&
                row.retailerId === wrongCore.retailerId,
            );
            if (exists) {
              await coreRetailer.destroy();
            } else {
              await coreRetailer.update({ coreProductId: correctCore.id });
            }
          }
  
          await db.taxonomyProduct.update(
            { coreProductId: correctCore.id },
            { where: { coreProductId: id } },
          );
          await db.coreProductBarcode.update(
            { coreProductId: correctCore.id },
            { where: { coreProductId: id } },
          );
          const wrongReviews = wrongCore && wrongCore.coreRetailers && wrongCore.coreRetailers.reduce((acc, coreRetailer) => {
            return [
              ...acc,
              ...coreRetailer.reviews.map(r => {
                return {
                  id: r.id,
                  coreProductId: coreRetailer.coreProductId,
                  retailerId: coreRetailer.retailerId,
                  productId: coreRetailer.productId,
                  coreRetailerId: r.coreRetailerId,
                  reviewId: r.reviewId,
                }
              }),
            ];
          }, []);
          const correctReviews = correctCore.coreRetailers && correctCore.coreRetailers.reduce((acc, coreRetailer) => {
            return [
              ...acc,
              ...coreRetailer.reviews.map(r => {
                return {
                  id: r.id,
                  coreProductId: coreRetailer.coreProductId,
                  retailerId: coreRetailer.retailerId,
                  productId: coreRetailer.productId,
                  coreRetailerId: r.coreRetailerId,
                  reviewId: r.reviewId,
                }
              }),
            ];
          }, []);
  
          if (wrongReviews) {
            const doneCoreRetailers = [];
            for (const wReview of wrongReviews) {
              const correctReview = correctReviews && correctReviews.find(r => r.retailerId === wReview.retailerId && r.reviewId === wReview.reviewId)
              if (correctReview) {
                await db.review.destroy({
                  where: { id: wReview.id },
                });
    
              } else {
                const targetCoreRetailer = await db.coreRetailer.findOne({
                  where: {
                    coreProductId: correctCore.id,
                    retailerId: wReview.retailerId,
                    productId: wReview.productId,
                  },
                });
    
                if (!targetCoreRetailer) {
                  if (!doneCoreRetailers.some(rid => rid === wReview.coreRetailerId)) {    
                    await db.coreRetailer.update(
                      { coreProductId: correctCore.id },
                      { where: { id: wReview.coreRetailerId } },
                    );
                    doneCoreRetailers.push(wReview.coreRetailerId);
                  }
    
                } else {
                    await db.review.update(
                      { coreRetailerId: targetCoreRetailer.id },
                      { where: { id: wReview.id} },
                    );
                }
              }
            };
          }
  
        } catch (e) {
          logger.log(
            {
              name: 'EAN and Core Exists Error Catched',
              suggestedId,
              id,
              cr: wrongCoreRetailers.coreRetailers,
              e,
            },
            'FgRed',
          );
        }
        for (const cpd of wrongCore.countryData) {
          const exists = correctCore.countryData.find(
            row => row.countryId === cpd.countryId,
          );
          if (!exists) {
            const newData = {
              ...cpd.toJSON(),
              coreProductId: correctCore.id,
            };
            delete newData.id;
            await db.coreProductCountryData.create(newData);
          }
        }
        await db.coreProduct.update({ disabled: true }, { where: { id: id } });
  
        if (correctCore.brandId === null && wrongCore.brandId !== null) {
          // eslint-disable-next-line max-len
          await db.coreProduct.update(
            { brandId: wrongCore.brandId },
            { where: { id: correctCore.id } },
          );
        }
      }
      return { status: true, error: '', coreProduct: correctCore };
    }
  
    /**
     * get total products by date and retailer
     * @param date
     * @returns {Promise<*>}
     */
    static async getTotalByDate(date) {
      const query =
        'select date_trunc(\'day\', date) as "date", count(id) as "total", "sourceType" as "retailer" from products where date >= :date group by date, "sourceType"';
      const queryParams = {
        raw: true,
        type: QueryTypes.SELECT,
        replacements: { date },
      };
      return db.sequelize.query(query, queryParams);
    }
  
    /**
     * automapping replace condition
     * @param row
     * @returns {boolean|boolean}
     */
    static replaceCoreCondition(row) {
      return (
        (row.matchNutritional === 1 &&
          row.matchWeight === 1 &&
          row.matchImage >= 0.95) ||
        (row.match >= 0.9 &&
          row.matchWeight === 1 &&
          row.matchIngredients === 1 &&
          row.matchImage >= 0.95)
      );
    }
  
    static getProduct(id) {
      return db.product.findOne({
        where: {
          coreProductId: Number(id),
        },
        attributes: ['id'],
      });
    }
  
    /**
     * Select previous products and compare with uploaded from the scraper
     * @param products
     * @param retailerId
     * @returns {Promise<*[]>}
     */
    static async prepareProductsStatus(products, retailerId) {
      if (!products.length) return products;
      // TODO temporary disabled
      // const date = products[0].date;
      // const ids = products.map(product => product.sourceId);
      // const cores = await db.coreRetailer.findAll({
      //   where: {
      //     retailerId,
      //     productId: { [Op.in]: ids },
      //   },
      // });
      // const today = new Date();
      // const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1, 0, 0, 0);
      // const end = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0);
      // const prevResult = await db.product.findAll({
      //   where: {
      //     retailerId,
      //     date: {
      //       [Op.gte]: start,
      //       [Op.lt]: end,
      //     },
      //   },
      //   include: ['productsData'],
      // });
      // const deListed = prevResult.filter((row) => {
      //   const item = products.find(product => product.sourceId === row.sourceId);
      //   return !item || item.productInStock === false;
      // }).map(row => ({
      //   ...cloneFields.reduce((obj, key) => ({ ...obj, [key]: row[key] }), {}),
      //   date,
      //   status: 'de-listed',
      //   promotions: false,
      //   promotionDescription: '',
      //   category: row.productsData[0].category,
      //   categoryType: row.productsData[0].categoryType,
      //   parentCategory: row.productsData[0].parentCategory,
      //   productRank: row.productsData[0].productRank,
      //   pageNumber: row.productsData[0].pageNumber,
      // }));
      const result = products.map(product => {
        // if (cores.find(core => core.productId === product.sourceId)) {
        //   const prev = prevResult.find(item => item.sourceId === product.sourceId);
        //   if (prev) product.status = prev.status === 'de-listed' ? 're-listed' : 'available';
        // } else {
        product.status = 'listed';
        // }
        return product;
      });
      return [...result];
    }
  
    static async replaceCoreProductsImagesToAWS() {
      console.log('==============================');
      console.log('replaceCoreProductsImagesToAWS');
      console.log('==============================');
      // eslint-disable-next-line one-var
      let notFound = 0,
        uploaded = 0,
        removed = 0;
      const uploadList = [];
      // get all cores with images
      const cores = await db.coreProduct.findAll();
      // check aws link and filter
      const list = cores.filter(
        ({ image }) => !image || !image.includes('bn.core-images'),
      );
      // check images existing
      for (const core of list) {
        const img = path.join(
          path.resolve(__dirname, '../..'),
          'public',
          core.image || `${core.ean}.jpg`,
        );
        if (fs.existsSync(img)) uploadList.push({ core, img });
        // eslint-disable-next-line no-plusplus
        else notFound++;
      }
      console.log(
        `Found ${uploadList.length} images of ${list.length}(${cores.length}) cores`,
      );
      // upload image to bucket
      for (const [i, { core, img }] of uploadList.entries()) {
        try {
          console.log(
            `=> Uploading ${i + 1}/${uploadList.length} images. EAN: ${
              core.ean
            }; image: "${img}"`,
          );
          const image = await AWSUtil.uploadImage({
            key: core.ean,
            bucket: 'coreImages',
            file: img,
          });
          // eslint-disable-next-line no-plusplus
          console.log(`> UPLOADED! Count: ${++uploaded}`);
          console.log(`Image URL: ${image}`);
          // set new image link to core.image
          if (image) {
            await core.update({ image });
            console.log('> UPDATED!');
            // remove old image file
            fs.unlinkSync(img);
          } else {
            console.log('> IMAGE UPLOAD ERROR: NULL image');
          }
          // eslint-disable-next-line no-plusplus
          console.log(`> REMOVED! Count: ${++removed}`);
        } catch (e) {
          console.error(e);
        }
      }
      return { notFound, uploaded, removed };
    }
    static async replaceBannerImagesToAWS() {
      console.log('========================');
      console.log('replaceBannerImagesToAWS');
      console.log('========================');
      // eslint-disable-next-line one-var
      let notFound = 0,
        uploaded = 0,
        removed = 0;
      const uploadList = [];
      try {
        // get all cores with images
        const banners = await db.banners.findAll({
          include: [
            {
              model: db.retailer,
              as: 'retailer',
              required: true,
            },
          ],
          where: {
            image: {
              [Op.and]: [
                { [Op.ne]: null },
                { [Op.ne]: 'false' },
                { [Op.ne]: '' },
              ],
            },
          },
        });
        // check aws link and filter
        const list = banners.filter(
          ({ image }) => !image.includes('bn.banner-images'),
        );
        // check images existing
        for (const banner of list) {
          const img = path.join(
            path.resolve(__dirname, '../..'),
            'public',
            banner.image,
          );
          if (fs.existsSync(img)) uploadList.push({ banner, img });
          // eslint-disable-next-line no-plusplus
          else notFound++;
        }
        console.log(
          `Found ${uploadList.length} images of ${list.length}(${banners.length}) banners`,
        );
        for (const [i, { banner, img }] of uploadList.entries()) {
          try {
            console.log(
              `=> Uploading ${i + 1}/${uploadList.length} images. id: ${
                banner.id
              }; image: "${img}"`,
            );
            const image = await AWSUtil.uploadImage({
              key: `${banner.retailer.name}/${+new Date()}`,
              bucket: 'bannerImages',
              file: img,
            });
            // eslint-disable-next-line no-plusplus
            console.log(`> UPLOADED! Count: ${++uploaded}`);
            console.log(`Image URL: ${image}`);
            // set new image link to core.image
            if (image) {
              await banner.update({ image });
              console.log('> UPDATED!');
              // remove old image file
              fs.unlinkSync(img);
            } else {
              console.log('> IMAGE UPLOAD ERROR: NULL image');
            }
            // eslint-disable-next-line no-plusplus
            console.log(`> REMOVED! Count: ${++removed}`);
          } catch (e) {
            console.error(e);
          }
        }
      } catch (e) {
        console.error(e);
      }
      return { notFound, uploaded, removed };
    }
    static async replaceBannerScreenshotsToAWS() {
      console.log('=============================');
      console.log('replaceBannerScreenshotsToAWS');
      console.log('=============================');
      // eslint-disable-next-line one-var
      let notFound = 0,
        uploaded = 0,
        removed = 0;
      const uploadList = [];
      try {
        // get all cores with images
        const banners = await db.banners.findAll({
          include: [
            {
              model: db.retailer,
              as: 'retailer',
              required: true,
            },
          ],
          where: {
            screenshot: {
              [Op.and]: [
                { [Op.ne]: null },
                { [Op.ne]: 'false' },
                { [Op.ne]: '' },
              ],
            },
          },
        });
        // check aws link and filter
        const list = banners.filter(
          ({ screenshot }) => !screenshot.includes('bn.banner-screenshots'),
        );
        // check images existing
        for (const banner of list) {
          const screenshot = path.join(
            path.resolve(__dirname, '../..'),
            'public',
            banner.screenshot,
          );
          if (fs.existsSync(screenshot)) {
            uploadList.push({ banner, screenshot });
          }
          // eslint-disable-next-line no-plusplus
          else notFound++;
        }
        console.log(
          `Found ${uploadList.length} images of ${list.length}(${banners.length}) banners`,
        );
        for (const [i, { banner, screenshot }] of uploadList.entries()) {
          try {
            console.log(
              `=> Uploading ${i + 1}/${uploadList.length} images. id: ${
                banner.id
              }; screenshot: "${screenshot}"`,
            );
            const image = await AWSUtil.uploadImage({
              key: `${banner.retailer.name}/${+new Date()}`,
              bucket: 'bannerScreenshots',
              file: screenshot,
            });
            // eslint-disable-next-line no-plusplus
            console.log(`> UPLOADED! Count: ${++uploaded}`);
            console.log(`Image URL: ${image}`);
            // set new image link to core.image
            if (image) {
              await banner.update({ screenshot: image });
              console.log('> UPDATED!');
              // remove old image file
              fs.unlinkSync(screenshot);
            } else {
              console.log('> IMAGE UPLOAD ERROR: NULL image');
            }
            // eslint-disable-next-line no-plusplus
            console.log(`> REMOVED! Count: ${++removed}`);
          } catch (e) {
            console.error(e);
          }
        }
      } catch (e) {
        console.error(e);
      }
      return { notFound, uploaded, removed };
    }
    static async replaceCompareImagesToAWS() {
      console.log('=========================');
      console.log('replaceCompareImagesToAWS');
      console.log('=========================');
      const imageSize = { width: 225, height: 225 };
      // eslint-disable-next-line one-var
      let notFound = 0,
        uploaded = 0,
        removed = 0;
      const uploadList = [];
      // get all cores with images
      try {
        const products = await ProductService.getAllRetailerProducts();
        // check images existing
        for (const product of products) {
          const directoryPath = path.join(
            path.resolve(__dirname, '../..'),
            '/public/imageComparing',
          );
          const img = `${directoryPath}/${product.sourceType}_${product.sourceId}_${imageSize.width}x${imageSize.height}.jpg`;
          if (fs.existsSync(img)) {
            uploadList.push({ product, img });
          } else {
            // eslint-disable-next-line no-plusplus
            notFound++;
          }
        }
        console.log(
          `Found ${uploadList.length} images of ${products.length} products`,
        );
        for (const [i, { product, img }] of uploadList.entries()) {
          try {
            console.log(
              `=> Uploading ${i + 1}/${uploadList.length} images. id: ${
                product.id
              }; image: "${img}"`,
            );
            const imageAWSKey = `${product.sourceType}/${product.sourceId}_${imageSize.width}x${imageSize.height}`;
            const image = await AWSUtil.uploadImage({
              key: imageAWSKey,
              bucket: 'compareImages',
              file: img,
            });
            // eslint-disable-next-line no-plusplus
            console.log(`> UPLOADED! Count: ${++uploaded}`);
            console.log(`Image URL: ${image}`);
            // remove old image file
            fs.unlinkSync(img);
            // eslint-disable-next-line no-plusplus
            console.log(`> REMOVED! Count: ${++removed}`);
          } catch (e) {
            console.error(e);
          }
        }
      } catch (e) {
        console.error(e);
      }
      return { notFound, uploaded, removed };
    }
    static async replaceRessembleImagesToAWS() {
      console.log('===========================');
      console.log('replaceRessembleImagesToAWS');
      console.log('===========================');
      // eslint-disable-next-line one-var
      let notFound = 0,
        uploaded = 0,
        removed = 0;
      const uploadList = [];
      // get all cores with images
      try {
        const images = await db.images.findAll({
          include: [
            {
              model: db.product,
              as: 'products',
              required: true,
              attributes: ['id', 'sourceType', 'sourceId'],
            },
          ],
          where: { ressemblePath: { [Op.like]: '%ressembleImages%' } },
        });
        // check aws link and filter
        const list = images.filter(
          ({ ressemblePath }) => !ressemblePath.includes('bn.ressemble-images'),
        );
        // check images existing
        for (const image of list) {
          const img = path.join(
            path.resolve(__dirname, '../..'),
            'public',
            image.ressemblePath,
          );
          if (fs.existsSync(img)) uploadList.push({ image, img });
          // eslint-disable-next-line no-plusplus
          else notFound++;
        }
        console.log(
          `Found ${uploadList.length} images of ${list.length}(${images.length}) image items`,
        );
        for (const [i, { image, img }] of uploadList.entries()) {
          try {
            const product = image.products[0];
            console.log(
              `=> Uploading ${i + 1}/${uploadList.length} images. id: ${
                image.id
              }; image: "${img}"`,
            );
            const ressemblePath = await AWSUtil.uploadImage({
              key: `${product.sourceType}/${product.sourceId}`,
              bucket: 'ressembleImages',
              file: img,
            });
            // eslint-disable-next-line no-plusplus
            console.log(`> UPLOADED! Count: ${++uploaded}`);
            console.log(`Image URL: ${ressemblePath}`);
            // set new image link to core.image
            await image.update({ ressemblePath });
            console.log('> UPDATED!');
            // remove old image file
            fs.unlinkSync(img);
            // eslint-disable-next-line no-plusplus
            console.log(`> REMOVED! Count: ${++removed}`);
          } catch (e) {
            console.error(e);
          }
        }
      } catch (e) {
        console.error(e);
      }
      return { notFound, uploaded, removed };
    }
  
   
  
  
  
    static async processProductReviews(reviews, product, retailer) {
      // eslint-disable-next-line max-len
      const coreRetailer = await db.coreRetailer.findOne({
        where: { retailerId: retailer.id, productId: product.id },
      });
      if (!coreRetailer) return;
      for (const review of reviews) {
        const value = {
          coreRetailerId: coreRetailer.id,
          title: review.title,
          comment: review.comment,
          rating: review.rating,
          date: review.date,
        };
        await db.review.findOrCreate({ where: value, defaults: value });
      }
    }
  
    static async resolveMSConflict() {
      let ms = 'M&S';
      const msEANRegExp = /^M[0-9]{4,8}S$/;
      const typeENUM = { MS: 'ms', S: 's' };
      const getMSEAN = ean => (ean ? `M${ean.slice(-8)}S` : ean);
  
      const msQuery = await db.sequelize.query(
        `SELECT DISTINCT P1.ean, P1."coreProductId", P1."productTitle", P1."productImage", P1."secondaryImages", P1."productDescription", P1.features, P1."productInfo", P1.size, P1.nutritional, P1."productBrand", CP1.title
      FROM "coreProducts" AS CP1
      INNER JOIN "products" AS P1 ON P1."coreProductId" = CP1.id
      WHERE P1."retailerId" = 3
      AND CP1.title LIKE '${ms}%'
      ORDER BY P1."productTitle" ASC`,
        { type: QueryTypes.SELECT },
      );
  
      const sQuery = await db.sequelize.query(
        `SELECT DISTINCT P1.ean, P1."coreProductId", P1."productTitle", P1."productImage", P1."secondaryImages", P1."productDescription", P1.features, P1."productInfo", P1.size, P1.nutritional, P1."productBrand", CP1.title
      FROM products AS P1
      INNER JOIN "coreProducts" AS CP1 ON P1."coreProductId" = CP1.id
      INNER JOIN "brands" AS B1 ON CP1."brandId" = B1.id
      WHERE P1."retailerId" = 8
      AND B1.name LIKE 'Sainsbury%'
      ORDER BY P1."productTitle" ASC`,
        { type: QueryTypes.SELECT },
      );
  
      // brand map
      const productBrands = [...msQuery, ...sQuery].reduce(
        (acc, row) => ({
          ...acc,
          [row.productBrand]: `%${row.productBrand.trim()}%`,
        }),
        {},
      );
      const brands = await db.brands.findAll({
        where: {
          [Op.or]: [
            {
              checkList: {
                [Op.or]: Object.values(productBrands).map(str => ({
                  [Op.like]: str,
                })),
              },
            },
            {
              name: {
                [Op.in]: Object.keys(productBrands).map(str => str.trim()),
              },
            },
          ],
        },
      });
  
      for (const brand of brands) {
        const checkList = brand.checkList ? Array.from(brand.checkList) : [];
        const key =
          checkList.find(str => !!productBrands[str]) || productBrands[brand.name]
            ? brand.name
            : false;
        if (!key) continue;
        productBrands[key] = brand;
      }
  
      const country = await db.country.findOne({ where: { iso3: 'GBR' } });
      const result = {};
      const conflictMap = { ms: msQuery, s: sQuery };
  
      for (const type of Object.keys(conflictMap)) {
        const rows = conflictMap[type];
        result[type] = {};
  
        const group = rows.reduce((acc, row) => {
          const key = row.ean;
          if (!acc[key]) acc[key] = [];
          acc[key].push(row);
          return acc;
        }, {});
        const products = Object.keys(group).map(ean =>
          type === typeENUM.MS
            ? group[ean].reduce((acc, row) =>
                row.size > acc.size || `${row.size}`.endsWith('0') ? row : acc,
              )
            : group[ean].slice(-1)[0],
        );
  
        const coreProductData = products.map(product => {
          const brand = productBrands[product.productBrand] || { id: null };
          return {
            coreProductId: product.coreProductId,
            data: {
              ean: product.ean,
              title: product.productTitle,
              image: product.productImage,
              brandId: brand.id || null,
              bundled: product.bundled,
              secondaryImages: product.secondaryImages,
              description: product.productDescription,
              features: product.features,
              ingredients: product.productInfo,
              size: product.size,
              specification: product.nutritional,
              productOptions: product.productOptions || false,
              eanIssues: !CompareUtil.checkEAN(product.ean),
            },
          };
        });
  
        const productDataCount = coreProductData.length;
        for (const [
          index,
          { coreProductId, data },
        ] of coreProductData.entries()) {
          const step = `${index + 1}/${productDataCount}(${type})`;
          console.time(step);
          console.log(step);
          console.dir({ coreProductId, data });
          let oldCore = await db.coreProduct.findOne({
            where: { id: coreProductId },
          });
          let oldCoreProducts = [];
          let oldBarcode = null;
          const msTitle = oldCore.title.includes(ms);
          const msEAN = msEANRegExp.test(oldCore.ean);
          if (type === typeENUM.MS && !!oldCore && msTitle && !msEAN) {
            const ean = getMSEAN(oldCore.ean);
            // update core and products ean, and barcode entity
            oldCore = await oldCore.update({ ean }, { returning: true });
            oldCoreProducts = await db.product.update(
              { ean },
              {
                where: { coreProductId: oldCore.id, retailerId: 8 },
                returning: true,
              },
            );
            oldBarcode = await db.coreProductBarcode.update(
              {
                barcode: ean,
              },
              {
                where: { coreProductId, barcode: data.ean },
                returning: true,
              },
            );
          }
          data.ean = type === typeENUM.MS ? data.ean : getMSEAN(data.ean);
          let core = await db.coreProduct.findOne({
            where: { ean: data.ean },
          });
          let freshCore = false;
          // create cores(upload image)
          if (!core) {
            core = await this.createCoreBy(data);
            freshCore = true;
          }
          // create cores country data
          if (!core.countryData || !core.countryData.id) {
            await CoreProductService.createProductCountryData(
              core,
              country.id,
              data,
              freshCore,
            );
          }
          // change coreProductId on products table
          const productList = await db.product.update(
            { coreProductId: core.id, ean: core.ean },
            {
              where: { coreProductId, retailerId: type === typeENUM.MS ? 3 : 8 },
              returning: true,
            },
          );
          // change coreRetailer entries
          const coreRetailer = await db.coreRetailer.update(
            { coreProductId: core.id },
            {
              where: {
                coreProductId,
                productId: {
                  [Op.in]: [
                    ...productList[1].reduce(
                      (acc, row) => acc.add(row.sourceId),
                      new Set(),
                    ),
                  ],
                },
              },
              returning: true,
            },
          );
          result[type][data.ean] = {
            oldCore,
            core,
            oldCoreProducts: oldCoreProducts[0],
            oldBarcode,
            productCount: productList[0],
            coreRetailer: coreRetailer[1],
          };
          console.timeEnd(step);
        }
      }
  
      const restCoreProducts = await db.coreProduct.scope('withMaster').findAll({
        where: {
          title: {
            [Op.like]: `${ms}%`,
          },
          ean: {
            [Op.regexp]: '^\\d+[,]?',
          },
        },
      });
  
      console.dir({ rest: restCoreProducts.length });
  
      const restCoreProductCount = restCoreProducts.length;
      for (const [index, coreProduct] of restCoreProducts.entries()) {
        const step = `${index + 1}/${restCoreProductCount}`;
        console.time(step);
        console.log(step);
        console.dir({ coreProductId: coreProduct.id });
        const msEAN = msEANRegExp.test(coreProduct.ean);
        if (msEAN) continue;
        const barcodes = coreProduct.ean.split(',');
        const ean = getMSEAN(barcodes[0]);
        console.dir({ barcode: barcodes[0], ean });
        try {
          await db.coreProductBarcode.update(
            { barcode: ean },
            {
              where: { coreProductId: coreProduct.id, barcode: coreProduct.ean },
            },
          );
          if (barcodes.length > 1) {
            for (const barcode of barcodes) {
              try {
                const barcodeEntity = await db.coreProductBarcode.findOne({
                  where: { coreProductId: coreProduct.id, barcode },
                });
                if (barcodeEntity) {
                  await barcodeEntity.update({ barcode: getMSEAN(barcode) });
                } else {
                  await db.coreProductBarcode.create({
                    coreProductId: coreProduct.id,
                    barcode: getMSEAN(barcode),
                  });
                }
              } catch (e) {
                console.error('Additiobal barcode issue!', e);
              }
            }
          }
          await coreProduct.update({ ean });
          await db.product.update(
            { ean },
            { where: { coreProductId: coreProduct.id } },
          );
        } catch (e) {
          console.error(e);
        }
        console.timeEnd(step);
      }
  
      return result;
    }
  }

