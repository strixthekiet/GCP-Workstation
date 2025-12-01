#!/bin/bash
MOUNT_POINT=$1
DEVICE_NAME=$2
# The device ID is 'google-' + the device_name defined in Terraform
DISK_IDENTIFIER="/dev/disk/by-id/google-${DEVICE_NAME}" 

echo "Starting disk setup for ${DISK_IDENTIFIER}..."

# 1. Create the mount point
sudo mkdir -p "${MOUNT_POINT}"

# 2. Safety Check: Verify the disk is actually attached to the VM
if [ ! -e "${DISK_IDENTIFIER}" ]; then
    echo "ERROR: Disk device ${DISK_IDENTIFIER} not found."
    echo "Current disks:"
    ls -l /dev/disk/by-id/
    exit 1
fi

# 3. Format Check (Optional but recommended)
# Check if the disk has a filesystem. If not, format it (ext4).
# This prevents mounting errors on a brand new disk.
if ! sudo blkid "${DISK_IDENTIFIER}"; then
    echo "Disk appears unformatted. Formatting to ext4..."
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "${DISK_IDENTIFIER}"
fi

# 4. Update /etc/fstab
if ! grep -qs "${MOUNT_POINT}" /etc/fstab; then
    echo "Adding entry to /etc/fstab..."
    # using UUID is generally safer, but /dev/disk/by-id/ is fine in GCP
    echo "${DISK_IDENTIFIER} ${MOUNT_POINT} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
else
    echo "Entry already exists in /etc/fstab."
fi

# 5. Mount
echo "Mounting disk..."
sudo mount -a

# 6. VERIFICATION (Crucial Step)
# We check if the mount point is actually a mount point now
if mountpoint -q "${MOUNT_POINT}"; then
    echo "SUCCESS: Disk mounted at ${MOUNT_POINT}"
    # Only chown if the mount succeeded
    sudo chown -R ubuntu:ubuntu "${MOUNT_POINT}"
else
    echo "CRITICAL ERROR: Mount failed. Data will be written to Boot Disk!"
    exit 1
fi
