#!/bin/bash
source config.sh

DATES=$(psql -q -At $SAFEGRAPH -c "\copy (
     SELECT table_name FROM information_schema.tables 
    WHERE table_schema = 'social_distancing'
) to STDOUT CSV")

for DATE in $(echo $DATES)
do 
    max_bg_procs 10
    (
        echo "$DATE"
         psql $SAFEGRAPH -v DATE=$DATE -f social_distancing/bigtable.sql
    ) &
done;