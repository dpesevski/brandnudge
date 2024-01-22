import moment from 'moment';
import { Op } from 'sequelize';
import db from '../models';

const defaultMechanic = 'Other';

function textToNumber(str) {
    const numMap = {
        one: 1,
        two: 2,
        three: 3,
        four: 4,
        five: 5,
        six: 6,
        seven: 7,
        eight: 8,
        nine: 9,
        ten: 10,
    };

    return Object.keys(numMap).reduce(
        (res, text) => res.replace(new RegExp(text, 'gi'), numMap[text]),
        str,
    );
}

function numPrice(price) {
    if (!price) return 1;
    if (!isNaN(price)) return price;
    if (price.includes('£')) return parseFloat(price.split('£')[1]).toFixed(2);
    else if (price.includes('p'))
        return parseFloat(price.split('p')[0] / 100).toFixed(2);
    return price;
}

function parseDate(d) {
    try {
        if (!d) return null;
        if (Date.parse(d)) return new Date(d).toLocaleDateString();
        // eslint-disable-next-line no-useless-escape
        const arr = d.split(/[-\/.]/);
        if (arr.length !== 3) return false;
        const month = arr[1] - 1;
        const year = arr[0].length === 4 ? arr[0] : arr[2];
        const date = arr[0].length === 4 ? arr[2] : arr[0];
        return new Date(year, month, date).toLocaleDateString();
    } catch (e) {
        console.error('parseDate failure!', e);
        return null;
    }
}

export default class PromotionService {
    /**
     * Create wrapper for retailer promotion search function
     * @param retailerId
     * @returns {Promise<function(*): Promise<boolean|{[p: string]: *}>>}
     */
    static async findRetailerPromotion(retailerId) {
        const retailerPromotions = await db.retailerPromotion.findAll({
            where: { retailerId },
            include: ['promotionMechanic'],
        });
        return async promotion => {
            const desc = textToNumber(
                promotion.description.replace(',', '').toLowerCase(),
            );
            let promo = retailerPromotions.find(item => {
                if (!item.promotionMechanic) return false;
                if (
                    item.promotionMechanic.name.toLowerCase() ===
                    (promotion.mechanic || '').toLowerCase()
                )
                    return true;
                if (!item.regexp || !item.regexp.length) return false;
                if (
                    item.promotionMechanic.name === 'Multibuy' &&
                    /(\d+\/\d+)/.test(desc)
                ) {
                    return false;
                }
                return new RegExp(item.regexp, 'i').test(desc);
            });
            let mechanic = promo
                ? promo.promotionMechanic
                : { name: defaultMechanic };
            if (!promo) {
                [mechanic] = await db.promotionMechanic.findOrCreate({
                    where: { name: defaultMechanic },
                    defaults: { name: defaultMechanic },
                });
                // eslint-disable-next-line no-continue
                if (!mechanic) return false;
                const obj = {
                    retailerId: retailerId,
                    promotionMechanicId: mechanic.id,
                };
                [promo] = await db.retailerPromotion.findOrCreate({
                    where: obj,
                    defaults: obj,
                });
            }
            return { ...promo.toJSON(), mechanic };
        };
    }

    /**
     * Generate default promoId for promotion
     * @param product
     * @param promotion
     * @returns {string}
     */
    static getDefaultPromoId(product, promotion) {
        const { retailerId, sourceId } = product;
        const { startDate, description } = promotion;
        return `${retailerId}_${sourceId}_${description}_${startDate}`.replace(
            / /g,
            '_',
        );
    }

    static getPromoKey(promotions, product, promotion, promoId) {
        let promotionKey = `${promoId}_${promotion.retailerPromotionId}_${promotion.description}`;
        if (!promotion.promoId) {
            for (const key of Object.keys(promotions)) {
                if (
                    key.includes(
                        `${product.retailerId}_${product.sourceId}_${promotion.description}`,
                    )
                ) {
                    promotionKey = key;
                    break;
                }
            }
        }
        return promotionKey;
    }

