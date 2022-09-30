#! /bin/bash

#########################
##
##	TODO: DESCRIPTION
##

Info() {
    echo "Error: Invalid option"
    echo "Type $0 -h for more information"
}

Help() {
    echo "TODO Add description..."
    echo
    echo "Syntax: $0 [-h|c]"
    echo "options:"
    echo "h	print this help"
    echo "c	delete all debugging related files"
    echo
}

Clear() {
    echo "Deleting files..."
    rm -rf hda-contents
    rm -f debug.log
    rm -f gdbscript
    rm -f QemuKill
    make clean
    rm -f OVMF.fd
    rm -f OVMF_VARS.fd
    rm -f OVMF_CODE.fd
}

while getopts ":hc" option; do

    case $option in
        h) # display Help
	    Help
	    exit;;
	c) # clear directory
	    Clear
	    exit;;
       \?) # invalid option
	    Info
	    exit;;
    esac

done


QEMU="qemu-system-x86_64"
QEMU_FLAGS=" -bios OVMF.fd"
QEMU_FLAGS+=" -hda fat:rw:hda-contents -net none"
QEMU_FLAGS+=" -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd"
QEMU_FLAGS+=" -drive if=pflash,format=raw,file=OVMF_VARS.fd"

GDB_FILE="gdbscript"

# Check if QEMU and OVMF is installed
if ! dpkg -l qemu-system* > /dev/null 2>&1; then
    echo "Qemu not installed"
    exit 1
fi

if ! dpkg -l ovmf > /dev/null 2>&1; then
    echo "Package ovmf not installed. Type 'sudo apt install ovmf'"
    exit 1
fi

# Copy OVMF* files from /usr/share
if [ ! -f OVMF.fd ] || [ ! -f OVMF_VARS.fd ] || [ ! -f OVMF_CODE.fd ]
then
  cp /usr/share/ovmf/OVMF.fd .
  cp /usr/share/OVMF/OVMF_CODE.fd .
  cp /usr/share/OVMF/OVMF_VARS.fd .
fi

Make() {
    make debug DEBUG_S=1 DEBUG_OPT=0
    ret_val=$?

    if [[ $ret_val -ne 0 ]] ; then
    	echo "Make failed with return value: $ret_val"
    	exit 1
    fi
}

# Define offsets for loading of symbol-table
IMAGEBASE=0x200000
BASEOFCODE=0x1000
RELOCADDR=0x400000

# Retrieve addresses from code (not used in this version)
Get_Offsets() {
    IMAGEBASE=$(grep -P '#define\tIMAGE_BASE' header.S | cut -f3)
    BASEOFCODE=$(grep -P '#deinfe\tBASE_OF_CODE' header.S | cut -f3)

    # TODO: get RELOCADDR
}

printf -v OFFSET "0x%X" $(($IMAGEBASE + $BASEOFCODE))

# Build
Make

# Create dir hda-contents
mkdir -p hda-contents/EFI/boot

# Copy memtest.efi to hda-contents
cp memtest.efi hda-contents/
cp memtest.efi hda-contents/EFI/boot/BOOT_X64.efi

# TODO Check if gdbscript exists - then do not create it

if [ ! -f $GDB_FILE ]
then
    echo "Creating gdbscript.."

    echo "set pagination off" > $GDB_FILE

    echo "add-symbol-file memtest.debug $OFFSET" >> $GDB_FILE
    echo "add-symbol-file memtest.debug $RELOCADDR" >> $GDB_FILE

    echo "b main" >> $GDB_FILE
    echo "commands" >> $GDB_FILE
    echo "layout src" >> $GDB_FILE
    echo "delete 1" >> $GDB_FILE
    echo "end" >> $GDB_FILE

    echo "b run_at" >> $GDB_FILE

    echo "shell sleep 0.5" >> $GDB_FILE # TODO remove if time is enough until qemu starts
    echo "target remote localhost:1234" >> $GDB_FILE
    echo "info b" >> $GDB_FILE
    echo "c" >> $GDB_FILE

fi

# Run QEMU and launch second terminal,
# wait for connection via gdb
gnome-terminal -- gdb -x $GDB_FILE &
$QEMU $QEMU_FLAGS -s -S

# TODO: Quit when gdb quits?
