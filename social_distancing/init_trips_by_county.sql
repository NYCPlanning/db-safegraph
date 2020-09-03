CREATE TABLE IF NOT EXISTS sg_trips_by_county_wknd (
    year_week text,
    weekend boolean,
    origin text,
    destination text,
    trips int
);

CREATE TABLE IF NOT EXISTS county_days_included_wknd (
    year_week text,
    date text
);