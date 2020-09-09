SET client_encoding = ‘UTF8’;

BEGIN;

CREATE TEMP TABLE tmp (
    safegraph_place_id text,
    parent_safegraph_place_id text,
    location_name text,
    safegraph_brand_ids text,
    brands text,
    top_category text,
    sub_category text,
    naics_code int,
    latitude numeric,
    longitude numeric,
    street_address text,
    city text,
    region varchar(2),
    postal_code varchar(5),
    iso_country_code varchar(2),
    phone_number text,
    open_hours json,
    category_tags text
);

\COPY tmp FROM pstdin WITH NULL AS '' DELIMITER ',' CSV HEADER;

INSERT INTO core_poi.:"DATE" 
SELECT * FROM tmp;

COMMIT;