#!/bin/bash

# ============================================================================
# LOGGING SYSTEM - Extremely Detailed Activity Tracking
# ============================================================================

# Log file configuration
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/armbian-repacker_$(date +%Y%m%d_%H%M%S).log"
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_SUCCESS=2
LOG_LEVEL_WARNING=3
LOG_LEVEL_ERROR=4
CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG  # Set to DEBUG for maximum detail

# ANSI color codes for terminal output
COLOR_RESET='\033[0m'
COLOR_DEBUG='\033[0;36m'    # Cyan
COLOR_INFO='\033[0;37m'     # White
COLOR_SUCCESS='\033[0;32m'  # Green
COLOR_WARNING='\033[0;33m'  # Yellow
COLOR_ERROR='\033[0;31m'    # Red
COLOR_BOLD='\033[1m'

# Initialize logging system
log_init() {
    mkdir -p "$LOG_DIR"
    
    # Keep only the 10 most recent log files
    local LOG_COUNT=$(find "$LOG_DIR" -name "armbian-repacker_*.log" -type f 2>/dev/null | wc -l)
    if [ "$LOG_COUNT" -ge 10 ]; then
        # Remove oldest logs, keeping only 9 (so the new one makes 10)
        find "$LOG_DIR" -name "armbian-repacker_*.log" -type f -printf '%T+ %p\n' 2>/dev/null | \
            sort | head -n -9 | cut -d' ' -f2- | xargs -r rm -f
    fi
    
    {
        echo "================================================================================"
        echo "  ARMBIAN AMLOGIC IMAGE REPACKER - DETAILED EXECUTION LOG"
        echo "================================================================================"
        echo "Session Start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Process ID: $$"
        echo "User: $(whoami) (UID: $EUID)"
        echo "Hostname: $(hostname)"
        echo "Working Directory: $(pwd)"
        echo "Shell: $SHELL ($BASH_VERSION)"
        echo "Operating System: $(uname -s) $(uname -r) $(uname -m)"
        echo "CPU Cores: $(nproc)"
        echo "Total Memory: $(free -h | awk '/^Mem:/ {print $2}')"
        echo "Available Disk Space: $(df -h . | awk 'NR==2 {print $4}')"
        echo "================================================================================"
        echo ""
    } > "$LOG_FILE"
    
    log_info "LOG_SYSTEM" "Logging system initialized successfully"
    log_debug "LOG_SYSTEM" "Log file created at: $LOG_FILE"
    log_debug "LOG_SYSTEM" "Log level set to: DEBUG (maximum verbosity)"
}

# Core logging function with timestamp and level
log_message() {
    local LEVEL="$1"
    local LEVEL_NUM="$2"
    local COMPONENT="$3"
    local MESSAGE="$4"
    local COLOR="$5"
    
    # Skip if message level is below current log level
    if [ "$LEVEL_NUM" -lt "$CURRENT_LOG_LEVEL" ]; then
        return
    fi
    
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    
    local LOG_LINE="[$TIMESTAMP] [$LEVEL] [$COMPONENT] $MESSAGE"
    
    # Write to log file only (silent mode for TUI)
    if [ -f "$LOG_FILE" ]; then
        echo "$LOG_LINE" >> "$LOG_FILE"
    fi
}

# Level-specific logging functions
log_debug() {
    log_message "DEBUG  " $LOG_LEVEL_DEBUG "$1" "$2" "$COLOR_DEBUG"
}

log_info() {
    log_message "INFO   " $LOG_LEVEL_INFO "$1" "$2" "$COLOR_INFO"
}

log_success() {
    log_message "SUCCESS" $LOG_LEVEL_SUCCESS "$1" "$2" "$COLOR_SUCCESS"
}

log_warning() {
    log_message "WARNING" $LOG_LEVEL_WARNING "$1" "$2" "$COLOR_WARNING"
}

log_error() {
    log_message "ERROR  " $LOG_LEVEL_ERROR "$1" "$2" "$COLOR_ERROR"
}

# Log variable with its value
log_var() {
    local COMPONENT="$1"
    local VAR_NAME="$2"
    local VAR_VALUE="$3"
    log_debug "$COMPONENT" "Variable [$VAR_NAME] = '$VAR_VALUE'"
}

# Log command execution
log_cmd() {
    local COMPONENT="$1"
    local CMD="$2"
    log_debug "$COMPONENT" "Executing command: $CMD"
}

# Log array contents
log_array() {
    local COMPONENT="$1"
    local ARRAY_NAME="$2"
    shift 2
    local ARRAY=("$@")
    
    log_debug "$COMPONENT" "Array [$ARRAY_NAME] has ${#ARRAY[@]} elements:"
    local i=0
    for item in "${ARRAY[@]}"; do
        log_debug "$COMPONENT" "  [$i] = '$item'"
        ((i++))
    done
}

