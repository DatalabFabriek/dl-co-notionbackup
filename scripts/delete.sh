#!/bin/bash

source /datalab/.env

# Remove $DL_BACKUP_PATH least ${"DL_BASEBACK_NUMBER_OF_FILES_TO_KEEP}
ls -tpd $DL_BACKUP_PATH/*.zip | grep -v '/$' | tail -n +$((NUMBER_OF_FILES_TO_KEEP + 1)) | xargs -I {} rm -- {}