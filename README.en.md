# Armbian Amlogic Image Repacker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell_Script-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Armbian](https://img.shields.io/badge/Armbian-Focused-orange.svg)](https://www.armbian.com/)
[![AMLogic](https://img.shields.io/badge/AMLogic-S905X%2FX2%2FX3-blue.svg)](https://en.wikipedia.org/wiki/Amlogic)
[![Version](https://img.shields.io/badge/Version-1.0-informational.svg)]()

> **Language / Idioma:** **[🟢 English]** | [Português](README.md)

An interactive script to repack Armbian images from single-partition (ext4) to the dual-partition format (FAT32 + ext4) required by most AMLogic TV Boxes to boot.

**Authors:** [Pedro Rigolin](https://github.com/pedrohrigolin) and [Fábio Haruo](https://github.com/Haruo09)

**Project:** Developed for the [Projeto TVBox](https://github.com/projetotvbox) at the **Instituto Federal de São Paulo (IFSP)**, Campus Salto

---

## 📑 Table of Contents

- [📦 About Projeto TVBox](#-about-projeto-tvbox)
- [🔍 Overview](#-overview)
  - [🎯 The Problem and the Solution](#-the-problem-and-the-solution)
  - [✨ Features](#-features)
- [⚙️ Requirements](#️-requirements)
  - [Hardware](#hardware)
  - [Operating System](#operating-system)
  - [Dependencies](#dependencies)
  - [Disk Space](#disk-space)
- [🚀 How to Use](#-how-to-use)
  - [Directory Structure](#directory-structure)
  - [Running the Script](#running-the-script)
  - [Operation Flow](#operation-flow)
- [🔧 Technical Details](#-technical-details)
  - [Partition Layout](#partition-layout)
  - [Automatically Configured Files](#automatically-configured-files)
- [⚠️ Notes on Image Size](#️-notes-on-image-size)
  - [Why the Size is Preserved](#why-the-size-is-preserved)
  - [How to Check Available Space](#how-to-check-available-space)
  - [How to Resize if Needed](#how-to-resize-if-needed)
- [📋 Logs](#-logs)
- [🔧 Troubleshooting](#-troubleshooting)
- [👥 Contributors](#-contributors)
- [📄 License](#-license)
- [⚠️ Disclaimer](#️-disclaimer)

---

## 📦 About Projeto TVBox

This script was developed as part of the **Projeto TVBox at IFSP Campus Salto**, an initiative aimed at repurposing TV Box devices seized by the Brazilian Federal Revenue Service.

The project reconfigures these devices, transforming them into **functional mini PCs** running Linux, providing:

- Reuse of hardware that would otherwise be discarded
- Digital inclusion through donations to communities
- Reduction of environmental impact (e-waste)
- Technical training for students

---

## 🔍 Overview

### 🎯 The Problem and the Solution

Official **Armbian** images use a **single ext4 partition** by default. However, the vast majority of AMLogic TV Boxes (SoCs S905X/X2/X3/X4) require **dual-partition** layout to boot correctly:

```
Partition 1: BOOT (FAT32) → Kernel, DTB, boot scripts
Partition 2: ROOTFS (ext4) → Root filesystem
```

Performing this conversion manually is a tedious and error-prone process. This script **fully automates** it, providing an interactive TUI that guides the user through every step.

### ✨ Features

- ✅ **Interactive interface** with `dialog` menus (TUI)
- ✅ **Image selection** via menu, with support for multiple `.img` files
- ✅ **Boot partition size selection** (256 MiB or 512 MiB)
- ✅ **Automatic partition formatting** (FAT32 and EXT4)
- ✅ **File copy and reorganization** of boot and rootfs contents
- ✅ **Automatic update** of `armbianEnv.txt` and `fstab` with new UUIDs
- ✅ **Detailed logging** of the entire execution to `./logs/`
- ✅ **Automatic cleanup** on error or interruption (unmounts partitions, detaches loop devices)
- ✅ **Dependency check** before starting

---

## ⚙️ Requirements

### Hardware

| Component | Requirement |
|-----------|-------------|
| RAM | ≥ 8 GB |
| Architecture | x86_64, aarch64, or riscv64 |
| Disk space | ≥ 2.5× the size of the original image |

### Operating System

The script was developed and tested on **Debian/Ubuntu** environments and is recommended for use on these distributions. It may work on other Linux distros, but without guarantees.

System requirements follow those of Armbian itself. Since these requirements may be updated by the Armbian team, always check the latest official documentation:

> 📖 **[Official Armbian Build Framework Requirements](https://docs.armbian.com/Developer-Guide_Build-Preparation/)**

For reference, the currently known requirements are:

| Environment | System |
|-------------|--------|
| Native build | Armbian or Ubuntu 24.04 (Noble) |
| Containerized | Any Docker-capable Linux |
| Windows | WSL2 with Armbian/Ubuntu 24.04 |

> ⚠️ **Note:** These requirements may change as Armbian evolves. Always verify the official documentation when in doubt.

### Dependencies

The script automatically checks for the presence of the following tools before executing. Install them if missing:

| Binary | Description |
|--------|-------------|
| `parted` | Disk partitioning |
| `dialog` | TUI interface |
| `mkfs.vfat` | FAT32 formatting (`dosfstools` package) |
| `mkfs.ext4` | EXT4 formatting (`e2fsprogs` package) |
| `rsync` | File copy with attribute preservation |
| `blkid` | Partition UUID reading |
| `losetup` | Loop device management |
| `pv` | Progress monitoring |

**Installation on Debian/Ubuntu:**

```bash
sudo apt install parted dialog dosfstools e2fsprogs rsync util-linux pv
```

**Installation on Arch Linux:**

```bash
sudo pacman -S parted dialog dosfstools e2fsprogs rsync util-linux pv
```

**Installation on Fedora/RHEL:**

```bash
sudo dnf install parted dialog dosfstools e2fsprogs rsync util-linux pv
```

### Disk Space

The script creates a full copy of the original image. It is recommended to have at least **2.5× the size of the original image** available on disk to accommodate the original image, the repacked image, and temporary working files.

Example: for a 4 GB image, have at least 10 GB free.

---

## 🚀 How to Use

### Directory Structure

Before running, the repository should have the following structure:

```
armbian-amlogic-image-repacker/
├── armbian-amlogic-image-repacker.sh
├── original-images/          ← Place your .img files here
│   └── your-armbian-image.img
├── repacked-images/          ← Repacked images will be saved here
└── logs/                     ← Execution logs
```

> 💡 The `original-images/` and `repacked-images/` directories are created automatically by the script if they do not exist.

### Running the Script

```bash
# Clone the repository
git clone https://github.com/projetotvbox/armbian-amlogic-image-repacker.git
cd armbian-amlogic-image-repacker

# Place your Armbian image (.img) in original-images/
cp /path/to/your-image.img original-images/

# Run as root
sudo bash armbian-amlogic-image-repacker.sh
```

### Operation Flow

1. **Dependency check** — the script confirms all required tools are available
2. **Image selection** — interactive menu lists all `.img` files found in `original-images/`
3. **Image validation** — confirms the selected image has an ext4 filesystem (standard Armbian image)
4. **Boot size selection** — choose between 256 MiB and 512 MiB for the FAT32 partition
5. **New image creation** — creates an image file with the same size as the original
6. **Partitioning** — creates the MBR partition table with two partitions (FAT32 + ext4)
7. **Formatting** — formats the partitions with labels `BOOT` and `ROOTFS`
8. **File copy** — distributes files from the original image into the correct partitions
9. **Configuration update** — updates `armbianEnv.txt` and `fstab` with the new UUIDs
10. **Finalization** — unmounts everything, removes temporary files, and displays the result

The repacked image is saved to `repacked-images/repacked_<original-name>.img`.

---

## 🔧 Technical Details

### Partition Layout

| Partition | Type | Label | Start | End | Contents |
|-----------|------|-------|-------|-----|----------|
| p1 | FAT32 | `BOOT` | 1 MiB | 256 MiB or 512 MiB | Kernel, DTBs, `armbianEnv.txt`, boot scripts |
| p2 | EXT4 | `ROOTFS` | End of p1 | 100% | Full root filesystem |

The partition table used is **MBR (msdos)**, with the `boot` and `lba` flags active on partition 1, as required by most AMLogic bootloaders.

### About the Space Before the First Partition (MBR Gap)

When inspecting the repacked image, you will notice that the first partition starts at sector 2048 (1 MiB offset), while the original Armbian image may start at sector 8192 or another larger offset. This difference is **intentional and not a problem**.

On conventional architectures, the space between the MBR and the start of the first partition (known as the "MBR gap" or "embedding area") is used to store the first-stage U-Boot (SPL — Secondary Program Loader). In this case, the bootloader is loaded directly from the boot device (SD card or USB drive).

**On AMLogic TV Boxes, this mechanism is not used.** The U-Boot is permanently embedded in the device's internal eMMC memory from the factory. When the device is powered on, the eMMC U-Boot takes control — it does not read or depend on the space preceding the first partition of the USB drive or SD card. That space is simply ignored.

What AMLogic TV Box U-Boot actually looks for is the content of the **FAT32 partition**: boot scripts such as `s905_autoscript`, `aml_autoscript`, or `boot.ini`, which instruct the bootloader on how to load the kernel. These are exactly the files that the script copies to the `BOOT` partition during repacking.

> 💡 **Script scope:** This script does not intend to preserve or manipulate the MBR gap of the original image. Chainload techniques, autoscripts, and any device-specific boot configuration should be applied **after** repacking, directly on the FAT32 partition of the resulting image.
>
> 📂 **Autoscripts:** Projeto TVBox maintains a fork of the autoscripts originally developed by [devmfc](https://github.com/devmfc), adapted for use with Armbian on AMLogic devices. If you need ready-to-use boot autoscripts, visit: [projetotvbox/amlogic-bootscripts-Armbian](https://github.com/projetotvbox/amlogic-bootscripts-Armbian)

### Automatically Configured Files

**`armbianEnv.txt`** (BOOT partition):

The script removes any existing `rootdev` entry and inserts the correct entry with the UUID of the new rootfs partition:

```
rootdev=UUID=<new-rootfs-uuid>
```

**`/etc/fstab`** (ROOTFS partition):

The fstab is rewritten with the correct entries for the new layout:

```
# <file system>  <mount point>  <type>  <options>                                  <dump>  <pass>
tmpfs            /tmp           tmpfs   defaults,nosuid                            0       0
UUID=<rootfs>    /              ext4    defaults,noatime,commit=600,errors=remount-ro  0   1
UUID=<boot>      /boot          vfat    defaults,noatime,umask=0077                0       2
```

---

## ⚠️ Notes on Image Size

### Why the Size is Preserved

The script creates the repacked image with **exactly the same size** as the original. This is intentional: official Armbian images already include enough unallocated space to accommodate the FAT32 boot partition (up to 512 MiB) without needing to increase the total image size.

In practice, **you do not need to worry about space** when using official Armbian images. The repacking will not overflow the image size.

### How to Check Available Space

If you want to confirm there is enough space before repacking — for example, when using a custom or trimmed-down image — follow the steps below.

**1. Check the total size and partition layout of the original image:**

```bash
parted your-image.img unit MiB print
```

Example output for a standard Armbian image:

```
Model:  (file)
Disk /path/to/your-image.img: 3932 MiB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start    End      Size     Type     File system  Flags
 1      1.00MiB  3931MiB  3930MiB  primary  ext4
```

**2. Calculate the space available for the new boot partition:**

To see how much space is actually used by the filesystem:

```bash
# Attach the image as a loop device
sudo losetup -fP --show your-image.img
# Example: returns /dev/loop0

# Check actual filesystem usage
sudo df -h /dev/loop0p1
# or
sudo dumpe2fs -h /dev/loop0p1 | grep -E "Block count|Free blocks|Block size"

# Detach when done
sudo losetup -d /dev/loop0
```

If the difference between the total image size and the used content is greater than the boot size you want to create (256 MiB or 512 MiB), repacking will work without issues.

### How to Resize if Needed

If the image is too compact and does not have enough space for the boot partition, you need to increase the image size before repacking. There are two approaches:

**Option A — `qemu-img` (recommended, safer):**

```bash
# Increase the image by 512 MiB (adjust as needed)
qemu-img resize your-image.img +512M
```

> ⚠️ `qemu-img resize` only increases the image file. The additional space remains unallocated and will be available for partitioning by the script.

**Option B — `truncate` (simpler alternative):**

```bash
# Check the current size in bytes
stat -c%s your-image.img

# Increase to a specific size (example: 5 GiB)
truncate -s 5G your-image.img
```

> ⚠️ Using `truncate` with a larger size only extends the file; it does not corrupt existing data. Never use `truncate` to *shrink* an image.

**Verifying after resizing:**

```bash
parted your-image.img unit MiB print
```

Confirm that the total image size is now sufficient for the existing data plus the desired boot partition.

---

## 📋 Logs

Each execution generates a detailed log in `./logs/`, with the format:

```
logs/armbian-repacker_YYYYMMDD_HHMMSS.log
```

The log records all operations performed, including executed commands, variable values, state transitions, and errors. The **10 most recent logs** are kept; older ones are removed automatically.

---

## 🔧 Troubleshooting

### "Missing required binaries"

The script detected that one or more dependencies are not installed. Install the corresponding packages as described in the [Dependencies](#dependencies) section and run again.

### "No .img files found"

No `.img` file was found in `original-images/`. Make sure:
- The file was copied to the correct directory
- The file has the `.img` extension (not `.img.gz` or another compressed format)

If the image is compressed (`.img.xz`, `.img.gz`), decompress it first:

```bash
# For .img.xz (common Armbian format)
xz -d your-image.img.xz

# For .img.gz
gunzip your-image.img.gz
```

### "Error: expected filesystem 'ext4'"

The selected image does not have ext4 on its first partition. This script is designed for standard Armbian images (single partition ext4). Make sure you are using the correct image.

### The repacked image does not boot

Check:
1. Whether `armbianEnv.txt` was updated correctly — the `rootdev` UUID must match the UUID of the rootfs partition of the repacked image
2. Whether `/etc/fstab` was updated — the UUIDs must match the new partitions
3. The execution log in `./logs/` to identify any error during the process

To check the UUIDs of the repacked image:

```bash
sudo losetup -fP --show repacked-images/repacked_your-image.img
# Example: returns /dev/loop0

sudo blkid /dev/loop0p1 /dev/loop0p2

sudo losetup -d /dev/loop0
```

### Loop device not released after an error

In case of abrupt interruption, there may be orphaned loop devices. List and remove them manually:

```bash
# List all loop devices in use
sudo losetup -a

# Remove a specific one
sudo losetup -d /dev/loopX
```

---

## 👥 Contributors

### Authors

- **[Pedro Rigolin](https://github.com/pedrohrigolin)** — Core development
- **[Fábio Haruo](https://github.com/Haruo09)** — Core development

### How to Contribute

Contributions are welcome! You can:

- 🐛 **Report bugs** by opening an issue
- 📝 **Improve documentation**
- 💻 **Contribute code** via pull request

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2026 Pedro Rigolin, Fábio Haruo

Developed for Projeto TVBox - Instituto Federal de São Paulo (IFSP), Campus Salto
```

See the [LICENSE](LICENSE) file for more details.

---

## ⚠️ Disclaimer

⚠️ **USE AT YOUR OWN RISK**

This script manipulates disk images and performs partitioning and formatting operations. Although it operates on image files (not directly on physical disks), always:

- Keep a backup of the original image before repacking
- Verify that you have sufficient disk space before running
- Run only as root, in a controlled environment

The authors are not responsible for data loss or corrupted images resulting from the use of this script.

---

*Made with 🐧 at IFSP Salto · Technology in service of public education*
