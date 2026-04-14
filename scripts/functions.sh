
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
    local tmp_json
    tmp_json=$(mktemp)

    # Make the POST request and capture the task ID
    if post "getNotificationLog" "$payload" > "$tmp_json"; then
        # Ensure inventory file exists so grep checks are predictable.
        touch "$DL_INVENTORY_LIST"

        # Parse activity records defensively because Notion response shape can vary.
        jq -r '
        (.recordMap.activity // {})
        | to_entries[]?
        | .key as $objectId
        | ((.value.value.value // .value.value // .value // {}) ) as $activity
        | ((($activity.edits // [])
          | map(select(.type == "export-completed" and (.link // "") != ""))
          | .[0].link) // empty) as $link
        | select($link != "")
        | "\($objectId)\t\($link)"
        ' "$tmp_json" | while IFS=$'\t' read -r objectId link; do

            [ -z "$objectId" ] && continue
            [ -z "$link" ] && continue

            grep -qF "$objectId" "$DL_INVENTORY_LIST"

            if [ $? -ne 0 ]; then
                echo "$objectId" >> "$DL_INVENTORY_LIST"
                download "$link" "${DL_BACKUP_PATH}/$(date +'%Y-%m-%dT%H%M%S')_$objectId.zip"
            fi

        done

        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            warn "Failed to parse notification log response."
          warn "Raw notification response follows:"
          cat "$tmp_json" >&2
        fi

    else
        warn "Failed to get notification log."
        if [ -s "$tmp_json" ]; then
        warn "Raw notification response follows:"
        cat "$tmp_json" >&2
        fi
    fi

    rm -f "$tmp_json"
}