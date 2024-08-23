#!/bin/bash

#set -eou pipefail

# Set some paths
export DL_PATH="/dlstore"
export DL_INVENTORY_LIST="$DL_PATH/inventory.txt"
export DL_LASTENQUEUING_FILE="$DL_PATH/enqueuing.txt"
export DL_BACKUP_PATH="$DL_PATH/backups"
export NUMBER_OF_FILES_TO_KEEP=45

# Create files and folders, if necessary
[ ! -f "$DL_INVENTORY_LIST" ] && touch "$DL_INVENTORY_LIST"
[ ! -d "$DL_BACKUP_PATH" ] && mkdir -p "$DL_BACKUP_PATH"

# Check .env file existence, if not, create it
if [ ! -f /datalab/.env ]; then
    # Create the .env
    touch /datalab/.env

    # Read the secrets
    if [ -f /run/secrets/dl-co-notionbackup-notiontoken ]; then 
        echo "NOTION_TOKEN=$(cat /run/secrets/dl-co-notionbackup-notiontoken)" >> /datalab/.env
    fi

    if [ -f /run/secrets/dl-co-notionbackup-filetoken ]; then
        echo "NOTION_FILE_TOKEN=$(cat /run/secrets/dl-co-notionbackup-filetoken)" >> /datalab/.env
    fi

    if [ -f /run/secrets/dl-co-notionbackup-spaceid ]; then
        echo "NOTION_SPACE_ID=$(cat /run/secrets/dl-co-notionbackup-spaceid)" >> /datalab/.env
    fi
fi

echo "DL_PATH=\"$DL_PATH\"" >> /datalab/.env
echo "DL_INVENTORY_LIST=\"$DL_INVENTORY_LIST\"" >> /datalab/.env
echo "DL_LASTENQUEUING_FILE=\"$DL_LASTENQUEUING_FILE\"" >> /datalab/.env
echo "DL_BACKUP_PATH=\"$DL_BACKUP_PATH\"" >> /datalab/.env
echo "NUMBER_OF_FILES_TO_KEEP=\"$NUMBER_OF_FILES_TO_KEEP\"" >> /datalab/.env

# Start up cron service
new_cron_job="30 2 * * * /datalab/enqueu.sh > /dev/null 2>&1
12 * * * * /datalab/download.sh > /dev/null 2>&1
0 5 * * * /datalab/delete.sh > /dev/null 2>&1"

# Append the new cron job to the current crontab
echo -e "$new_cron_job" | crontab -

# Start the cron service
service cron start

# Show the inventory list (gets updated whenever a new file download has started)
tail -f "$DL_INVENTORY_LIST"
