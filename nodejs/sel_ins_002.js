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