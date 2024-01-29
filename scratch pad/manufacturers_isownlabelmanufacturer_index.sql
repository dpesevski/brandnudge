CREATE INDEX IF NOT EXISTS manufacturers_isownlabelmanufacturer_index
    ON public.manufacturers ("isOwnLabelManufacturer") INCLUDE (id)
    WHERE "isOwnLabelManufacturer";

