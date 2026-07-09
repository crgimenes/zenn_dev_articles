---
title: "暗号化コンテナで認証情報と設定ファイルを守る"
emoji: "🔒"
type: "tech"
topics: ["go", "security", "linux", "cryptsetup"]
published: true
---

I use a small pocket computer in my backpack. This device is used for testing and development, and it stores sensitive information such as credentials, passwords, and access keys. I don’t want this data to fall into the wrong hands. Unlike my laptop, which has an encrypted drive, my pocket computer’s drive isn’t encrypted. Drive-wide encryption consumes a lot of processing power and usually requires disabling SSD TRIM, which hurts performance.

To work around this, I decided to create an encrypted container to hold only my sensitive information. This container is mounted only when needed, increasing the overall security of the system.

## Creating an Encrypted Container

You need to install the `cryptsetup` package. To do this, run as root:

```bash
sudo apt install cryptsetup
```

Next, create the encrypted container. First, generate a 200MB file (as an example):

```bash
dd if=/dev/urandom of=secure_container.img bs=1M count=200
```

Initialize LUKS:

```bash
cryptsetup luksFormat secure_container.img
```

Open the container:

```bash
cryptsetup open secure_container.img secure_container
```

Format it (ext4 as an example):

```bash
mkfs.ext4 /dev/mapper/secure_container
```

Mount the container:

```bash
mkdir -p /mnt/secure_container
mount /dev/mapper/secure_container /mnt/secure_container
```

Now the `/mnt/secure_container` directory is ready to use. You can move your sensitive files there and create symbolic links (for example, from the `~/.ssh` directory or AWS access keys in `~/.aws`).

## Unmounting the Container

To unmount, unmount the directory and close the container:

```bash
umount /mnt/secure_container
cryptsetup close secure_container
```

## Automating Mount and Unmount

Since mounting and unmounting the container is repetitive, it’s worth creating scripts to automate this task. These scripts need root privileges to work. You can configure sudo so it doesn’t ask for a password when running them, making the process easier.

### Mount Script (`mount_secure_container.sh`)

```bash
#!/bin/sh

[ "root" != "$USER" ] && exec sudo $0 "$@"

# Example paths
IMAGE_PATH="/home/user/secure_container.img"
MAPPER_NAME="secure_container"
MOUNT_POINT="/mnt/secure_container"

# Open the container.
cryptsetup open "$IMAGE_PATH" "$MAPPER_NAME" || {
    echo "Failed to open the container."
    exit 1
}

# Mount the container.
mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT" || {
    echo "Failed to mount the container."
    cryptsetup close "$MAPPER_NAME"
    exit 1
}

echo "Container mounted at: $MOUNT_POINT"
exit 0
```

### Unmount Script (`umount_secure_container.sh`)

```bash
#!/bin/sh

[ "root" != "$USER" ] && exec sudo $0 "$@"

IMAGE_PATH="/home/user/secure_container.img"
MAPPER_NAME="secure_container"
MOUNT_POINT="/mnt/secure_container"

# Unmount the container.
umount "$MOUNT_POINT" || {
    echo "Failed to unmount. Make sure no files are still in use."
    exit 1
}

# Close the container.
cryptsetup close "$MAPPER_NAME" || {
    echo "Failed to close the LUKS container."
    exit 1
}

echo "Container unmounted and closed."
exit 0
```

### Shutdown Script (`off`)

Create a script named `off` to ensure the container is unmounted before shutting down:

```bash
#!/bin/sh

[ "root" != "$USER" ] && exec sudo $0 "$@"

sync
/home/user/bin/umount_encrypted.sh
poweroff
```

Then configure sudo so it doesn’t request a password for these scripts:

```bash
sudo visudo
```

Add the following lines:

```bash
user ALL=(ALL) NOPASSWD: /home/user/bin/mount_encrypted.sh
user ALL=(ALL) NOPASSWD: /home/user/bin/umount_encrypted.sh
user ALL=(ALL) NOPASSWD: /home/user/bin/off
```

Remember to replace `user` in the scripts with your actual username.

## Conclusion

This method keeps sensitive data secure and accessible only when needed. The encrypted container simplifies backups and makes it easy to transfer to another computer. In this way, you combine security and convenience in your system.

[Cesar Gimenes](https://crg.eti.br/en/cesar-gimenes)
