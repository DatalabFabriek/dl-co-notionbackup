#!/bin/bash

source /datalab/functions.sh
source /datalab/.env

# Check for required environment variables
if [[ -z "$NOTION_TOKEN" || -z "$NOTION_FILE_TOKEN" || -z "$NOTION_SPACE_ID" ]]; then
  die "Need to have NOTION_TOKEN, NOTION_FILE_TOKEN and NOTION_SPACE_ID defined in the environment. See https://github.com/datalabfabriek/dl-co-notionbackup/blob/main/README.md for a manual on how to get that information."
fi

export_from_notion "markdown"