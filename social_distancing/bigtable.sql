SET myvars.date TO :'DATE';

DO $$
DECLARE
    create_table boolean;
    computed boolean;
    query text;
BEGIN
    SELECT 'sg_bigtable' NOT IN (SELECT table_schema FROM information_schema.tables) INTO create_table;

    SELECT FORMAT(
        $query$
        SELECT
            '%1$s' as date,
            to_char('%1$s'::date, 'IYYY-IW') as year_week,
            EXTRACT(DOW FROM '%1$s'::date) as day_of_week,
            LEFT(origin_census_block_group, 5) as origin_county,
            SUM((origin_census_block_group = desti.key)::int*desti.value::int) as completely_home_device_count,
            SUM(part_time_work_behavior_devices) as part_time_work_behavior_devices,
            SUM(full_time_work_behavior_devices) as full_time_work_behavior_devices,
            SUM(CASE WHEN LEFT(desti.key, 5)='36005' THEN desti.value::int END) as "36005",
            SUM(CASE WHEN LEFT(desti.key, 5)='36047' THEN desti.value::int END) as "36047",
            SUM(CASE WHEN LEFT(desti.key, 5)='36061' THEN desti.value::int END) as "36061",
            SUM(CASE WHEN LEFT(desti.key, 5)='36081' THEN desti.value::int END) as "36081",
            SUM(CASE WHEN LEFT(desti.key, 5)='36085' THEN desti.value::int END) as "36085",
            -- CT
            SUM(CASE WHEN LEFT(desti.key, 5)='09001' THEN desti.value::int END) as "09001",
            SUM(CASE WHEN LEFT(desti.key, 5)='09005' THEN desti.value::int END) as "09005",
            SUM(CASE WHEN LEFT(desti.key, 5)='09009' THEN desti.value::int END) as "09009",
            -- North NJ
            SUM(CASE WHEN LEFT(desti.key, 5)='34003' THEN desti.value::int END) as "34003",
            SUM(CASE WHEN LEFT(desti.key, 5)='34013' THEN desti.value::int END) as "34013",
            SUM(CASE WHEN LEFT(desti.key, 5)='34017' THEN desti.value::int END) as "34017",
            SUM(CASE WHEN LEFT(desti.key, 5)='34019' THEN desti.value::int END) as "34019",
            SUM(CASE WHEN LEFT(desti.key, 5)='34021' THEN desti.value::int END) as "34021",
            SUM(CASE WHEN LEFT(desti.key, 5)='34023' THEN desti.value::int END) as "34023",
            SUM(CASE WHEN LEFT(desti.key, 5)='34025' THEN desti.value::int END) as "34025",
            SUM(CASE WHEN LEFT(desti.key, 5)='34027' THEN desti.value::int END) as "34027",
            SUM(CASE WHEN LEFT(desti.key, 5)='34029' THEN desti.value::int END) as "34029",
            SUM(CASE WHEN LEFT(desti.key, 5)='34031' THEN desti.value::int END) as "34031",
            SUM(CASE WHEN LEFT(desti.key, 5)='34035' THEN desti.value::int END) as "34035",
            SUM(CASE WHEN LEFT(desti.key, 5)='34037' THEN desti.value::int END) as "34037",
            SUM(CASE WHEN LEFT(desti.key, 5)='34039' THEN desti.value::int END) as "34039",
            SUM(CASE WHEN LEFT(desti.key, 5)='34041' THEN desti.value::int END) as "34041",
            -- HV
            SUM(CASE WHEN LEFT(desti.key, 5)='36027' THEN desti.value::int END) as "36027",
            SUM(CASE WHEN LEFT(desti.key, 5)='36071' THEN desti.value::int END) as "36071",
            SUM(CASE WHEN LEFT(desti.key, 5)='36079' THEN desti.value::int END) as "36079",
            SUM(CASE WHEN LEFT(desti.key, 5)='36087' THEN desti.value::int END) as "36087",
            SUM(CASE WHEN LEFT(desti.key, 5)='36105' THEN desti.value::int END) as "36105",
            SUM(CASE WHEN LEFT(desti.key, 5)='36111' THEN desti.value::int END) as "36111",
            SUM(CASE WHEN LEFT(desti.key, 5)='36119' THEN desti.value::int END) as "36119",
            -- LI
            SUM(CASE WHEN LEFT(desti.key, 5)='36059' THEN desti.value::int END) as "36059",
            SUM(CASE WHEN LEFT(desti.key, 5)='36103' THEN desti.value::int END) as "36103",
            -- PA
            SUM(CASE WHEN LEFT(desti.key, 5)='42025' THEN desti.value::int END) as "42025",
            SUM(CASE WHEN LEFT(desti.key, 5)='42077' THEN desti.value::int END) as "42077",
            SUM(CASE WHEN LEFT(desti.key, 5)='42089' THEN desti.value::int END) as "42089",
            SUM(CASE WHEN LEFT(desti.key, 5)='42095' THEN desti.value::int END) as "42095",
            SUM(CASE WHEN LEFT(desti.key, 5)='42025' THEN desti.value::int END) as "42103",
            -- Out of region
            SUM(CASE WHEN LEFT(desti.key, 5) not in (
                '36059','36103','09009','09005','09001','36027','36071','36105',
                '36111','34019','34021','34025','34029','34037','34041','34003',
                '34013','34017','34023','34027','34031','34035','34039','42025',
                '42077','42095','42089','42103','36005','36061','36081','36047',
                '36085','36079','36087','36119') THEN desti.value::int END) as "O31CR",
            sum((bucketed_away_from_home_time ->> '21-45')::int) as "away_21-45",
            sum((bucketed_away_from_home_time ->> '481-540')::int) as "away_481-540",
            sum((bucketed_away_from_home_time ->> '721-840')::int) as "away_721-840",
            sum((bucketed_away_from_home_time ->> '301-360')::int) as "away_301-360",
            sum((bucketed_away_from_home_time ->> '<20')::int) as "away_<20",
            sum((bucketed_away_from_home_time ->> '61-120')::int) as "away_61-120",
            sum((bucketed_away_from_home_time ->> '241-300')::int) as "away_241-300",
            sum((bucketed_away_from_home_time ->> '121-180')::int) as "away_121-180",
            sum((bucketed_away_from_home_time ->> '1321-1440')::int) as "away_1321-1440",
            sum((bucketed_away_from_home_time ->> '841-960')::int) as "away_841-960",
            sum((bucketed_away_from_home_time ->> '1081-1200')::int) as "away_1081-1200",
            sum((bucketed_away_from_home_time ->> '961-1080')::int) as "away_961-1080",
            sum((bucketed_away_from_home_time ->> '181-240')::int) as "away_181-240",
            sum((bucketed_away_from_home_time ->> '361-420')::int) as "away_361-420"
        FROM social_distancing."%1$s", json_each_text(destination_cbgs) as desti
        WHERE LEFT(origin_census_block_group, 5) in ('36005', '36061', '36081', '36047', '36085')
        GROUP BY LEFT(origin_census_block_group, 5)
        $query$, current_setting('myvars.date')
    ) INTO query;

    IF not create_table 
        THEN EXECUTE FORMAT($inner_create$ CREATE TABLE sg_bigtable AS (%s) $inner_create$, query);
    END IF;

    SELECT current_setting('myvars.date')::text NOT IN (SELECT DISTINCT date FROM sg_bigtable) INTO computed;

    IF create_table AND computed
        THEN EXECUTE FORMAT($inner_insert$ INSERT INTO sg_bigtable %s $inner_insert$, query);
    ELSE RAISE NOTICE '% is already loaded !', current_setting('myvars.date');
    
    END IF;
END $$