# Log file system operation
log_fs_op() {
    local COMPONENT="$1"
    local OPERATION="$2"
    local TARGET="$3"
    local DETAILS="$4"
    log_info "$COMPONENT" "FS Operation: $OPERATION on '$TARGET' - $DETAILS"
}

# Log state change
log_state() {
    local COMPONENT="$1"
    local STATE_NAME="$2"
    local OLD_STATE="$3"
    local NEW_STATE="$4"
    log_info "$COMPONENT" "State change [$STATE_NAME]: '$OLD_STATE' -> '$NEW_STATE'"
}

# Log section separator for readability
log_section() {
    local SECTION_NAME="$1"
    local SEPARATOR="--------------------------------------------------------------------------------"
    if [ -f "$LOG_FILE" ]; then
        echo "" >> "$LOG_FILE"
    fi
    log_info "MAIN" "$SEPARATOR"
    log_info "MAIN" "BEGIN SECTION: $SECTION_NAME"
    log_info "MAIN" "$SEPARATOR"
}

# ============================================================================
# MAIN SCRIPT START
# ============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "Error: please run as root."
    exit 1
fi

# Initialize logging as early as possible
log_init

log_section "DEPENDENCY CHECK"

# list of packages we rely on; use array so we can quote safely later
DEPENDENCIES=(pv parted dialog dosfstools rsync)
MISSING_PKGS=()

log_array "DEPENDENCIES" "DEPENDENCIES" "${DEPENDENCIES[@]}"
log_info "DEPENDENCIES" "Starting dependency verification for ${#DEPENDENCIES[@]} packages"

echo "Checking dependencies..."

# TODO: Update to run on mostly package managers (pacman, apt, etc.)

for pkg in "${DEPENDENCIES[@]}"; do
    log_debug "DEPENDENCIES" "Checking package: $pkg"

    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        log_warning "DEPENDENCIES" "Dependency missing: $pkg"
        echo "Dependency missing: $pkg"

        MISSING_PKGS+=("$pkg")

    else
        log_success "DEPENDENCIES" "Package '$pkg' is installed"
    fi

done

log_var "DEPENDENCIES" "MISSING_PKGS_COUNT" "${#MISSING_PKGS[@]}"

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    log_warning "DEPENDENCIES" "Missing ${#MISSING_PKGS[@]} package(s), starting installation"
    log_array "DEPENDENCIES" "MISSING_PKGS" "${MISSING_PKGS[@]}"

    echo "Installing missing dependencies: ${MISSING_PKGS[*]}"

    log_cmd "DEPENDENCIES" "apt-get update"
    apt-get update

    # expand array unquoted so each element is a separate argument
    log_cmd "DEPENDENCIES" "apt-get install -y ${MISSING_PKGS[*]}"
    apt-get install -y "${MISSING_PKGS[@]}"

    if [ $? -ne 0 ]; then
        log_error "DEPENDENCIES" "CRITICAL: Failed to install dependencies"
        log_error "DEPENDENCIES" "Installation exit code: $?"
        log_array "DEPENDENCIES" "FAILED_PACKAGES" "${MISSING_PKGS[@]}"

        echo "CRITICAL ERROR: Failed to install dependencies (${MISSING_PKGS[*]})."

        echo "Please check your internet connection."

        exit 1

    else
        log_success "DEPENDENCIES" "All missing dependencies installed successfully"
    fi

else
    log_success "DEPENDENCIES" "All required dependencies are already installed"
fi

log_section "THEME CONFIGURATION"

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

log_debug "THEME" "Creating temporary theme file"
THEME=$(mktemp)
log_var "THEME" "THEME_FILE_PATH" "$THEME"

printf "%s\n" "$THEME_CONTENT" >"$THEME"
log_success "THEME" "Rosé Pine theme file created successfully"

log_section "ENVIRONMENT SETUP"

INSTALL_SESSION_ID="armbian-amlogic-image-repacker-$$"
WORK_DIR="/mnt/$INSTALL_SESSION_ID"

MNT_REPACKED_BOOT="$WORK_DIR/repacked-boot"
MNT_REPACKED_ROOTFS="$WORK_DIR/repacked-rootfs"
MNT_SOURCE_BOOT="$WORK_DIR/source-boot"

log_var "ENV" "INSTALL_SESSION_ID" "$INSTALL_SESSION_ID"
log_var "ENV" "WORK_DIR" "$WORK_DIR"
log_var "ENV" "MNT_REPACKED_BOOT" "$MNT_REPACKED_BOOT"
log_var "ENV" "MNT_REPACKED_ROOTFS" "$MNT_REPACKED_ROOTFS"
log_var "ENV" "MNT_SOURCE_BOOT" "$MNT_SOURCE_BOOT"

