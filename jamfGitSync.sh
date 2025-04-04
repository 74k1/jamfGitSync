#!/usr/bin/env bash

# Vars
numCores=$(getconf _NPROCESSORS_ONLN)
maxParallelJobs="$(( numCores * 2 ))"
unameType=$(uname -s)
scriptSummariesFile="/tmp/script_summaries.json"

unset jamfProURL apiUser apiPass dryRun downloadScripts downloadEAs pushChangesToJamfPro apiToken

# Checks

# jq
if ! command -v jq > /dev/null ; then
    echo "[Error] jq is not installed but required."
    exit 1
fi

# Functions

function changed_scripts() {
  local change="$1"
  local changedFile="./${change}"
  local record name script cleanRecord id json httpCode

  # Exit if file doesnt exist
  [[ ! -e "$changedFile" ]] && echo "[ERROR] File does not exist: $changedFile" && exit 1

  # If the changed file is .json, then we need to locate the accompanying script
  if [[ "$change" == *.json ]]; then
    record="$changedFile"
    if [[ "$unameType" == "Darwin" ]]; then
      script=$(find -E "$(dirname "$changedFile")" -regex '.*(.py|.swift|.pl|.rb|.applescript|.zsh|.sh)$' -maxdepth 1 -mindepth 1 | head -n 1 )
    else
      script=$(find "$(dirname "$changedFile")" -regextype posix-extended -regex '.*(.py|.swift|.pl|.rb|.applescript|.zsh|.sh)$' -maxdepth 1 -mindepth 1 | head -n 1 )
    fi
  fi

  # If the changed file is the script, we need to find the accompanying json file
  if [[ "$change" =~ .*(.py|.swift|.pl|.rb|.applescript|.zsh|.sh)$ ]]; then
    script="$changedFile"
    record=$(find "$(dirname "$changedFile")" -name "*.xml" -maxdepth 1 -mindepth 1 | head -n 1 )
  fi

  # Exit if there's no json file
  if [[ -z "$record" ]]; then
    echo "[ERROR] No record json found for: $change"
    return 1
  fi

  # Same for the script
  if [[ -z "$script" ]]; then
    echo "[ERROR] Script not found for: $change"
    return 1
  fi

  # Make sure the json doesn't include things we don't want
  cleanRecord=$(jq 'del(.id) | del(.scriptContents)' < "$record")

  # Ensure we can get a name from the xml record
  name=$(echo "$cleanRecord" | jq -r -c '.name')
  [[ -z "$name" ]] && echo "[ERROR] Could not determine name of script from json record, skipping." && return 1

  # Determine the id of a script that may exist in Jamf Pro with the same name
  id=$(get_script_summaries | jq -r -c '.results | .[] | select(.name | test("$name"; "i")) | .id' )

  # Create json containing both the original json record and the script contents
  json=$(
    jq -Rsn --argjson a "$cleanRecord" --rawfile script "$script" '$a + { "scriptContents": $script }'
  )

  echo "$json" > tmp_script.json

  if [[ -z "$json" ]]; then
    echo "[ERROR] Failed to encode json and the script contents properly."
    return 1
  fi

  # Update the script in Jamf Pro if it already exists
  # Otherwise, create a new script in Jamf Pro

  if [[ -n "$id" ]]; then

    # If configured to backup
    [[ "$backupUpdated" == "true" ]] && download_script "$id" "$name" "./backups/scrpits"

    # Handle dry run and return
    [[ "$dryRun" == "true" ]] && echo "[DRY] Simulating updating script \"$name\"..." && sleep 1 && return

    echo "[INFO] Updating script: $name..."
    httpCode=$(
      curl -s -X PUT \
        -H "Authorization: Bearer $apiToken" \
        -H "Content-Type: application/json" \
        "$jamfProURL/api/v1/scripts/$id" \
        --data-binary @tmp_script.json \
        -o /dev/null \
        -w "%{http_code}"
    )
    parse_http_code "$httpCode" || return 1
        # -o /dev/null \
        # -w "%{http_code}"
  else
    [[ "$dryRun" == "true" ]] && echo "[DRY] Simulating updating script \"$name\"..." && sleep 1 && return

    echo "[INFO] Creating new script: $name..."
    httpCode=$(
      curl -s -v -X POST \
        -H "Authorization: Bearer $apiToken" \
        -H "Content-Type: application/json" \
        "$jamfProURL/api/v1/scripts" \
        --data-binary @tmp_script.json \
        -o /dev/null \
        -w "%{http_code}"
    )
    parse_http_code "$httpCode" || return 1

  fi

  rm tmp_script.json

  return
}

