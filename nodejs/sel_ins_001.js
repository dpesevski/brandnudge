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