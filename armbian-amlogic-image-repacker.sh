#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Error: please run as root."
    exit 1
fi

# list of packages we rely on; use array so we can quote safely later
DEPENDENCIES=(pv parted dialog dosfstools rsync)
MISSING_PKGS=()

echo "Checking dependencies..."

for pkg in "${DEPENDENCIES[@]}"; do

    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then

        echo "Dependency missing: $pkg"
        
        MISSING_PKGS+=("$pkg")

    fi

done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then

    echo "Installing missing dependencies: ${MISSING_PKGS[*]}"

    apt-get update

    # expand array unquoted so each element is a separate argument
    apt-get install -y "${MISSING_PKGS[@]}"

    if [ $? -ne 0 ]; then

        echo "CRITICAL ERROR: Failed to install dependencies (${MISSING_PKGS[*]})."

        echo "Please check your internet connection."

        exit 1

    fi

fi

# --- Rosé Pine (Main) Corrected Theme String ---
# We ensure no leading/trailing spaces and standard ANSI names.
THEME_CONTENT="use_shadow = ON
use_colors = ON
screen_color = (MAGENTA,BLACK,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (MAGENTA,WHITE,ON)
border_color = (BLUE,WHITE,ON)
button_active_color = (WHITE,BLUE,OFF)
button_inactive_color = (WHITE,BLUE,OFF)

item_selected_color = (WHITE,MAGENTA,ON)"

THEME=$(mktemp)

printf "%s\n" "$THEME_CONTENT" > "$THEME"

INSTALL_SESSION_ID="armbian-amlogic-image-repacker-$$"
WORK_DIR="/mnt/$INSTALL_SESSION_ID"

MNT_REPACKED_BOOT="$WORK_DIR/repacked-boot"
MNT_REPACKED_ROOTFS="$WORK_DIR/repacked-rootfs"
MNT_SOURCE_BOOT="$WORK_DIR/source-boot"

LOOP=""
LOOP_ORIG=""
LOOP_DEV=""

cleanup() {
    mountpoint -q "$MNT_REPACKED_BOOT"   && umount "$MNT_REPACKED_BOOT"   2>/dev/null
    mountpoint -q "$MNT_REPACKED_ROOTFS" && umount "$MNT_REPACKED_ROOTFS" 2>/dev/null
    mountpoint -q "$MNT_SOURCE_BOOT"     && umount "$MNT_SOURCE_BOOT"     2>/dev/null

    [ -n "$LOOP"      ] && losetup -d "$LOOP"      2>/dev/null
    [ -n "$LOOP_ORIG" ] && losetup -d "$LOOP_ORIG" 2>/dev/null
    [ -n "$LOOP_DEV"  ] && losetup -d "$LOOP_DEV"  2>/dev/null

    rm -rf "$WORK_DIR" 2>/dev/null
}

trap 'cleanup; rm -f "$THEME"; clear' EXIT

ORIGINAL_IMAGES_DIR="./original-images"
REPACKED_IMAGES_DIR="./repacked-images"

BACKTITLE="Armbian Amlogic Image Repacker - UNOFFICIAL SCRIPT - by Fábio Haruo and Pedro Rigolin"

dialog_throw_error() {

    ERROR_MSG="$1"
    
    DIALOGRC="$THEME" dialog \
        --backtitle "$BACKTITLE" \
        --title "Error" \
        --ok-label "OK" \
        --msgbox "\n$ERROR_MSG" \
        10 60
    
    exit 1

}

dialog_assert_exit_status() {
    
    ERROR_MSG="$1"
    EXIT_STATUS="$?"

    if [ "$EXIT_STATUS" -ne 0 ]; then
        dialog_throw_error "$ERROR_MSG"
    fi

}

dialog_show_wait() {
    
    MESSAGE="$1"
    
    DIALOGRC="$THEME" dialog \
        --backtitle "$BACKTITLE" \
        --title "Please Wait" \
        --infobox "\n$MESSAGE" \
        5 60

}

assert_img_fs() {
    
    local IMG_PATH="$1"
    local EXPECTED_IMG_FSTYPE="$2"

    LOOP_DEV=$(losetup -fP --show "$IMG_PATH")

    local IMG_FSTYPE
    IMG_FSTYPE=$(blkid -o value -s TYPE "${LOOP_DEV}p1")

    losetup -d "$LOOP_DEV"

    if [ "$IMG_FSTYPE" != "$EXPECTED_IMG_FSTYPE" ]; then
        dialog_throw_error "Error: expected filesystem '$EXPECTED_IMG_FSTYPE' on first partition but found '${IMG_FSTYPE:-none}'."
    fi
    
}

if [ ! -d "$ORIGINAL_IMAGES_DIR" ]; then

    mkdir -p "$ORIGINAL_IMAGES_DIR"

    dialog_throw_error "The directory '$ORIGINAL_IMAGES_DIR' did not exist and was created.\nPlease add your Armbian .img files to it and run the script again."

fi

if [ ! -d "$REPACKED_IMAGES_DIR" ]; then
    mkdir -p "$REPACKED_IMAGES_DIR"
fi

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
    dialog_throw_error "No .img files found in '$ORIGINAL_IMAGES_DIR'. Please add some images and try again."
fi

# --- Improved Dialog Call ---
# Using 'echo -e' ensures newlines are handled correctly within the substitution
IMAGE_NAME=$(DIALOGRC="$THEME" dialog \
                --backtitle "$BACKTITLE" \
                --title "Image Selection" \
                --ok-label "Select" \
                --cancel-label "Cancel" \
                --menu "\nSelect an .img file to process:" \
                15 60 8 \
                "${OPTIONS[@]}" \
                3>&1 1>&2 2>&3)

EXIT_STATUS="$?"

#TODO: LOGAR ISSO
if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Selection cancelled."
    exit 0
fi

# if [[ -n "$IMAGE" ]]; then
#     #Aqui vai vir log
#     # echo "You selected: $ORIGINAL_IMAGES_DIR/$IMAGE_NAME"
#     # Proceed with your sfdisk/manipulation logic here
# else
#     #Aqui vai vir log
#     # echo "Selection cancelled."
# fi

ORIGINAL_IMAGE="$ORIGINAL_IMAGES_DIR/$IMAGE_NAME"
assert_img_fs "$ORIGINAL_IMAGE" "ext4"

# We are going to test if the image is valid by trying to read its partition table
# If it fails, we will show an error message and exit

BOOT_SIZE=$(DIALOGRC="$THEME" dialog \
                --backtitle "$BACKTITLE" \
                --title "Boot Partition Size" \
                --ok-label "Accept" \
                --cancel-label "Cancel" \
                --menu "\nSelect the desired size for the BOOT partition:" \
                15 75 8 \
                "512MiB" "512 MB (Recommended for most users)" \
                "256MiB" "256 MB (Minimum, may cause issues with some devices)" \
                3>&1 1>&2 2>&3)

EXIT_STATUS="$?"

#TODO: LOGAR ISSO
if [ "$EXIT_STATUS" -ne 0 ]; then
    echo "Selection cancelled."
    exit 0
fi

# if [[ -n "$BOOT_SIZE" ]]; then
#     #Aqui vai vir log
#     # echo "You selected BOOT partition size: $BOOT_SIZE"
# else
#     #Aqui vai vir log
#     # echo "Selection cancelled."
# fi

dialog_show_wait "Processing the image. Please wait..."

IMAGE="$REPACKED_IMAGES_DIR/repacked_$IMAGE_NAME"

ORIGINAL_SIZE=$(stat -c%s "$ORIGINAL_IMAGE")
truncate -s "$ORIGINAL_SIZE" "$IMAGE"
dialog_assert_exit_status "Error creating the image file."

# Cria o particionamento MBR
parted -s "$IMAGE" mklabel msdos
dialog_assert_exit_status "Error in partitioning system."

# Partição 1: Boot FAT32 (256MB)
parted -s "$IMAGE" mkpart primary fat32 1MiB "$BOOT_SIZE"
dialog_assert_exit_status "Error: cannot format system."

parted -s "$IMAGE" set 1 boot on
dialog_assert_exit_status "Error: cannot set boot flag."

parted -s "$IMAGE" set 1 lba on
dialog_assert_exit_status "Error: cannot set LBA flag."

parted -s "$IMAGE" mkpart primary ext4 "$BOOT_SIZE" 100%
dialog_assert_exit_status "Error: cannot create ext4 partition"

dialog_show_wait "Mounting images. Please wait..."

LOOP=$(losetup -fP --show "$IMAGE")
dialog_assert_exit_status "Error: cannot setup loop device."

LOOP_ORIG=$(losetup -fP --show "$ORIGINAL_IMAGE")
dialog_assert_exit_status "Error: cannot setup loop device for original image."

# Formata as partições novas
mkfs.vfat -n BOOT "${LOOP}p1" > /dev/null 2>&1
dialog_assert_exit_status "Error: cannot format boot partition."

mkfs.ext4 -L ROOTFS "${LOOP}p2" > /dev/null 2>&1
dialog_assert_exit_status "Error: cannot format rootfs partition."

mkdir -p "$MNT_REPACKED_BOOT" "$MNT_REPACKED_ROOTFS" "$MNT_SOURCE_BOOT"
dialog_assert_exit_status "Error: cannot create working directories."

#TODO: FAZER BOOT SER UM LINK SIMBOLICO

mount "${LOOP}p1" "$MNT_REPACKED_BOOT"
dialog_assert_exit_status "Error: cannot mount boot partition."

mount "${LOOP}p2" "$MNT_REPACKED_ROOTFS"
dialog_assert_exit_status "Error: cannot mount rootfs partition."

mount "${LOOP_ORIG}p1" "$MNT_SOURCE_BOOT"
dialog_assert_exit_status "Error: cannot mount original image boot partition."

dialog_show_wait "Copying boot files. Please wait..."

rsync -rltHL --no-owner --no-group --no-perms "$MNT_SOURCE_BOOT/boot/" "$MNT_REPACKED_BOOT/"
dialog_assert_exit_status "Error: cannot copy boot files."

dialog_show_wait "Copying rootfs files. Please wait..."

rsync -aAXH "$MNT_SOURCE_BOOT/" "$MNT_REPACKED_ROOTFS/"
dialog_assert_exit_status "Error: cannot copy rootfs files."

dialog_show_wait "Cleaning up. Please wait..."

cleanup

DIALOGRC="$THEME" dialog \
    --backtitle "$BACKTITLE" \
    --title "Success" \
    --ok-label "OK" \
    --msgbox "\nImage repacked successfully:\n$IMAGE" \
    10 60

exit 0