function auth() {
  local healthCheckHttpCode response

  # attempt contacting the Jamf Pro Server
  healthCheckHttpCode=$(curl -s "$jamfProURL"/healthCheck.html -X GET -o /dev/null -w "%{http_code}")

  if [[ "$healthCheckHttpCode" != "200" ]]; then
    echo "[ERROR] unable to contact the Jamf Pro server; exiting"
    exit 1
  fi

  response=$(
    curl --request POST \
      --url "${jamfProURL}/api/v1/oauth/token" \
      --header 'accept: application/json' \
      --header 'content-type: application/x-www-form-urlencoded' \
      --data "grant_type=client_credentials" \
      --data "client_id=${clientId}" \
      --data "client_secret=${clientSecret}" \
      -o "$scriptSummariesFile" -w "%{http_code}"
  )

  apiToken=$(jq -r ".access_token" < "$scriptSummariesFile")

  echo "HTTP Status Code: $response"
  echo "Token: $apiToken"
  
  parse_http_code "$response" || exit 3

  rm "$scriptSummariesFile"

  return
}

function get_script_summaries() {
  if [[ -e "$scriptSummariesFile" ]]; then
    cat "$scriptSummariesFile"
  else
    curl -s -H "Authorization: Bearer $apiToken" -H "accept: application/json" \
      "$jamfProURL/api/v1/scripts?page=0&page-size=10000&sort=id%3Aasc" \
      -o "$scriptSummariesFile" \
      -X GET 2>/dev/null
    cat "$scriptSummariesFile"
  fi
}

# DOWNLOAD SCRIPTS
function download_script() {
  local id="$1"
  local name="$2"
  local dlPath="$3"
  local script shebang extension

  # Pull the full script object
  script=$(curl --request GET \
    "$jamfProURL/api/v1/scripts/$id" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $apiToken" \
    2>/dev/null
  )

  [[ -z "$script" ]] && echo "[ERROR] Error getting scripts." && return 1

  shebang=$(echo "$script" | jq -c -r '.scriptContents' | head -n 1)

  extension=$(get_script_extension "$shebang")

  echo "[INFO] Writing script \"$name\" to disk."

  mkdir -p "${dlPath}/${name}"

  echo "$script" | jq 'del(.id) | del(.scriptContents)' > "${dlPath}/${name}/record.json"

  echo "$script" | jq -r -c '.scriptContents' | tr -d '\r' > "${dlPath}/${name}/script.${extension}"

  return
}

# https://developer.jamf.com/jamf-pro/docs/jamf-pro-api-overview#response-codes
function parse_http_code() {
  local httpCode="$1"
  case "$httpCode" in
    200) # success
      return
      ;;
    201)
      return
      ;;
    204)
      return
      ;;
    400)
      echo "[ERROR] 400: Bad request. Verify the syntax of the request, specifically the request body."
      ;;
    401)
      echo "[ERROR] 401: Authentication failed. Verify the credentials being used for the request."
      ;;
    403)
      echo "[ERROR] 403: Invalid permissions. Verify the account being used has the proper permissions for the resource you are trying to access."
      ;;
    404)
      echo "[ERROR] 404: Resource not found. Verify the URL path is correct."
      ;;
    409)
      echo "[ERROR] 409: The request could not be completed due to a conflict with the current state of the resource."
      ;;
    412)
      echo "[ERROR] 412: Precondition failed. See error description for additional details."
      ;;
    414)
      echo "[ERROR] 414: Request-URI too long."
      ;;
    500)
      echo "[ERROR] 500: Internal server error. Retry the request or contact support if the error persists."
      ;;
    503)
      echo "[ERROR] 503: Service unavailable."
      ;;
    *)
      echo "[ERROR] $httpCode: Unknown error occured."
      ;;
  esac
}

