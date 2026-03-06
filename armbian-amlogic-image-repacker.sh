#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Error: please run as root."
    exit 1
fi

DEPENDENCIES="pv parted dialog dosfstools rsync"
MISSING_PKGS=""

echo "Checking dependencies..."

for pkg in $DEPENDENCIES; do

    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then

        echo "Dependency missing: $pkg"

        MISSING_PKGS="$MISSING_PKGS $pkg"

    fi

done

if [ -n "$MISSING_PKGS" ]; then

    echo "Installing missing dependencies:$MISSING_PKGS"

    apt-get update
    apt-get install -y "$MISSING_PKGS"

    if [ "$?" -ne 0 ]; then

        echo "CRITICAL ERROR: Failed to install dependencies ($MISSING_PKGS)."

        echo "Please check your internet connection."

        exit 1    

    
    fi

fi

ORIGINAL_IMAGES_DIR="./original-images"
REPACKED_IMAGES_DIR="./repacked-images"

if [ ! -d "$ORIGINAL_IMAGES_DIR" ]; then
    echo "Error: Original images directory '$ORIGINAL_IMAGES_DIR' not found."
    exit 1
fi

if [ ! -d "$REPACKED_IMAGES_DIR" ]; then
    mkdir -p "$REPACKED_IMAGES_DIR"
fi

BACKTITLE="Armbian Amlogic Image Repacker - UNOFFICIAL SCRIPT - by Fábio Haruo and Pedro Rigolin"

# 2. Collect .img files into an array
# We use a glob and a loop to build the (Tag Description) pairs
OPTIONS=()

while IFS= read -r -d $'\0' file; do

    FILENAME=$(basename "$file")

    # Tag: filename | Description: size or path
    OPTIONS+=("$FILENAME" "Image file")

done < <(find "$ORIGINAL_IMAGES_DIR" -maxdepth 1 -name "*.img" -print0)

# 3. Check if any images were found
if [ ${#OPTIONS[@]} -eq 0 ]; then

    dialog --clear \
           --backtitle "$BACKTITLE" \
           --title "No Images Found" \
           --msgbox "No .img files found in '$ORIGINAL_IMAGES_DIR'. Please add some images and try again." \
           10 50

    clear

    exit 0

fi


# --- Rosé Pine (Main) Corrected Theme String ---
# We ensure no leading/trailing spaces and standard ANSI names.
THEME="use_shadow = ON
use_colors = ON
screen_color = (MAGENTA,BLACK,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (MAGENTA,WHITE,ON)
border_color = (BLUE,WHITE,OFF)
button_active_color = (WHITE,YELLOW,ON)
button_inactive_color = (WHITE,WHITE,OFF)
tag_color = (BLACK,YELLOW,ON)
item_selected_color = (WHITE,MAGENTA,ON)"

# --- Improved Dialog Call ---
# Using 'echo -e' ensures newlines are handled correctly within the substitution
SELECTION=$(DIALOGRC=<(echo "$THEME") dialog --clear \
                --backtitle "$BACKTITLE" \
                --title " Image Selection " \
                --ok-label "Select" \
                --cancel-label "Cancel" \
                --menu "\nSelect an .img file to process:" \
                15 60 8 \
                "${OPTIONS[@]}" \
                3>&1 1>&2 2>&3)

EXIT_STATUS=$?

# 5. Handle the result
clear

#TODO: LOGAR ISSO
if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Selection cancelled."
    exit 0
fi

if [[ -n "$SELECTION" ]]; then
    echo "You selected: $ORIGINAL_IMAGES_DIR/$SELECTION"
    # Proceed with your sfdisk/manipulation logic here
else
    echo "Selection cancelled."
fi

BOOT_SIZE=$(DIALOGRC=<(echo "$THEME") dialog --clear \
                --backtitle "$BACKTITLE" \
                --title " Boot Partition Size " \
                --ok-label "Accept" \
                --cancel-label "Cancel" \
                --menu "\nSelect the desired size for the BOOT partition:" \
                15 75 8 \
                "512M" "512 MB (Recommended for most users)" \
                "256M" "256 MB (Minimum, may cause issues with some devices)" \
                3>&1 1>&2 2>&3)

EXIT_STATUS=$?

if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Selection cancelled."
    exit 0
fi

if [[ -n "$BOOT_SIZE" ]]; then
    echo "You selected BOOT partition size: $BOOT_SIZE"
    # Proceed with your sfdisk/manipulation logic here
else
    echo "Selection cancelled."
fi