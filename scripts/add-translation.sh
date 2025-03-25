#!/bin/bash
set -euo pipefail

BASE_URL=${BASE_URL:-"https://api.comfy.org"}
JWT_TOKEN=${JWT_TOKEN:-"missing.jwt.token"}

for folder in translations/*/; do
    if [ ! -d "$folder" ]; then
        continue
    fi

    NODE_ID=$(basename "$folder")
    if ! git diff --name-only HEAD^ | grep 'translations/' | awk -F'/' '{print $2}' | sort -u | grep "$NODE_ID" >/dev/null; then
        echo "skipping '$NODE_ID' because it has no changes"
        continue
    fi

    BODY_FILE="$NODE_ID.json"
    echo '{}' >"$BODY_FILE"

    for subfolder in "$folder"/*/; do
        if [ ! -d "$subfolder" ]; then
            continue
        fi

        SUBFOLDER_NAME=$(basename "$subfolder")
        CONFIG_FILE="$subfolder/nodeDefs.json"

        if [ ! -f "$CONFIG_FILE" ]; then
            continue
        fi

        CONTENT=$(cat "$CONFIG_FILE" | jq -c .)
        jq --arg key "$SUBFOLDER_NAME" --argjson value "$CONTENT" \
            '. + {($key): $value}' "$BODY_FILE" >"tmp.json" &&
            mv "tmp.json" "$BODY_FILE"

    done

    jq \
        '{"data": .}' "$BODY_FILE" >"tmp.json" &&
        mv "tmp.json" "$BODY_FILE"

    echo "adding translation for $NODE_ID..."
    curl "$BASE_URL/nodes/$NODE_ID/translations" \
        --fail-with-body \
        --header "Authorization: Bearer $JWT_TOKEN" \
        --header 'Content-Type: application/json' \
        -d "@$BODY_FILE"

    rm -f "$BODY_FILE"
done
