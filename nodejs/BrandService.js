export default class BrandService {
  static async getBrandByCheckList(name) {
    const listBrands = await db.brands.findAll({
      where: { checkList: { [Op.ne]: null } },
    });


    const brand = listBrands.find(list =>
      JSON.parse(list.checkList).includes(name),
    );
    return brand || null;
  }

  /**
   * Update brand by condition
   * @param data
   * @returns {Promise<<Model[]>>}
   */
  static async changeBrand(data) {
    const products = await db.coreProduct.findAll({
      where: { brandId: data.oldId },
    });
    for (const product in products) {
      await products[product].update({ brandId: data.newId });
    }
    return db.coreProduct.findAll({ where: { brandId: data.newId } });
  }
}