    /**
     * Compare current and previous product promotions, and change promoId and promo period
     * @param promotion
     * @param data
     * @param product
     * @returns {Promise<*>}
     */
    static async comparePromotionWithPreviousProduct(promotion, data, product) {
        const result = { ...data };
        const {
            id: productId,
            sourceId,
            retailerId,
            coreProductId,
            dateId,
        } = product;
        const prevProduct = await db.product.findOne({
            where: {
                sourceId,
                retailerId,
                coreProductId,
                id: { [Op.not]: productId },
                dateId: { [Op.lt]: dateId },
            },
            include: ['productPromotions'],
            order: [['date', 'desc']],
        });

        if (prevProduct && prevProduct.productPromotions.length) {
            const start = moment(data.startDate);
            const end = moment(data.endDate);
            for (const prevPromo of prevProduct.productPromotions) {
                const prevStart = parseDate(
                    prevPromo.startDate || prevProduct.date || prevPromo.createdAt,
                );
                const prevEnd = parseDate(
                    prevPromo.endDate || prevProduct.date || prevPromo.createdAt,
                );
                const prevPromoId = PromotionService.getDefaultPromoId(product, {
                    ...promotion,
                    startDate: prevPromo.startDate,
                });
                const prevPromoDefaultId = PromotionService.getDefaultPromoId(
                    product,
                    prevPromo,
                );
                // check and change promoId
                if (!promotion.promoId) {
                    if (prevPromoId === prevPromoDefaultId) {
                        if (!prevPromo.promoId) {
                            prevPromo.promoId = `${prevPromoDefaultId}`;
                            await prevPromo.save();
                        }
                        result.promoId = prevPromo.promoId;
                    }
                } else if (!prevPromo.promoId) {
                    if (prevPromoId === prevPromoDefaultId) {
                        prevPromo.promoId = data.promoId;
                        await prevPromo.save();
                    }
                } else if (prevPromo.promoId === prevPromoId) {
                    prevPromo.promoId = data.promoId;
                    await prevPromo.save();
                }
                // check and change start/end dates
                if (prevPromo.promoId === result.promoId) {
                    if (moment(prevStart).isBefore(start)) result.startDate = prevStart;
                    if (moment(prevEnd).isAfter(end)) result.endDate = prevEnd;
                }
            }
        }
        return result;
    }

    /**
     * Process and save product promotions
     * @param promotions
     * @param product
     * @returns {Promise<[]>}
     */
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
    }

    static async createMechanic(data) {
        return db.promotionMechanic.create(data);
    }

    static async getAllMechanics() {
        return db.promotionMechanic.findAll();
    }

    static async getMechanic(id) {
        return db.promotionMechanic.findOne({ where: { id } });
    }

    static async createRetailerPromotion(data) {
        return db.retailerPromotion.create(data);
    }

    static async getAllRetailerPromotions() {
        return db.retailerPromotion.findAll({
            include: ['promotionMechanic', 'retailer'],
        });
    }

    static async getRetailerPromotion(id) {
        return db.retailerPromotion.findOne({
            where: { id },
            include: ['promotionMechanic', 'retailer'],
        });
    }

    static async createPromotion(data) {
        return db.promotion.create(data);
    }

    static async getAllPromotions() {
        return db.promotion.findAll({
            include: ['retailerPromotion', 'product'],
        });
    }

    static async getPromotionsByProduct(id) {
        return db.promotion.findAll({
            where: { productId: id },
            include: [
                {
                    model: db.retailerPromotion,
                    as: 'retailerPromotion',
                    include: [
                        {
                            model: db.promotionMechanic,
                            as: 'promotionMechanic',
                        },
                    ],
                },
                'product',
            ],
        });
    }

    static async getPromotion(id) {
        return db.promotion.findOne({
            where: { id },
            include: ['retailerPromotion', 'product'],
        });
    }

    static calculateMultibuyPrice(description, price) {
        if (!description || !price) return price;
        let result = price;
        const desc = textToNumber(description.replace(',', '').toLowerCase());

        const isFloat = n => Number(n) === n && n % 1 !== 0;

        const countAndPrice = desc.match(/£?(\d+(.\d{1,2})?|\d+\/\d+)p?/g);
        if (!countAndPrice || !countAndPrice.length) return price;

        const [count, discountPrice = '£1'] = countAndPrice;
        const dp = numPrice(discountPrice);
        let sum = price * count;

        // "3 for 2" match
        const forMatch = desc.match(/(\d+) for (\d+)/i);

        if (forMatch) {
            // eslint-disable-next-line no-unused-vars
            const [match, totalCount, forCount] = forMatch;
            sum = price * forCount;
            result = sum / totalCount;
        } else if (desc.includes('save')) {
            const isPercent = desc.includes('%');
            const halfPrice = desc.includes('half price');
            // eslint-disable-next-line no-nested-ternary
            const discount = isPercent ? (sum / 100) * dp : halfPrice ? sum / 2 : dp;
            result = (sum - discount) / count;
        } else if (desc.includes('price of')) {
            result = (price * dp) / count;
        } else if (desc.includes('free')) {
            const freeCount = dp > count ? 1 : +dp;
            result = sum / (+count + freeCount);
        } else if (desc.includes('half price')) {
            sum += (price / 2) * dp;
            result = sum / (+count + +dp);
        } else {
            result = Math.round((dp * 100.0) / count) / 100;
        }

        result = isFloat(result) ? result.toFixed(2) : result;

        return result.toString();
    }

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
