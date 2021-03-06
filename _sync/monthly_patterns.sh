#!/bin/bash
SG_BASEPATH=sg/sg-c19-response/monthly-patterns/patterns_backfill
SG_BASEPATH_NEW=sg/sg-c19-response/monthly-patterns/patterns
RDP_BASEPATH=rdp/recovery-data-partnership/monthly_patterns
function max_bg_procs {
    if [[ $# -eq 0 ]] ; then
            echo "Usage: max_bg_procs NUM_PROCS.  Will wait until the number of background (&)"
            echo "           bash processes (as determined by 'jobs -pr') falls below NUM_PROCS"
            return
    fi
    local max_number=$((0 + ${1:-0}))
    while true; do
            local current_number=$(jobs -pr | wc -l)
            if [[ $current_number -lt $max_number ]]; then
                    break
            fi
            sleep 1
    done
}

for INFO in $(mc ls --recursive --json $SG_BASEPATH)
do 
    max_bg_procs 5
    (
        KEY=$(echo $INFO | jq -r '.key')
        NEW_KEY=$(python3 -c "print('$KEY'.replace('/', '-'))")
        FILENAME=$(basename $KEY)
        DATE=$(echo $FILENAME | cut -c1-10)
        PARTITION="dt=$DATE"
        SUBPATH=$(echo $KEY | cut -c-13)
        if ! [ "$FILENAME" = "_SUCCESS" ]; then

            # Check existence
            STATUS=$(mc stat --json $RDP_BASEPATH/$PARTITION/$NEW_KEY | jq -r '.status')
            
            case $STATUS in
            success)
                echo "$KEY is already synced to $NEW_KEY, skipping ..."
            ;;
            error)
                # Download data and unzip, remove README.txt and the original .zip file
                mc cp $SG_BASEPATH/$KEY $RDP_BASEPATH/$NEW_KEY
            ;;
            esac
        else echo "ignore _SUCCESS"
        fi
    ) &
done
wait
echo "Syncing Backfill Complete !"

for INFO in $(mc ls --recursive --json $SG_BASEPATH_NEW)
do 
    max_bg_procs 5
    (
        KEY=$(echo $INFO | jq -r '.key')
        NEW_KEY=$(python3 -c "print('$KEY'.replace('/', '-'))")
        FILENAME=$(basename $KEY)
        SUBPATH=$(echo $KEY | cut -c-13)
        if ! [ "$FILENAME" = "_SUCCESS" ]; then

            # Check existence
            STATUS=$(mc stat --json $RDP_BASEPATH/$NEW_KEY | jq -r '.status')
            
            case $STATUS in
            success)
                echo "$KEY is already synced to $NEW_KEY, skipping ..."
            ;;
            error)
                # Download data and unzip, remove README.txt and the original .zip file
                mc cp $SG_BASEPATH_NEW/$KEY $RDP_BASEPATH/$NEW_KEY
            ;;
            esac
        else echo "ignore _SUCCESS"
        fi
    ) &
done

wait
echo "Syncing New Complete !"