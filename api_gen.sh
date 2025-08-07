#!/bin/bash

set -eo pipefail

for var in TOSCRIPT API_UID API_SEC; do
	if [ -z "$var" ]; then 
		echo "[FATAL]: empty $var variable"
		exit 1;
	fi
done

abspath="${TOSCRIPT}".json
declare -i expiration
now=$(date +%s)

mkdir -p "$abspath"

if [ -f "$abspath"/bestbefore.json ]; then
	expiration=$(jq -r '.expire_in // 0' "$abspath"/bestbefore.json)
else
	echo "[INFO] Token not found..."
	expiration=0
fi

if [ "$now" -ge "$expiration" ]; then
	echo "[INFO] Invalid token, refreshing..."
	if ! curl -s -X POST --data \
		"grant_type=client_credentials&client_id=$API_UID&client_secret=$API_SEC" \
		https://api.intra.42.fr/oauth/token >"$abspath"/token.json; then
		echo "Error: failed to obtain access token"
		exit 1
	fi
	expire_in=$(jq -e -r '.expires_in' "$abspath"/token.json)
	bestbefore=$(($(date +%s) + "$expire_in"))
	jq -n --argjson exp "$bestbefore" \ '{expire_in: $exp}' >"$abspath"/bestbefore.json
fi

exit 0