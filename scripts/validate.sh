#!/bin/bash
set -euo pipefail

BASE_URL=${BASE_URL:-"https://api.comfy.org"}
for entry in translations/*/; do
    if [ ! -d "$entry" ]; then
        echo "not a directory: $entry"
        continue
    fi

    NODE_ID=$(basename "$entry")
    echo "validating $NODE_ID..."
    curl -s --fail-with-body "$BASE_URL/nodes/$NODE_ID" >/dev/null
    echo "$NODE_ID is valid"
done