LOOP=""
LOOP_ORIG=""
LOOP_DEV=""

log_debug "ENV" "Initialized loop device variables (empty initially)"
log_var "ENV" "LOOP" "$LOOP"
log_var "ENV" "LOOP_ORIG" "$LOOP_ORIG"
log_var "ENV" "LOOP_DEV" "$LOOP_DEV"

cleanup() {
    log_section "CLEANUP"
    log_info "CLEANUP" "Starting cleanup process"
    
    if mountpoint -q "$MNT_REPACKED_BOOT"; then
        log_info "CLEANUP" "Unmounting repacked boot partition: $MNT_REPACKED_BOOT"
        umount "$MNT_REPACKED_BOOT" 2>/dev/null && log_success "CLEANUP" "Unmounted $MNT_REPACKED_BOOT" || log_warning "CLEANUP" "Failed to unmount $MNT_REPACKED_BOOT"
    fi
    
    if mountpoint -q "$MNT_REPACKED_ROOTFS"; then
        log_info "CLEANUP" "Unmounting repacked rootfs partition: $MNT_REPACKED_ROOTFS"
        umount "$MNT_REPACKED_ROOTFS" 2>/dev/null && log_success "CLEANUP" "Unmounted $MNT_REPACKED_ROOTFS" || log_warning "CLEANUP" "Failed to unmount $MNT_REPACKED_ROOTFS"
    fi
    
    if mountpoint -q "$MNT_SOURCE_BOOT"; then
        log_info "CLEANUP" "Unmounting source boot partition: $MNT_SOURCE_BOOT"
        umount "$MNT_SOURCE_BOOT" 2>/dev/null && log_success "CLEANUP" "Unmounted $MNT_SOURCE_BOOT" || log_warning "CLEANUP" "Failed to unmount $MNT_SOURCE_BOOT"
    fi

    if [ -n "$LOOP" ]; then
        log_info "CLEANUP" "Detaching loop device: $LOOP"
        losetup -d "$LOOP" 2>/dev/null && log_success "CLEANUP" "Detached $LOOP" || log_warning "CLEANUP" "Failed to detach $LOOP"
    fi
    
    if [ -n "$LOOP_ORIG" ]; then
        log_info "CLEANUP" "Detaching original image loop device: $LOOP_ORIG"
        losetup -d "$LOOP_ORIG" 2>/dev/null && log_success "CLEANUP" "Detached $LOOP_ORIG" || log_warning "CLEANUP" "Failed to detach $LOOP_ORIG"
    fi
    
    if [ -n "$LOOP_DEV" ]; then
        log_info "CLEANUP" "Detaching temporary loop device: $LOOP_DEV"
        losetup -d "$LOOP_DEV" 2>/dev/null && log_success "CLEANUP" "Detached $LOOP_DEV" || log_warning "CLEANUP" "Failed to detach $LOOP_DEV"
    fi

    if [ -d "$WORK_DIR" ]; then
        log_info "CLEANUP" "Removing work directory: $WORK_DIR"
        rm -rf "$WORK_DIR" 2>/dev/null && log_success "CLEANUP" "Removed $WORK_DIR" || log_warning "CLEANUP" "Failed to remove $WORK_DIR"
    fi
    
    log_success "CLEANUP" "Cleanup process completed"
}

trap 'cleanup; rm -f "$THEME"; log_info "TRAP" "Script terminated, trap executed"; clear' EXIT

ORIGINAL_IMAGES_DIR="./original-images"
REPACKED_IMAGES_DIR="./repacked-images"

BACKTITLE="Armbian Amlogic Image Repacker - UNOFFICIAL SCRIPT - by Fábio Haruo and Pedro Rigolin"

dialog_throw_error() {
    ERROR_MSG="$1"
    
    log_error "DIALOG" "Fatal error occurred: $ERROR_MSG"
    log_error "DIALOG" "Displaying error dialog to user"

    DIALOGRC="$THEME" dialog \
        --backtitle "$BACKTITLE" \
        --title "Error" \
        --ok-label "OK" \
        --msgbox "\n$ERROR_MSG" \
        10 60
    
    log_error "DIALOG" "Script terminating due to error"
    exit 1

}

dialog_assert_exit_status() {
    ERROR_MSG="$1"
    EXIT_STATUS="$?"
    
    log_debug "DIALOG" "Asserting exit status: $EXIT_STATUS"

    if [ "$EXIT_STATUS" -ne 0 ]; then
        log_error "DIALOG" "Exit status assertion failed: $EXIT_STATUS != 0"
        dialog_throw_error "$ERROR_MSG"
    fi
    
    log_debug "DIALOG" "Exit status assertion passed"

}

