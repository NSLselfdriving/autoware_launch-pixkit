#!/usr/bin/env bash

find_autoware_dir() {
    local dir
    dir=$(find "$HOME" -type d -name autoware -not -path '*/\.*' 2>/dev/null | while read -r d; do
        if [ -f "$d/autoware.repos" ]; then
            echo "$d"
            break
        fi
    done)
    echo "$dir"
}

# Find the autoware directory
AUTOWARE_DIR=$(find_autoware_dir)
if [ -z "$AUTOWARE_DIR" ]; then
    echo "Autoware directory not found. Please ensure it exists in the directory hierarchy and contains autoware.repos."
    exit 1
fi

# Save the current working directory
CURRENT_DIR=$(pwd)

# Change to the autoware directory
cd "$AUTOWARE_DIR" || exit

# Set the base directory for the ROS package
PACKAGE_NAME="autoware_launch"
SRC_DIR=$(colcon list --packages-select $PACKAGE_NAME | awk '{print $2}')
ICONS_DIR="$SRC_DIR/rviz/autoware-rviz-icons"
QSS_FILE="$AUTOWARE_DIR/$SRC_DIR/rviz/autoware.qss"
QT5CT_CONFIG_FILE="$HOME/.config/qt5ct/qt5ct.conf"

# Change back to the original working directory
cd "$CURRENT_DIR" || exit

# Check if the icon folder and QSS file exist
if [ ! -d "$ICONS_DIR" ]; then
    echo "Icons directory not found: $ICONS_DIR"
    exit 1
fi

if [ ! -f "$QSS_FILE" ]; then
    echo "QSS file not found: $QSS_FILE"
    exit 1
fi

# Create backup of the original QSS file
cp "$QSS_FILE" "$QSS_FILE.bak"

# Update paths in the QSS file
sed -i "s|url(\(.*\)\(\.png\|\.svg\))|url($ICONS_DIR/\1\2)|g" "$QSS_FILE"

# Ensure the qt5ct config directory exists
mkdir -p "$(dirname "$QT5CT_CONFIG_FILE")"

# Function to append the new stylesheet
append_stylesheet() {
    local existing_stylesheet
    existing_stylesheet=$(grep -oP '(?<=stylesheets=).*' "$QT5CT_CONFIG_FILE")

    if [[ "$existing_stylesheet" != *"$QSS_FILE"* ]]; then
        if [ -n "$existing_stylesheet" ]; then
            sed -i "s|stylesheets=.*|stylesheets=${existing_stylesheet},$QSS_FILE|g" "$QT5CT_CONFIG_FILE"
        else
            echo "stylesheets=$QSS_FILE" >>"$QT5CT_CONFIG_FILE"
        fi
    fi
}

# Add the QSS file to qt5ct config
if grep -q "stylesheets=" "$QT5CT_CONFIG_FILE"; then
    append_stylesheet
else
    echo "stylesheets=$QSS_FILE" >>"$QT5CT_CONFIG_FILE"
fi

echo "QSS file updated and qt5ct config modified successfully."
