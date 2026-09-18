---
title: "コマンドラインで扱うヘッドレスVirtualBox"
emoji: "🖥️"
type: "tech"
topics: ["virtualbox", "debian", "linux", "cli"]
published: true
---

**WIP - This text is a work in progress. I haven't documented all the examples I wanted to yet, nor have I reviewed the text. Contributions are welcome.**

Continuing with the project of building a machine *cluster*, I'm going to need some kind of virtualization system, because not all of the experiments I want to run can be done with containers alone. I did a few tests with [QEMU](https://www.qemu.org), but for now it's more practical to *stick* with [VirtualBox](https://www.virtualbox.org).

All access to the *cluster* is over ssh, so I need to control VirtualBox from the command line using the *VBoxManage* utility.

## Installation

Since I use Debian Stable on the servers, installing the latest version of VirtualBox requires the [Debian Fasttrack](https://fasttrack.debian.net) repository, as described on the Debian site.

This is a summary of the installation.

```bash
apt install fasttrack-archive-keyring
```

Add the following lines to the `/etc/apt/sources.list` file. (remember to check the release name)

```
deb https://fasttrack.debian.net/debian-fasttrack/ bullseye-fasttrack main contrib
deb https://fasttrack.debian.net/debian-fasttrack/ bullseye-backports-staging main contrib
```

Then install it as usual.

```bash
apt update
apt upgrade
apt install virtualbox virtualbox-ext-pack
```

There are several other packages that may be useful; look for them with the `apt search virtualbox` command.


## Creating a VM

```bash
VM_NAME="Nome_da_VM"
VBoxManage createvm \
--name $NAME_VM \
--ostype Debian_64 \
--register
```

Adjusting the CPU

```bash
VBoxManage modifyvm $NAME_VM \
--cpus 2 \
--cpuexecutioncap 50 \
--memory 2048 \
--vram 12
```

Adjusting the memory

```bash
VBoxManage modifyvm $NAME_VM \
--memory 2048 \
--vram 12
```

Assigning a network interface

```bash
VBoxManage modifyvm $NAME_VM \
--nic1 bridged \
--bridgeadapter1 eno1
```

### Creating a virtual disk

```bash
VBoxManage createhd \
--filename $NAME_VM.vdi \
--size 5120 \
--variant Standard
```

Attaching a SATA controller to the VM

```bash
VBoxManage storagectl $NAME_VM \
--name "SATA Controller" \
--add sata \
--bootable on
```

Attaching the virtual disk to the controller

```bash
VBoxManage storageattach $NAME_VM \
--storagectl "SATA Controller" \
--port 0 \
--device 0 \
--type hdd \
--medium $NAME_VM.vdi
```

Attaching an IDE controller to the VM

```bash
VBoxManage storagectl $NAME_VM \
--name "IDE Controller" \
--add ide
VBoxManage storageattach $NAME_VM \
--storagectl "IDE Controller" \
--port 0 \
--device 0 \
--type dvddrive \
--medium imagem.iso
```

Attaching the host's DVD drive to the VM

```bash
VBoxManage storageattach $NAME_VM \
--storagectl "IDE Controller" \
--port 0 \
--device 0 \
--type dvddrive \
--medium host:/dev/dvd
```

Removing media

```bash
VBoxManage storageattach $NAME_VM \
--storagectl "IDE Controller" \
--port 0 \
--device 0 \
--type dvddrive \
--medium none
```

## Enabling VRDE (RDP)

The VirtualBox Remote Display Protocol (VRDP) is compatible with the Remote Desktop Protocol (RDP) created by Microsoft, and it's useful mainly at the start of the client machine's installation process.

You can modify the virtual machine to enable RDP automatically with the `--vrde on` parameter, or you can pass the same parameter when you start the VM.

```bash
VBoxManage modifyvm $NAME_VM --vrde on
```

There are a few authentication modes available for RDP; I prefer the `external` mode. This way the system uses the *host* user's account and password to authenticate over RDP.

```bash
VBoxManage modifyvm $NAME_VM --vrdeauthtype external
```

---

Listing operating system types

```bash
VBoxManage list ostypes
```

## Getting information

Show the information for a VM

```bash
VBoxManage showvminfo $NAME_VM
```

Listing VMs

```bash
VBoxManage list vms
```

Starting the VM

```bash
VBoxManage startvm $NAME_VM \
--type headless
```

When the machine starts, the simplest way to connect to it during the first few accesses — while you still haven't set a name for the machine or set up any [Zero Configuration Networking](https://crg.eti.br/en/pub/zero-configuration-network-no-debian/) system — is to get the MAC address with the `showvminfo` command and use it to find the VM's IP on the network.


```bash
VBoxManage showvminfo $NAME_VM
ip neighbor |tr '[:lower:]' '[:upper:]' |grep "XX:XX:XX:XX:XX:XX"
```

Listing running VMs

```bash
VBoxManage list runningvms
```

Listing VMs in *long* mode

```bash
VBoxManage list -l runningvms
```

Removing a VM

```bash
VBoxManage unregistervm --delete $NAME_VM
```

## Shutting down the VM

Besides *poweroff*, we can also use *pause*, *resume*, *reset*, and several other commands.

```bash
VBoxManage controlvm $NAME_VM poweroff
```

## Exporting and importing the VM

```bash
VBoxManage export $NAME_VM -o $NAME_VM.ova 
```

```bash
VBoxManage import $NAME_VM.ova
```

There are many other useful options and parameters in VBoxManage; you can check them out in [chapter 8 of the VirtualBox documentation](https://www.virtualbox.org/manual/ch08.html).