function get_script_extension() {
  local shebang="$1"

  case "$shebang" in
    *python*)
      echo "py"
      ;;
    *swift*)
      echo "swift"
      ;;
    *perl*)
      echo "pl"
      ;;
    *ruby*)
      echo "rb"
      ;;
    *osascript*)
      echo "applescript"
      ;;
    *zsh*)
      echo "zsh"
      ;;
    # Everything else falls into a sh script
    # Other types can easily be added above this point if necessary
    *)
      echo "sh"
      ;;
  esac
  return
}

function finish() {
  [[ -n "$apiToken" ]] && curl -s -H "Authorization: Bearer $apiToken" "$jamfProURL/v1/auth/invalidate-token" -X POST

  rm "$scriptSummariesFile" 2>/dev/null
}

# Main

# Parse command line arguments
while test $# -gt 0
do
  case "$1" in
    --url)
      shift
      jamfProURL="${1%/}"
      ;;
    --clientid)
      shift
      clientId="$1"
      ;;
    --clientsecret)
      shift
      clientSecret="$1"
      ;;
    --download-scripts)
      downloadScripts="true"
      ;;
    --push-changes-to-jamf-pro)
      pushChangesToJamfPro="true"
      ;;
    --backup-updated)
      backupUpdated="true"
      ;;
    --limit)
      shift
      maxParallelJobs="$1"
      ;;
    --dry-run)
      dryRun="true"
      ;;
    *)
      # Exit if we received an unknown option/flag/argument
      [[ "$1" == --* ]] && echo "Unknown option/flag: $1" && exit 4
      [[ "$1" != --* ]] && echo "Unknown argument: $1" && exit 4
      ;;
  esac
  shift
done

# Exit if required arguments are missing

[[ -z "$jamfProURL" ]] && echo "[ERROR] Missing Jamf Pro URL (--url)" && exit 1
[[ -z "$clientId" ]] && echo "[ERROR] Missing API Client ID (--clientid)" && exit 2
[[ -z "$clientSecret" ]] && echo "[ERROR] Missing API Client Secret (--clientsecret)" && exit 3

# Obtain Jamf Pro API Bearer Token
auth

# Obtained $apiToken with 60s timeout

# get_script_summaries

if [[ "$pushChangesToJamfPro" == "true" ]]; then
  # Make sure we're running from a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "[ERROR] Not a git repository."
    echo "[HINT] This is designed to upload changes to scripts that are changed between the latest two git commits."
    exit 1
  fi

  echo "[INFO] Determining changes between the last two git commits.."

  while read -r change; do
    if [[ "$change" == scripts/* ]]; then
      changed_scripts "$change"
    else
      echo "[WARNING] Ignoring non-tracked changed file: $change"
      continue
    fi
  done < <(git diff --name-only HEAD HEAD~1 2>/dev/null | grep -E '^scripts.*' | rev | sort -u -t '/' -k2 | rev | sort)
  exit 0
fi

# Download scripts if configured to do so with two jobs per core (unless --limit is set)

if [[ "$downloadScripts" == "true" ]]; then
  echo "[INFO] Getting identifying info for all scritps in Jamf Pro..."

  # Loop through each script ID/Name from a summary obtained from Jamf Pro
  while read -r summary; do
    # Limit the parallell jobs to what we've set as the max
    until [[ "$(jobs -lr 2>&1 | wc -l)" -lt "$maxParallelJobs" ]]; do
      sleep 1
    done

    # Extract the id and name of each script
    id=$(echo "$summary" | jq -r -c '.id')
    name=$(echo "$summary" | jq -r -c '.name')

    download_script "$id" "$name" "./scripts" &
  done < <(get_script_summaries | jq -r -c '.results | .[]')
  wait
fi

exit 0
