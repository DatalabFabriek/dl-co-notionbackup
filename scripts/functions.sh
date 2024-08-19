
#!/bin/bash

# Helper function to exit on error
die() {
  echo "$(date) - $1" >&2
  exit 1
}

# Helper function to warn
warn() {
  echo "$(date) - $1" >&2
}


# Function to make a POST request
post() {
  local endpoint="$1"
  local data="$2"
  curl -X POST "https://www.notion.so/api/v3/$endpoint" \
    -H "Content-Type: application/json" \
    -H "Cookie: token_v2=$NOTION_TOKEN" \
    --data "$data"
}

# Function to make a POST request
download() {
  local url="$1"
  local filename="$2"

  curl -X GET "$url" \
    -H "Cookie: token_v2=$NOTION_TOKEN;file_token=$NOTION_FILE_TOKEN" \
    -o "$filename"
}

# Function to export data from Notion in the specified format
export_from_notion() {
  local format="$1"
  
  # Prepare the payload for the POST request
  local payload=$(cat <<EOF
{
  "task": {
    "eventName": "exportSpace",
    "request": {
      "spaceId": "$NOTION_SPACE_ID",
      "exportOptions": {
        "exportType": "$format",
        "timeZone": "Europe/Amsterdam",
        "locale": "en"
      },
      "shouldExportComments": false
    }
  }
}
EOF
)

  # Make the POST request and capture the task ID
  local response=$(post "enqueueTask" "$payload")
  local taskId=$(echo "$response" | jq -r '.taskId')
    echo "Response: $response"

  if [[ "$taskId" != "null" ]]; then
    echo "Enqueued task $taskId"
  else
    warn "Failed to enqueue task."
  fi
}


get_downloadable_zips_from_notion() {
    # Prepare the payload for the POST request
    local payload="{\"spaceId\":\"${NOTION_SPACE_ID}\",\"size\":20,\"type\":\"unread_and_read\",\"variant\":\"no_grouping\"}"

    # Make the POST request and capture the task ID
    post "getNotificationLogV2" "$payload" > /tmp/json

    if [ $? -eq 0 ]; then
        # Use jq to loop through each activity object and assign to variables
        jq -r '
        .recordMap.activity | 
        to_entries[] | 
        # Assign clearer names to parts of the structure
        .key as $objectId |
        .value.value as $activity |
        # Check if the edits contain export-completed
        select($activity.edits[].type == "export-completed") |
        # Output the objectId and the link from the first edit
        "\($objectId) \($activity.edits[0].link)"
        ' /tmp/json | while read -r objectId link; do

            grep "$objectId" "$DL_INVENTORY_LIST" > /dev/null 2> /dev/null

            if [ $? -ne 0 ]; then
                echo "$objectId" >> "$DL_INVENTORY_LIST"
                download "$link" "${DL_BACKUP_PATH}/$(date +'%Y-%m-%dT%H%M%S')_$objectId.zip"
            fi

        done

    else
        warn "Failed to get notification log."
    fi
}