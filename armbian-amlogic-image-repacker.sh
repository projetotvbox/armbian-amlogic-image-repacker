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
ROSE_PINE_THEME="use_shadow = OFF
use_colors = ON
screen_color = (CYAN,BLACK,OFF)
dialog_color = (WHITE,BLACK,OFF)
title_color = (MAGENTA,BLACK,ON)
border_color = (BLUE,BLACK,OFF)
button_active_color = (BLACK,YELLOW,ON)
button_inactive_color = (WHITE,BLACK,OFF)
tag_color = (YELLOW,BLACK,ON)
item_color = (WHITE,BLACK,OFF)
item_selected_color = (BLACK,MAGENTA,ON)"

# --- Improved Dialog Call ---
# Using 'echo -e' ensures newlines are handled correctly within the substitution
SELECTION=$(DIALOGRC=<(echo "$ROSE_PINE_THEME") dialog --clear \
                --backtitle "Armbian Repacker - Rosé Pine Edition" \
                --title " Image Selection " \
                --menu "Select an .img file to process:" \
                15 60 8 \
                "${OPTIONS[@]}" \
                3>&1 1>&2 2>&3)

EXIT_STATUS=$?
clear

# # 4. Display the Dialog menu
# # We redirect stderr (3) to a variable to capture the user selection
# SELECTION=$(dialog --clear \
#                 --backtitle "$BACKTITLE" \
#                 --title "Image Selection" \
#                 --menu "Select an .img file to process:" \
#                 15 50 8 \
#                 "${OPTIONS[@]}" \
#                 2>&1 >/dev/tty)x

# 5. Handle the result
clear

if [[ -n "$SELECTION" ]]; then
    echo "You selected: $ORIGINAL_IMAGES_DIR/$SELECTION"
    # Proceed with your sfdisk/manipulation logic here
else
    echo "Selection cancelled."
fi