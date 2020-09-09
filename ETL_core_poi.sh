#!/bin/bash
source config.sh

BASEPATH=sg/sg-c19-response/core
psql $SAFEGRAPH -c "CREATE SCHEMA IF NOT EXISTS core_poi;"

for INFO in $(mc ls --recursive --json $BASEPATH)
do
    max_bg_procs 15
    (
        # Extract file path from json response
        KEY=$(echo $INFO | jq -r '.key') 

        # Extract file name from file path
        FULL_FILENAME=$(basename $KEY)
        FILENAME="${FULL_FILENAME%.*}"

        # Take last 10 characters of file name as date
        DATE=$(echo $FILENAME | tail -c 11)

        # Check if the data for this date is already loaded
        LOADED=$(psql -q -At $SAFEGRAPH -c "
            SELECT '$DATE' IN (
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'core_poi'
            )")
        
        case $LOADED in
            f) # If not loaded, then load into database
                echo "Loading $FULL_FILENAME right now ..."

                mkdir -p tmp && (
                    cd tmp
                    mc cp $BASEPATH/$KEY $FULL_FILENAME
                    unzip $FULL_FILENAME
                    # Loop through unzipped directory and combine parts
                    for PART in $(ls *.gz)
                        do 
                            gunzip $PART
                            CSVNAME=${PART//.gz/}
                            if ! [ -f raw.csv ]; then 
                                mv $CSVNAME raw.csv
                            else
                                tail -n +2 $CSVNAME >> raw.csv
                                rm $CSVNAME
                            fi
                        done;

                    echo $(head -n1 raw.csv)
                )

                {
                    # Try old schema first
                    python3 weekly_patterns/core_poi.py | 
                        psql $SAFEGRAPH \
                            -v ON_ERROR_STOP=1\
                            -v DATE=$DATE \
                            -f weekly_patterns/create_core_poi_old.sql
                } || {
                    # If failed, then try new schema
                    python3 weekly_patterns/core_poi.py | 
                        psql $SAFEGRAPH \
                            -v ON_ERROR_STOP=1\
                            -v DATE=$DATE \
                            -f weekly_patterns/create_core_poi.sql
                }

                rm -rf tmp
            ;;
            *) # Otherwise, print the following message:
                echo "$FULL_FILENAME is already loaded!"
            ;;
        esac
    ) &
done;

wait
echo "import complete!"