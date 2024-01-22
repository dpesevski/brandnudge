//RetailersService

export default class RetailerService {
  /**
   * Get retailer by id
   * @param id
   * @returns {Promise<Model | null> | Promise<Model>}
   */
  static getRetailer(id) {
    return db.retailer.findOne({
      where: { id },
      include: ['country'],
    });
  }

  /**
   * Get retailer by name and country ISO codes
   * @param {string} name - retailer name
   * @param {Object} isoCodes - iso & iso3 country codes, default GB/GBR
   * @returns {Promise<Model | null> | Promise<Model>}
   */
  static async getRetailerByName(name, isoCodes = CountryService.defaultISO) {
    const countryId = await CountryService.getCountryByISO(isoCodes);
    if (!countryId) throw Boom.badData('Retailer country not found');
    const retailer = await db.retailer.findOne({
      where: { name },
    });
    if (retailer) return retailer;
    return db.retailer.create({ name, countryId });
  }

  /**
   * get all retailers
   * @returns {Promise<Model[]>}
   */
  static getRetailers() {
    return db.retailer.findAll({
      include: ['country'],
    });
  }

  /**
   * create retailer query
   * @param data
   * @returns {data}
   */
  static async createRetailer(data) {
    if (data.hasOwnProperty('logo')) {
      const res = await AWSUtil.uploadImage({
        key: `retailerLogo_${data.name}`,
        bucket: 'avatars',
        base64: data.logo,
        isSvg: true,
      });
  
      const pngBuffer = await ImageUtil.convertSvgToPng(res, {format: 'png'});
      await AWSUtil.uploadImage({
        key: `retailerLogo_${data.name}_png`,
        bucket: 'avatars',
        base64: pngBuffer.toString('base64'),
        isSvg: false,
      });

      data.logo = res;
    }
    return db.retailer.create(data);
  }

  /**
   * Drop data for current day
   * @param id
   * @param name
   * @param today
   * @returns {Promise<boolean>}
   */
  static async deleteTodayRetailerData(
    { id, name },
    today = new Date().toISOString().split('T')[0],
  ) {
    const dates = await db.dates.findOrCreate({ where: { date: today } });
    const dateId = dates[0].id;

    // Remove banners
    const banners = await db.sequelize.query(
      'SELECT * FROM "banners" WHERE date_trunc(\'day\', "banners"."createdAt") = :today AND "retailerId" = :id',
      {
        replacements: { today, id },
        type: QueryTypes.SELECT,
      },
    );
    const bannerIds = banners.map(banner => banner.id);
    await db.bannersProducts.destroy({
      where: { bannerId: { [Op.in]: bannerIds } },
    });
    await db.banners.destroy({ where: { id: { [Op.in]: bannerIds } } });

    // Remove taxonomy
    const taxonomyIds = [];
    // Level 1
    const taxonomies1 = await db.sequelize.query(
      'SELECT * FROM "taxonomies" WHERE date_trunc(\'day\', "taxonomies"."date") = :today AND "retailer" = :name AND "level" = 1',
      {
        replacements: { today, name },
        type: QueryTypes.SELECT,
      },
    );
    const taxonomy1Ids = taxonomies1.map(taxonomy => taxonomy.id);
    taxonomyIds.unshift(taxonomy1Ids);
    // Level 2
    const taxonomies2 = await db.sequelize.query(
      'SELECT * FROM "taxonomies" WHERE date_trunc(\'day\', "taxonomies"."date") = :today AND "retailer" = :name AND "level" = 2',
      {
        replacements: { today, name, taxonomyId: taxonomy1Ids },
        type: QueryTypes.SELECT,
      },
    );
    const taxonomy2Ids = taxonomies2.map(taxonomy => taxonomy.id);
    taxonomyIds.unshift(taxonomy2Ids);
    // Level 3
    const taxonomies3 = await db.sequelize.query(
      'SELECT * FROM "taxonomies" WHERE date_trunc(\'day\', "taxonomies"."date") = :today AND "retailer" = :name AND "level" = 3',
      {
        replacements: { today, name, taxonomyId: taxonomy2Ids },
        type: QueryTypes.SELECT,
      },
    );
    const taxonomy3Ids = taxonomies3.map(taxonomy => taxonomy.id);
    taxonomyIds.unshift(taxonomy3Ids);
    for (const ids of taxonomyIds) {
      try {
        await db.taxonomyProduct.destroy({
          where: { taxonomyId: { [Op.in]: ids } },
        });
        await db.taxonomy.destroy({ where: { id: { [Op.in]: ids } } });
      } catch (e) {
        console.error(e);
      }
    }

    // Remove products
    const products = await db.sequelize.query(
      'SELECT * FROM "products" WHERE "dateId" = :dateId AND "retailerId" = :id',
      {
        replacements: { dateId, id },
        type: QueryTypes.SELECT,
      },
    );
    const productIds = products.map(product => product.id);
    await db.productsData.destroy({
      where: { productId: { [Op.in]: productIds } },
    });
    await db.productStatus.destroy({
      where: { productId: { [Op.in]: productIds } },
    });
    await db.promotion.destroy({
      where: { productId: { [Op.in]: productIds } },
    });
    await db.aggregatedProduct.destroy({
      where: { productId: { [Op.in]: productIds } },
    });
    await db.product.destroy({ where: { id: { [Op.in]: productIds } } });
    return true;
  }
}

