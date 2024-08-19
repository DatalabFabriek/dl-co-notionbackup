#!/bin/bash

source /datalab/functions.sh

# If the .env file exists, source that. Handy for development, you can just put your Notion tokes in there.
# See README.md for more details on how to get the appropriate tokens.
[ -f /datalab/.env ] && source /datalab/.env

# Read the secrets
if [ -f /run/secrets/dl-co-notionbackup-notiontoken ]; then 
    export NOTION_TOKEN=$(cat /run/secrets/dl-co-notionbackup-notiontoken)
fi

if [ -f /run/secrets/dl-co-notionbackup-filetoken ]; then
    export NOTION_FILE_TOKEN=$(cat /run/secrets/dl-co-notionbackup-filetoken)
fi

if [ -f /run/secrets/dl-co-notionbackup-spaceid ]; then
    export NOTION_SPACE_ID=$(cat /run/secrets/dl-co-notionbackup-spaceid)
fi

# Check for required environment variables
if [[ -z "$NOTION_TOKEN" || -z "$NOTION_FILE_TOKEN" || -z "$NOTION_SPACE_ID" ]]; then
  die "Need to have NOTION_TOKEN, NOTION_FILE_TOKEN and NOTION_SPACE_ID defined in the environment. See https://github.com/datalabfabriek/dl-co-notionbackup/blob/main/README.md for a manual on how to get that information."
fi

get_downloadable_zips_from_notion