dialog_show_wait() {
    MESSAGE="$1"
    
    log_info "DIALOG" "Showing wait message to user: $MESSAGE"

    DIALOGRC="$THEME" dialog \
        --backtitle "$BACKTITLE" \
        --title "Please Wait" \
        --infobox "\n$MESSAGE" \
        5 60

}

assert_img_fs() {
    local IMG_PATH="$1"
    local EXPECTED_IMG_FSTYPE="$2"
    
    log_info "VALIDATE" "Validating filesystem on image: $IMG_PATH"
    log_var "VALIDATE" "EXPECTED_FSTYPE" "$EXPECTED_IMG_FSTYPE"
    
    log_cmd "VALIDATE" "losetup -fP --show $IMG_PATH"
    LOOP_DEV=$(losetup -fP --show "$IMG_PATH")
    log_var "VALIDATE" "LOOP_DEV" "$LOOP_DEV"

    local IMG_FSTYPE
    log_cmd "VALIDATE" "blkid -o value -s TYPE ${LOOP_DEV}p1"
    IMG_FSTYPE=$(blkid -o value -s TYPE "${LOOP_DEV}p1")
    log_var "VALIDATE" "DETECTED_FSTYPE" "${IMG_FSTYPE:-none}"

    log_cmd "VALIDATE" "losetup -d $LOOP_DEV"
    losetup -d "$LOOP_DEV"

    if [ "$IMG_FSTYPE" != "$EXPECTED_IMG_FSTYPE" ]; then
        log_error "VALIDATE" "Filesystem validation failed!"
        log_error "VALIDATE" "Expected: $EXPECTED_IMG_FSTYPE, Found: ${IMG_FSTYPE:-none}"
        dialog_throw_error "Error: expected filesystem '$EXPECTED_IMG_FSTYPE' on first partition but found '${IMG_FSTYPE:-none}'."
    fi
    
    log_success "VALIDATE" "Filesystem validation passed: $IMG_FSTYPE"

}

dialog_show_warning() {
    WARNING_MSG="$1"
    
    log_warning "DIALOG" "Displaying warning to user: $WARNING_MSG"
    
    DIALOGRC="$THEME" dialog \
        --backtitle "$BACKTITLE" \
        --title "⚠ Warning" \
        --ok-label "OK" \
        --colors \
        --msgbox "\n\Z3$WARNING_MSG\Zn" \
        10 60
    
    log_info "DIALOG" "User acknowledged warning"

}

log_section "DIRECTORY STRUCTURE CHECK"

if [ ! -d "$ORIGINAL_IMAGES_DIR" ]; then
    log_warning "DIRECTORIES" "Original images directory does not exist: $ORIGINAL_IMAGES_DIR"
    log_fs_op "DIRECTORIES" "CREATE" "$ORIGINAL_IMAGES_DIR" "Creating directory"

    mkdir -p "$ORIGINAL_IMAGES_DIR"

    log_error "DIRECTORIES" "Directory created but no images available"
    dialog_throw_error "The directory '$ORIGINAL_IMAGES_DIR' did not exist and was created.\nPlease add your Armbian .img files to it and run the script again."

else
    log_success "DIRECTORIES" "Original images directory exists: $ORIGINAL_IMAGES_DIR"
fi

if [ ! -d "$REPACKED_IMAGES_DIR" ]; then
    log_warning "DIRECTORIES" "Repacked images directory does not exist: $REPACKED_IMAGES_DIR"
    log_fs_op "DIRECTORIES" "CREATE" "$REPACKED_IMAGES_DIR" "Creating directory"
    mkdir -p "$REPACKED_IMAGES_DIR"
    log_success "DIRECTORIES" "Created repacked images directory"
else
    log_success "DIRECTORIES" "Repacked images directory exists: $REPACKED_IMAGES_DIR"
fi

log_section "IMAGE DISCOVERY"

# 2. Collect .img files into an array
# We use a glob and a loop to build the (Tag Description) pairs
OPTIONS=()

log_info "IMAGE_SCAN" "Scanning for .img files in $ORIGINAL_IMAGES_DIR"
log_cmd "IMAGE_SCAN" "find $ORIGINAL_IMAGES_DIR -maxdepth 1 -name '*.img' -print0"

while IFS= read -r -d $'\0' file; do

    FILENAME=$(basename "$file")
    log_debug "IMAGE_SCAN" "Found image file: $FILENAME"

    # Tag: filename | Description: size or path
    OPTIONS+=("$FILENAME" "Image file")

