from _helper import aws

"""
DESCRIPTION:
   This script parses point-of-interest visit counts from the safegraph monthly patterns
   data to create a table containing the number of visits to POIs in a given NAICS sector
   per day. The data is aggregated to the zipcode level.

INPUTS:
    safegraph.monthly_patterns (
        safegraph_place_id text, 
        poi_cbg text,
        postal_code text,
        date_range_start date,
        date_range_end date,
        visits_by_day json
    )

    safegraph.core_poi (
        safegraph_place_id text, 
        naics_code varchar(6), 
        top_category text, 
        sub_category text,
        region varchar(2)
    )
    
OUTPUTS:
    outputs/daily_borough_poivisits_by_sector (
        borough text, 
        borocode int,
        zipcode varchar(5),
        fips_county varchar(5),
        naics_code varchar(6),
        top_category text,
        sub_category text
    )
"""

query = """
WITH daily_visits AS(
SELECT safegraph_place_id, poi_cbg, postal_code, date_add('day', row_number() over(), date_start) AS date_current, CAST(visits AS SMALLINT) as visits
FROM (
  SELECT
     safegraph_place_id,
     poi_cbg,
     postal_code,
     CAST(SUBSTR(date_range_start, 1, 10) AS DATE) as date_start,
     CAST(SUBSTR(date_range_end, 1, 10) AS DATE) as date_end,
     cast(json_parse(visits_by_day) as array<varchar>) as a
  FROM safegraph.monthly_patterns
  WHERE SUBSTR(poi_cbg,1,5) IN ('36085','36081','36061','36047','36005')
) b
CROSS JOIN UNNEST(a) as t(visits)
)
SELECT
   a.date_current as date,
   (CASE WHEN SUBSTR(a.poi_cbg,1,5) = '36005' THEN 'BX'
        WHEN SUBSTR(a.poi_cbg,1,5) = '36047' THEN 'BK'
        WHEN SUBSTR(a.poi_cbg,1,5) = '36061' THEN 'MN'
        WHEN SUBSTR(a.poi_cbg,1,5) = '36081' THEN 'QN'
        WHEN SUBSTR(a.poi_cbg,1,5) = '36085' THEN 'SI'
   END) as borough,
   (CASE WHEN SUBSTR(a.poi_cbg,1,5) = '36005' THEN 2
        WHEN SUBSTR(a.poi_cbg,1,5) = '36047' THEN 3
        WHEN SUBSTR(a.poi_cbg,1,5) = '36061' THEN 1
        WHEN SUBSTR(a.poi_cbg,1,5) = '36081' THEN 4
        WHEN SUBSTR(a.poi_cbg,1,5) = '36085' THEN 5
   END) as borocode,
   postal_code as zipcode,
   SUBSTR(a.poi_cbg,1,5) as fips_county,
   SUBSTR(b.naics_code,1,2) as sector,
   SUM(a.visits) as total_visits
FROM daily_visits a
LEFT JOIN (
      SELECT distinct safegraph_place_id, naics_code, top_category, sub_category
      FROM "safegraph"."core_poi"
      WHERE region = 'NY'
    ) b  
    ON a.safegraph_place_id=b.safegraph_place_id
GROUP BY a.date_current,
         SUBSTR(a.poi_cbg,1,5),
         a.postal_code,
         SUBSTR(b.naics_code,1,2)
"""

aws.execute_query(
    query=query, 
    database="safegraph", 
    output="output/poi/daily_zip_poivisits_by_sector.csv"
)