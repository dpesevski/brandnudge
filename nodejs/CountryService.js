export default class CountryService {
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

