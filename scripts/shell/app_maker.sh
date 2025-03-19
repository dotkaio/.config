#!/bin/bash
# Usage: ./create_app.sh <website_url> <app_name>
# Example: ./create_app.sh "https://example.com" "ExampleApp"

# Ensure two parameters are passed
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <website_url> <app_name>"
  exit 1
fi

WEBSITE_URL=$1
APP_NAME=$2

# Define template and output directories
TEMPLATE_DIR="/Users/sysadm/Developer/make-app/MyWebAppTemplate"  # Your base Xcode template directory
DESKTOP_DIR="$HOME/Desktop"
NEW_APP_DIR="${DESKTOP_DIR}/${APP_NAME}_App"

# Copy the template project to a new folder on the Desktop
cp -R "${TEMPLATE_DIR}" "${NEW_APP_DIR}"

# Update the ContentView.swift file with the provided website URL.
CONTENT_VIEW_FILE="${NEW_APP_DIR}/MyWebAppTemplate/ContentView.swift"
if [ -f "${CONTENT_VIEW_FILE}" ]; then
  # Replace the placeholder URL ("https://example.com") with the actual URL.
  sed -i.bak "s|https://example.com|${WEBSITE_URL}|g" "${CONTENT_VIEW_FILE}"
  echo "Updated URL in ContentView.swift"
else
  echo "Error: ${CONTENT_VIEW_FILE} not found."
fi

# Update Info.plist with the new app name.
INFO_PLIST_FILE="${NEW_APP_DIR}/MyWebAppTemplate/Info.plist"
if [ -f "${INFO_PLIST_FILE}" ]; then
  # Replace a placeholder name (e.g., "MyWebAppTemplate") with the new app name.
  sed -i.bak "s|MyWebAppTemplate|${APP_NAME}|g" "${INFO_PLIST_FILE}"
  echo "Updated app name in Info.plist"
else
  echo "Error: ${INFO_PLIST_FILE} not found."
fi

# Optional: Fetch an app icon using the macOSIcons API.
API_KEY="e1320e10c9204c13014354dece489ca145f84964b1f7739a610284dd5e78e754"
ICON_API_URL="https://api.macosicons.com/api/search"

ICON_RESPONSE=$(curl -s -X POST "${ICON_API_URL}" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${API_KEY}" \
  -d "{
    \"query\": \"${APP_NAME}\",
    \"searchOptions\": {
      \"hitsPerPage\": 2,
      \"offset\": 0,
      \"page\": 1,
      \"filters\": [\"downloads >= 20\", \"category = BO0gbTCPUK\"]
    }
  }")

# Requires jq for JSON parsing – ensure it's installed
ICON_URL=$(echo "${ICON_RESPONSE}" | jq -r '.results[0].iconUrl')

if [ -n "${ICON_URL}" ] && [ "${ICON_URL}" != "null" ]; then
  echo "Found icon URL: ${ICON_URL}"
  # Define the path to your app icon in the Assets catalog
  ICON_DEST="${NEW_APP_DIR}/MyWebAppTemplate/Assets.xcassets/AppIcon.appiconset/appicon.png"
  curl -s -o "${ICON_DEST}" "${ICON_URL}"
  echo "Downloaded icon to ${ICON_DEST}"
else
  echo "No icon found or error fetching icon."
fi

# Optional: Build the app using xcodebuild
echo "Building the app..."
cd "${NEW_APP_DIR}" || exit
# Ensure the scheme name matches the updated project; adjust if necessary.
xcodebuild -scheme "${APP_NAME}" -configuration Release

echo "App '${APP_NAME}' created successfully in ${NEW_APP_DIR}"
