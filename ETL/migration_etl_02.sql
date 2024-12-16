CREATE TABLE IF NOT EXISTS staging.debug_tmp_product_pp_removed AS TABLE staging.debug_tmp_product_pp
    WITH NO DATA;


ALTER TABLE staging.load
    ADD load_status text;

UPDATE staging.load
SET load_status='completed';