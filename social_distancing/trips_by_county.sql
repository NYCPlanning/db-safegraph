SET myvars.date TO :'DATE';

DO $$
DECLARE
    week_exists boolean;
    new_date boolean;
    _weekend boolean;
    _year_week text;
    query text;

BEGIN
    SELECT EXTRACT(DOW FROM current_setting('myvars.date')::date) IN (6,0) INTO _weekend;
    SELECT to_char(current_setting('myvars.date')::date, 'IYYY-IW')||_weekend::text IN (SELECT DISTINCT year_week||weekend::text FROM sg_trips_by_county_wknd) INTO week_exists;
    SELECT current_setting('myvars.date')::text NOT IN (SELECT DISTINCT date FROM county_days_included) INTO new_date;
    SELECT to_char(current_setting('myvars.date')::date, 'IYYY-IW') INTO _year_week;
    
    IF new_date
    THEN
        SELECT FORMAT(
        $inner$ 
        INSERT INTO county_days_included
        VALUES ('%s', '%s')
        $inner$, _year_week, current_setting('myvars.date')::text)
        INTO query;
        EXECUTE query;

        IF NOT week_exists
        THEN
            RAISE NOTICE 'Loading % to a new week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
            SELECT FORMAT(
                $inner$
                INSERT INTO sg_trips_by_county_wknd
                SELECT 
                '%s' as year_week,
                '%s' as weekend,
                origin::text,
                destination::text,
                sum(counts) as trips
                FROM (
                SELECT         
                    LEFT(origin_census_block_group, 5) as origin,
                    LEFT(desti.key, 5) as destination,
                    desti.value::int as counts
                FROM social_distancing."%s",
                    json_each_text(destination_cbgs) as desti
                WHERE LEFT(origin_census_block_group, 2) in (
                    '36', '34', '09', '42', '25', '44', '50', '33'
                )
                AND LEFT(desti.key, 2) in (
                    '36', '34', '09', '42', '25', '44', '50', '33'
                )) a
                GROUP BY origin, destination;
            $inner$, _year_week, _weekend, current_setting('myvars.date'))
            INTO query;
            EXECUTE query;
        ELSE
            RAISE NOTICE 'Adding % to existing week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
            SELECT FORMAT(
                $inner$
                WITH origin_dest AS 
                (
                    SELECT         
                        LEFT(origin_census_block_group, 5) as origin,
                        LEFT(desti.key, 5) as destination,
                        desti.value::int as counts
                    FROM social_distancing."%s",
                        json_each_text(destination_cbgs) as desti
                    WHERE LEFT(origin_census_block_group, 2) in (
                        '36', '34', '09', '42', '25', '44', '50', '33' 
                    )
                    AND LEFT(desti.key, 2) in (
                        '36', '34', '09', '42', '25', '44', '50', '33' )
                ) 

                UPDATE sg_trips_by_county_wknd a
                SET trips = a.trips + b.trips
                FROM
                    (SELECT 
                    '%s' as year_week,
                    '%s' as weekend,
                    origin::text,
                    destination::text,
                    sum(counts) as trips
                    FROM origin_dest
                    GROUP BY origin, destination) b
                WHERE a.year_week = b.year_week 
                AND a.weekend = b.weekend::boolean
                AND a.origin = b.origin 
                AND a.destination = b.destination;
            $inner$, current_setting('myvars.date'), _year_week, _weekend)
            INTO query;
            EXECUTE query;
        END IF;
    ELSE
        RAISE NOTICE '% is already loaded to records for week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
    END IF;
END $$