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
    SELECT to_char(current_setting('myvars.date')::date, 'IYYY-IW')||_weekend::text IN (SELECT DISTINCT year_week||weekend::text FROM sg_trips_by_state_wknd) INTO week_exists;
    SELECT current_setting('myvars.date')::text NOT IN (SELECT DISTINCT date FROM state_days_included) INTO new_date;
    SELECT to_char(current_setting('myvars.date')::date, 'IYYY-IW') INTO _year_week;
    
    IF new_date
    THEN
        SELECT FORMAT(
        $inner$ 
        INSERT INTO state_days_included
        VALUES ('%s', '%s')
        $inner$, _year_week, current_setting('myvars.date')::text)
        INTO query;
        EXECUTE query;
        
        IF NOT week_exists
        THEN
            RAISE NOTICE 'Loading % to a new week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
            SELECT FORMAT(
                $inner$
                WITH pairs AS
                    (
                    SELECT 
                    '%s' as year_week,
                    '%s' as weekend,
                    origin::text,
                    destination::text,
                    sum(counts) as trips
                    FROM (
                    SELECT
                        CASE
                            WHEN  LEFT(origin_census_block_group, 5) 
                                    IN ('36005', '36061', '36081', '36047', '36085')         
                                THEN 'NYC'
                            ELSE LEFT(origin_census_block_group, 2) 
                        END as origin,
                        CASE
                            WHEN  LEFT(desti.key, 5) 
                                    IN ('36005', '36061', '36081', '36047', '36085')         
                                THEN 'NYC'
                            ELSE LEFT(desti.key, 2)
                        END as destination,
                        desti.value::int as counts
                    FROM social_distancing."%s",
                        json_each_text(destination_cbgs) as desti
                    WHERE LEFT(origin_census_block_group, 5) in (
                        '36005', '36061', '36081', '36047', '36085' 
                    )
                    OR LEFT(desti.key, 5) in (
                        '36005', '36061', '36081', '36047', '36085' 
                    )) a
                    GROUP BY origin, destination)

                    INSERT INTO sg_trips_by_state_wknd
                    SELECT
                    a.year_week,
                    a.weekend,
                    a.origin as state,
                    a.trips as to_nyc,
                    b.trips as from_nyc,
                    a.trips - b.trips as net_nyc
                    FROM pairs a
                    JOIN pairs b
                    ON a.origin=b.destination
                    WHERE a.origin <> 'NYC';

            $inner$, _year_week, _weekend, current_setting('myvars.date'))
            INTO query;
            EXECUTE query;
        ELSE
            RAISE NOTICE 'Adding % to existing week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
            SELECT FORMAT(
                $inner$
                WITH pairs AS
                    (
                    SELECT 
                    '%s' as year_week,
                    '%s' as weekend,
                    origin::text,
                    destination::text,
                    sum(counts) as trips
                    FROM (
                    SELECT
                        CASE
                            WHEN  LEFT(origin_census_block_group, 5) 
                                    IN ('36005', '36061', '36081', '36047', '36085')         
                                THEN 'NYC'
                            ELSE LEFT(origin_census_block_group, 2) 
                        END as origin,
                        CASE
                            WHEN  LEFT(desti.key, 5) 
                                    IN ('36005', '36061', '36081', '36047', '36085')         
                                THEN 'NYC'
                            ELSE LEFT(desti.key, 2)
                        END as destination,
                        desti.value::int as counts
                    FROM social_distancing."%s",
                        json_each_text(destination_cbgs) as desti
                    WHERE LEFT(origin_census_block_group, 5) in (
                        '36005', '36061', '36081', '36047', '36085' 
                    )
                    OR LEFT(desti.key, 5) in (
                        '36005', '36061', '36081', '36047', '36085' 
                    )) a
                    GROUP BY origin, destination),
                
                daily AS (
                    SELECT
                    a.year_week,
                    a.weekend,
                    a.origin as state,
                    a.trips as to_nyc,
                    b.trips as from_nyc,
                    a.trips - b.trips as net_nyc
                    FROM pairs a
                    JOIN pairs b
                    ON a.origin=b.destination
                    WHERE a.origin <> 'NYC'
                )

                UPDATE sg_trips_by_state_wknd a
                SET to_nyc = a.to_nyc + b.to_nyc,
                    from_nyc = a.from_nyc + b.from_nyc,
                    net_nyc = a.net_nyc + b.net_nyc
                FROM daily b
                WHERE a.year_week = b.year_week 
                AND a.weekend::boolean = b.weekend::boolean
                AND a.state = b.state;
            $inner$, _year_week, _weekend, current_setting('myvars.date'))
            INTO query;
            EXECUTE query;
        END IF;
    ELSE
        RAISE NOTICE '% is already loaded to records for week % (weekend: %)', current_setting('myvars.date')::text, _year_week, _weekend::text;
    END IF;
END $$