done < <(find "$ORIGINAL_IMAGES_DIR" -maxdepth 1 -name "*.img" -print0)

log_var "IMAGE_SCAN" "IMAGES_FOUND" "${#OPTIONS[@]}"
if [ ${#OPTIONS[@]} -gt 0 ]; then
    log_array "IMAGE_SCAN" "AVAILABLE_IMAGES" "${OPTIONS[@]}"
fi

# 3. Check if any images were found
if [ ${#OPTIONS[@]} -eq 0 ]; then
    log_error "IMAGE_SCAN" "No .img files found in directory"
    dialog_throw_error "No .img files found in '$ORIGINAL_IMAGES_DIR'. Please add some images and try again."
fi

log_success "IMAGE_SCAN" "Found $((${#OPTIONS[@]}/2)) image(s)"

log_section "USER IMAGE SELECTION"

# --- Improved Dialog Call ---
# Using 'echo -e' ensures newlines are handled correctly within the substitution
log_info "USER_INPUT" "Displaying image selection dialog to user"
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
log_var "USER_INPUT" "DIALOG_EXIT_STATUS" "$EXIT_STATUS"

if [ "$EXIT_STATUS" -ne 0 ]; then
    log_warning "USER_INPUT" "User cancelled image selection"
    echo "Selection cancelled."
    exit 0
fi

log_var "USER_INPUT" "SELECTED_IMAGE" "$IMAGE_NAME"
log_success "USER_INPUT" "User selected: $IMAGE_NAME"

ORIGINAL_IMAGE="$ORIGINAL_IMAGES_DIR/$IMAGE_NAME"
log_var "MAIN" "ORIGINAL_IMAGE_PATH" "$ORIGINAL_IMAGE"

log_section "IMAGE VALIDATION"

dialog_show_wait "Validating image file. Please wait..."

assert_img_fs "$ORIGINAL_IMAGE" "ext4"

log_section "BOOT PARTITION SIZE SELECTION"

# We are going to test if the image is valid by trying to read its partition table
# If it fails, we will show an error message and exit

log_info "USER_INPUT" "Displaying boot partition size selection dialog"
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
log_var "USER_INPUT" "DIALOG_EXIT_STATUS" "$EXIT_STATUS"

if [ "$EXIT_STATUS" -ne 0 ]; then
    log_warning "USER_INPUT" "User cancelled boot size selection"
    echo "Selection cancelled."
    exit 0
fi

log_var "USER_INPUT" "SELECTED_BOOT_SIZE" "$BOOT_SIZE"
log_success "USER_INPUT" "User selected boot size: $BOOT_SIZE"

log_section "IMAGE CREATION AND PARTITIONING"

dialog_show_wait "Creating new image file. Please wait..."

IMAGE="$REPACKED_IMAGES_DIR/repacked_$IMAGE_NAME"
log_var "MAIN" "OUTPUT_IMAGE_PATH" "$IMAGE"

log_cmd "IMAGE_CREATE" "stat -c%s $ORIGINAL_IMAGE"
ORIGINAL_SIZE=$(stat -c%s "$ORIGINAL_IMAGE")
log_var "IMAGE_CREATE" "ORIGINAL_SIZE_BYTES" "$ORIGINAL_SIZE"

log_info "IMAGE_CREATE" "Creating new image file with size: $ORIGINAL_SIZE bytes"
log_cmd "IMAGE_CREATE" "truncate -s $ORIGINAL_SIZE $IMAGE"
truncate -s "$ORIGINAL_SIZE" "$IMAGE"
dialog_assert_exit_status "Error creating the image file."
log_success "IMAGE_CREATE" "Image file created successfully"

dialog_show_wait "Creating partition table. Please wait..."

# Cria o particionamento MBR
log_info "PARTITION" "Creating MBR partition table"
log_cmd "PARTITION" "parted -s $IMAGE mklabel msdos"
parted -s "$IMAGE" mklabel msdos
dialog_assert_exit_status "Error in partitioning system."
log_success "PARTITION" "MBR partition table created"

# Partição 1: Boot FAT32 (256MB)
log_info "PARTITION" "Creating partition 1 (BOOT) with size: $BOOT_SIZE"
log_cmd "PARTITION" "parted -s $IMAGE mkpart primary fat32 1MiB $BOOT_SIZE"
parted -s "$IMAGE" mkpart primary fat32 1MiB "$BOOT_SIZE"
dialog_assert_exit_status "Error: cannot format system."
log_success "PARTITION" "Boot partition created (1MiB - $BOOT_SIZE)"

log_info "PARTITION" "Setting boot flag on partition 1"
log_cmd "PARTITION" "parted -s $IMAGE set 1 boot on"
parted -s "$IMAGE" set 1 boot on
dialog_assert_exit_status "Error: cannot set boot flag."
log_success "PARTITION" "Boot flag set on partition 1"

log_info "PARTITION" "Setting LBA flag on partition 1"
log_cmd "PARTITION" "parted -s $IMAGE set 1 lba on"
parted -s "$IMAGE" set 1 lba on
dialog_assert_exit_status "Error: cannot set LBA flag."
log_success "PARTITION" "LBA flag set on partition 1"

log_info "PARTITION" "Creating partition 2 (ROOTFS) from $BOOT_SIZE to 100%"
log_cmd "PARTITION" "parted -s $IMAGE mkpart primary ext4 $BOOT_SIZE 100%"
parted -s "$IMAGE" mkpart primary ext4 "$BOOT_SIZE" 100%
dialog_assert_exit_status "Error: cannot create ext4 partition"
log_success "PARTITION" "Root partition created ($BOOT_SIZE - 100%)"

log_section "LOOP DEVICE SETUP"

dialog_show_wait "Setting up loop devices. Please wait..."

log_info "LOOP_SETUP" "Setting up loop device for repacked image"
log_cmd "LOOP_SETUP" "losetup -fP --show $IMAGE"
LOOP=$(losetup -fP --show "$IMAGE")
dialog_assert_exit_status "Error: cannot setup loop device."
log_var "LOOP_SETUP" "LOOP" "$LOOP"
log_success "LOOP_SETUP" "Loop device attached: $LOOP"

log_info "LOOP_SETUP" "Setting up loop device for original image"
log_cmd "LOOP_SETUP" "losetup -fP --show $ORIGINAL_IMAGE"
LOOP_ORIG=$(losetup -fP --show "$ORIGINAL_IMAGE")
dialog_assert_exit_status "Error: cannot setup loop device for original image."
log_var "LOOP_SETUP" "LOOP_ORIG" "$LOOP_ORIG"
log_success "LOOP_SETUP" "Loop device attached: $LOOP_ORIG"

log_section "FILESYSTEM FORMATTING"

dialog_show_wait "Formatting partitions. Please wait..."

# Formata as partições novas
log_info "FORMAT" "Formatting boot partition as FAT32"
log_cmd "FORMAT" "mkfs.vfat -n BOOT ${LOOP}p1"
mkfs.vfat -n BOOT "${LOOP}p1" >/dev/null 2>&1
dialog_assert_exit_status "Error: cannot format boot partition."
log_success "FORMAT" "Boot partition formatted successfully (FAT32, label: BOOT)"

log_info "FORMAT" "Formatting rootfs partition as EXT4"
log_cmd "FORMAT" "mkfs.ext4 -L ROOTFS ${LOOP}p2"
mkfs.ext4 -L ROOTFS "${LOOP}p2" >/dev/null 2>&1
dialog_assert_exit_status "Error: cannot format rootfs partition."
log_success "FORMAT" "Rootfs partition formatted successfully (EXT4, label: ROOTFS)"

log_section "MOUNT OPERATIONS"

dialog_show_wait "Mounting partitions. Please wait..."

log_info "MOUNT" "Creating mount point directories"
log_cmd "MOUNT" "mkdir -p $MNT_REPACKED_BOOT $MNT_REPACKED_ROOTFS $MNT_SOURCE_BOOT"
mkdir -p "$MNT_REPACKED_BOOT" "$MNT_REPACKED_ROOTFS" "$MNT_SOURCE_BOOT"
dialog_assert_exit_status "Error: cannot create working directories."
log_success "MOUNT" "Mount directories created"

log_info "MOUNT" "Mounting repacked boot partition"
log_cmd "MOUNT" "mount ${LOOP}p1 $MNT_REPACKED_BOOT"
mount "${LOOP}p1" "$MNT_REPACKED_BOOT"
dialog_assert_exit_status "Error: cannot mount boot partition."
log_success "MOUNT" "Mounted ${LOOP}p1 -> $MNT_REPACKED_BOOT"

log_info "MOUNT" "Mounting repacked rootfs partition"
log_cmd "MOUNT" "mount ${LOOP}p2 $MNT_REPACKED_ROOTFS"
mount "${LOOP}p2" "$MNT_REPACKED_ROOTFS"
dialog_assert_exit_status "Error: cannot mount rootfs partition."
log_success "MOUNT" "Mounted ${LOOP}p2 -> $MNT_REPACKED_ROOTFS"

log_info "MOUNT" "Mounting original image boot partition"
log_cmd "MOUNT" "mount ${LOOP_ORIG}p1 $MNT_SOURCE_BOOT"
mount "${LOOP_ORIG}p1" "$MNT_SOURCE_BOOT"
dialog_assert_exit_status "Error: cannot mount original image boot partition."
log_success "MOUNT" "Mounted ${LOOP_ORIG}p1 -> $MNT_SOURCE_BOOT"

log_section "FILE COPY OPERATIONS"

dialog_show_wait "Copying boot files. This may take a few minutes..."

log_info "COPY" "Copying boot files from source to repacked boot partition"
log_debug "COPY" "Source: $MNT_SOURCE_BOOT/boot/"
log_debug "COPY" "Destination: $MNT_REPACKED_BOOT/"
log_cmd "COPY" "rsync -rltHL --no-owner --no-group --no-perms $MNT_SOURCE_BOOT/boot/ $MNT_REPACKED_BOOT/"
rsync -rltHL --no-owner --no-group --no-perms "$MNT_SOURCE_BOOT/boot/" "$MNT_REPACKED_BOOT/"
dialog_assert_exit_status "Error: cannot copy boot files."
log_success "COPY" "Boot files copied successfully"

dialog_show_wait "Copying root filesystem. This may take several minutes..."

log_info "COPY" "Copying rootfs files from source to repacked rootfs partition"
log_debug "COPY" "Source: $MNT_SOURCE_BOOT/"
log_debug "COPY" "Destination: $MNT_REPACKED_ROOTFS/"
log_cmd "COPY" "rsync -aAXH $MNT_SOURCE_BOOT/ $MNT_REPACKED_ROOTFS/"
rsync -aAXH "$MNT_SOURCE_BOOT/" "$MNT_REPACKED_ROOTFS/"
dialog_assert_exit_status "Error: cannot copy rootfs files."
log_success "COPY" "Rootfs files copied successfully"

dialog_show_wait "Cleaning up boot directory. Please wait..."

log_info "COPY" "Cleaning boot directory from rootfs"
log_cmd "COPY" "rm -rf ${MNT_REPACKED_ROOTFS}/boot/*"
rm -rf "${MNT_REPACKED_ROOTFS:?}/boot/"*
log_success "COPY" "Boot directory cleaned from rootfs"

log_section "UUID RETRIEVAL AND CONFIGURATION"

dialog_show_wait "Configuring boot settings. Please wait..."

log_info "UUID" "Retrieving UUIDs for new partitions"
log_cmd "UUID" "blkid -s UUID -o value ${LOOP}p1"
NEW_UUID_BOOT=$(blkid -s UUID -o value "$LOOP"p1)
log_var "UUID" "NEW_UUID_BOOT" "${NEW_UUID_BOOT:-<empty>}"

log_cmd "UUID" "blkid -s UUID -o value ${LOOP}p2"
NEW_UUID_ROOT=$(blkid -s UUID -o value "$LOOP"p2)
log_var "UUID" "NEW_UUID_ROOT" "${NEW_UUID_ROOT:-<empty>}"

if [ -z "$NEW_UUID_BOOT" ]; then
    log_warning "UUID" "BOOT partition UUID is empty or could not be retrieved"
    dialog_show_warning "Could not retrieve BOOT partition UUID.\n\nThe fstab file will not include the BOOT UUID, which may cause boot issues on some devices.\n\nPlease verify the image manually after repacking."

else
    log_success "UUID" "BOOT UUID retrieved successfully: $NEW_UUID_BOOT"
fi

if [ -z "$NEW_UUID_ROOT" ]; then
    log_error "UUID" "ROOT partition UUID is empty or could not be retrieved (CRITICAL)"
    dialog_show_warning "CRITICAL: Could not retrieve ROOT partition UUID!\n\narmbianEnv.txt and fstab cannot be updated.\n\nTHIS WILL CAUSE BOOT FAILURE!\n\nPlease check the UUID manually and fix the configuration files."

else
    log_success "UUID" "ROOT UUID retrieved successfully: $NEW_UUID_ROOT"

    ARMBIAN_ENV_FILE="$MNT_REPACKED_BOOT/armbianEnv.txt"
    log_var "CONFIG" "ARMBIAN_ENV_FILE" "$ARMBIAN_ENV_FILE"

    if [ -f "$ARMBIAN_ENV_FILE" ]; then
        log_info "CONFIG" "armbianEnv.txt found, updating with ROOT UUID"
        log_fs_op "CONFIG" "BACKUP" "$ARMBIAN_ENV_FILE" "Creating backup"

        cp "$ARMBIAN_ENV_FILE" "$MNT_REPACKED_BOOT/armbianEnv.txt.bak"
        log_success "CONFIG" "Backup created: armbianEnv.txt.bak"

        log_cmd "CONFIG" "sed -i '/^[[:space:]]*#*[[:space:]]*rootdev/d' $ARMBIAN_ENV_FILE"
        sed -i '/^[[:space:]]*#*[[:space:]]*rootdev/d' "$ARMBIAN_ENV_FILE"
        log_debug "CONFIG" "Removed old rootdev entries from armbianEnv.txt"

        log_cmd "CONFIG" "echo 'rootdev=UUID=$NEW_UUID_ROOT' >> $ARMBIAN_ENV_FILE"
        echo "rootdev=UUID=$NEW_UUID_ROOT" >>"$ARMBIAN_ENV_FILE"
        log_success "CONFIG" "Updated armbianEnv.txt with new ROOT UUID"

    else
        log_error "CONFIG" "armbianEnv.txt not found at expected location"
        dialog_show_warning "armbianEnv.txt not found in boot partition!\n\nThe system will not boot without this file.\n\nPlease create the file manually with:\nrootdev=UUID=$NEW_UUID_ROOT"

    fi

fi

log_section "FSTAB CONFIGURATION"

if [ -n "$NEW_UUID_BOOT" ] && [ -n "$NEW_UUID_ROOT" ]; then
    log_info "FSTAB" "Both UUIDs available, updating fstab"

    FSTAB_FILE="${MNT_REPACKED_ROOTFS:?}/etc/fstab"
    log_var "FSTAB" "FSTAB_FILE" "$FSTAB_FILE"

    if [ -f "$FSTAB_FILE" ]; then
        log_info "FSTAB" "fstab file found, creating new configuration"
        log_fs_op "FSTAB" "BACKUP" "$FSTAB_FILE" "Creating backup"

        cp "$FSTAB_FILE" "$FSTAB_FILE".bak
        log_success "FSTAB" "Backup created: fstab.bak"

        log_info "FSTAB" "Writing new fstab with updated UUIDs"
        echo "# <file system> <mount point> <type> <options> <dump> <pass>" >"$FSTAB_FILE"
        {
            echo "tmpfs /tmp tmpfs defaults, nosuid 0 0"
            echo "UUID=$NEW_UUID_ROOT / ext4 defaults,noatime,commit=600,errors=remount-ro 0 1"
            echo "UUID=$NEW_UUID_BOOT /boot vfat defaults,noatime,umask=0077 0 2"
        } >>"$FSTAB_FILE"
        log_success "FSTAB" "fstab updated successfully with:"
        log_debug "FSTAB" "  - ROOT UUID: $NEW_UUID_ROOT"
        log_debug "FSTAB" "  - BOOT UUID: $NEW_UUID_BOOT"

    else
        log_error "FSTAB" "fstab file not found at $FSTAB_FILE"
        dialog_show_warning "fstab file not found in /etc/fstab!\n\nThe system may not mount partitions correctly.\n\nPlease create a proper fstab file manually."

    fi

else
    log_warning "FSTAB" "One or both UUIDs missing, skipping fstab update"
    log_debug "FSTAB" "BOOT UUID present: $([[ -n \"$NEW_UUID_BOOT\" ]] && echo 'YES' || echo 'NO')"
    log_debug "FSTAB" "ROOT UUID present: $([[ -n \"$NEW_UUID_ROOT\" ]] && echo 'YES' || echo 'NO')"
fi

log_section "FINAL CLEANUP AND COMPLETION"

dialog_show_wait "Finalizing and cleaning up. Please wait..."

cleanup

log_info "COMPLETE" "Image repacking completed successfully!"
log_var "COMPLETE" "OUTPUT_IMAGE" "$IMAGE"
log_info "COMPLETE" "You can find your repacked image at: $IMAGE"

{
    echo ""
    echo "================================================================================"
    echo "  REPACKING SUMMARY"
    echo "================================================================================"
    echo "Original Image: $ORIGINAL_IMAGE"
    echo "Repacked Image: $IMAGE"
    echo "Boot Partition Size: $BOOT_SIZE"
    echo "Boot Partition UUID: ${NEW_UUID_BOOT:-N/A}"
    echo "Root Partition UUID: ${NEW_UUID_ROOT:-N/A}"
    echo "Session End: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "================================================================================"
    echo ""
} >>"$LOG_FILE"

log_success "COMPLETE" "All operations completed successfully!"
log_info "LOG_SYSTEM" "Detailed log saved to: $LOG_FILE"

DIALOGRC="$THEME" dialog \
    --backtitle "$BACKTITLE" \
    --title "Success" \
    --ok-label "OK" \
    --msgbox "\n\nImage repacked successfully!\n\nOutput file:\n$IMAGE\n\nBoot UUID: ${NEW_UUID_BOOT:-N/A}\nRoot UUID: ${NEW_UUID_ROOT:-N/A}" \
    12 70

exit 0
