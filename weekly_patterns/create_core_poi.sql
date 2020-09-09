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
    category_tags text,
    opened_on text,
    closed_on text,
    tracking_opened_since text,
    tracking_closed_since text
);

\COPY tmp FROM pstdin WITH NULL AS '' DELIMITER '|' CSV HEADER;

DROP TABLE IF EXISTS core_poi.:"DATE";

SELECT * 
INTO core_poi.:"DATE" 
FROM tmp
WHERE region ~* 'NY|NJ|PA|CT|RI|MA|VT|NH';

COMMIT;