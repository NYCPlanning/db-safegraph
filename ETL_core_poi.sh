#!/bin/bash
source config.sh

# BASEPATH=sg/sg-c19-response/core
# for INFO in $(mc ls --recursive --json $BASEPATH)
# do
#     max_bg_procs 15
#     (
#         # Extract file path from json response
#         KEY=$(echo $INFO | jq -r '.key') 

#         # Extract file name from file path
#         FULL_FILENAME=$(basename $KEY)
#         FILENAME="${FULL_FILENAME%.*}"


#         # Take last 10 characters of file name as date
#         DATE=$(echo $FILENAME | tail -c 11)
#         DATEIDX=${DATE//-/}
#         # Check if the data for this date is already loaded
#         LOADED=$(psql -q -At $SAFEGRAPH -c "
#             SELECT '$DATE' IN (
#                 SELECT table_name 
#                 FROM information_schema.tables 
#                 WHERE table_schema = 'core_poi'
#             )")
        
#         case $LOADED in
#             f) # If not loaded, then load into database
#                 echo "Loading $FULL_FILENAME right now ..."
#                 echo $DATE

#                 mkdir -p tmp && (
#                     cd tmp
#                     mc cp $BASEPATH/$KEY $FULL_FILENAME
#                     unzip $FULL_FILENAME
#                     for part in $(ls *.gz)
#                         do 
#                             echo "$part"
#                             # do something here ...
#                         done;
#                 )
#                 rm -rf tmp  

#                 {
#                     # Try new schema first
#                     gzip -dc $FULL_FILENAME | 
#                         psql $SAFEGRAPH \
#                             -v ON_ERROR_STOP=1\
#                             -v DATE=$DATE \
#                             -f weekly_patterns/create_core_poi.sql
#                 } || {
#                     # If failed, then try old schema
#                     gzip -dc $FULL_FILENAME | 
#                         psql $SAFEGRAPH \
#                             -v ON_ERROR_STOP=1\
#                             -v DATE=$DATE \
#                             -f weekly_patterns/create_core_poi_old.sql
#                 }
#                 rm $FULL_FILENAME
#             ;;
#             *) # Otherwise, print the following message:
#                 echo "$FULL_FILENAME is already loaded!"
#             ;;
#         esac
#     ) &
# done;

# wait
# echo "import complete!"






BASEPATH=sg/sg-c19-response/core
SUBPATH=$(
    for INFO in $(mc ls --recursive --json $BASEPATH)
    do 
        KEY=$(echo $INFO | jq -r '.key')
        # FILENAME=$(basename $KEY)
        SUBPATH=$(echo $KEY | cut -c-13)
        echo "$SUBPATH"
    done | sort -u
)
for SUB in $(echo $SUBPATH) 
do
    _DATE=$(echo $SUB | cut -c-10)
    DATE=$(python3 -c "print('$_DATE'.replace('/', '-'))")
    echo "$DATE"
    LOADED=$(psql -q -At $SAFEGRAPH -c "
            SELECT '$DATE' IN (
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'core_poi'
            )")
    case $LOADED in
        f)
            for INFO in $(mc ls --recursive --json $BASEPATH/$SUB)
            do 
                (
                    KEY=$(echo $INFO | jq -r '.key')
                    FILENAME=$(basename $KEY)
                    if ! ["$FILENAME" = "_SUCCESS"]; then
                        CSVNAME=${FILENAME//.gz/}
                        mkdir -p tmp && (
                            cd tmp
                            mc cp $BASEPATH/$SUB/$KEY $FILENAME
                            gunzip $FILENAME
                            if ! [ -f raw.csv ]; then 
                                mv $CSVNAME raw.csv
                            else
                                tail -n +2 $CSVNAME >> raw.csv
                                rm $CSVNAME
                            fi
                        )
                    else echo "ignore ..."
                    fi
                ) &
            done
            wait
            {
                cat tmp/raw.csv | 
                psql $SAFEGRAPH \
                    -v ON_ERROR_STOP=1\
                    -v DATE=$DATE \
                    -f weekly_patterns/create_core_poi.sql
            } || {
                cat tmp/raw.csv |
                psql $SAFEGRAPH \
                    -v ON_ERROR_STOP=1\
                    -v DATE=$DATE \
                    -f weekly_patterns/create_core_poi_old.sql
            }
            rm -rf tmp
        ;;
        *) 
        echo "$DATE is already loaded!"
        ;;
    esac
done;