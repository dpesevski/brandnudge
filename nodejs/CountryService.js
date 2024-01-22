export default class CountryService {
    static defaultISO = { iso: 'GB', iso3: 'GBR' };
  
    static async getCountryByName(name) {
      return db.country.scope('withoutDates').findOne({ name });
    }
  
    static async getCountryByISO({ iso, iso3 }) {
      const where = {};
      if (iso) where.iso = iso;
      else if (iso3) where.iso3 = iso3;
      return db.country.scope('withoutDates').findOne({ where });
    }
  
    /**
     * Get country by id
     * @param id
     * @returns {Promise<Model | null> | Promise<Model>}
     */
    static getCountry(id) {
        return db.country.findOne({
            where: { id },
            include: [
                {
                    model: db.currency,
                    as: 'currency',
                },
            ],
        });
    }

    /**
     * get all countries
     * @returns {Promise<Model[]>}
     */
    static getCountries() {
        return db.country.findAll({
            include: [
                {
                    model: db.currency,
                    as: 'currency',
                },
            ],
        });
    }

    /**
     * create country query
     * @param data
     * @returns {data}
     */
    static createCountry(data) {
        return db.country.create(data);
    }
}

