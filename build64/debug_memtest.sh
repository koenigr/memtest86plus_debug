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
	echo "t ..." # TODO
	echo
}

Terminal_Help() {
	echo "No terminal recognized. Please install x-terminal-emulator or gnome-terminal."
	echo "Alternatively you can define your own terminal inclusive its execution command via:"
	echo "./debug_script.sh -t \"<terminal> <execution_command>\""
	echo "See following examples:"
	echo "./debug_script.sh -t \"x-terminal-emulator -e \""
	echo "./debug_script.sh -t \"gnome-terminal --  \""
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
    rm -f memtest_shared_debug.lds
}

while getopts ":hct:" option; do

	case $option in
		h) # display Help
			Help
			exit;;
		c) # clear directory
			Clear
			exit;;
		t) # define own terminal
			echo "argument -t called with parameter $OPTARG" >&2
            if [ $OPTARG = "help" ]; then
                Terminal_Help
                exit 0
            fi
			TERMINAL="$OPTARG"
			if ! $TERMINAL ls; then
				echo "Your entered command is not valid. Please check it again"
                echo "Or type \"./debug_memtest.sh -t help\" for help"
				exit 1
			fi
			exit;;
        \?) # invalid option
            Info
            exit;;
	esac

done

Check() {
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
	if [ ! -f OVMF.fd ] || [ ! -f OVMF_VARS.fd ] || [ ! -f OVMF_CODE.fd ]; then
		cp /usr/share/ovmf/OVMF.fd .
		cp /usr/share/OVMF/OVMF_CODE.fd .
		cp /usr/share/OVMF/OVMF_VARS.fd .
	fi

	# Check for various terminals
	# TODO do not define TERMINAL if already defined by commandline
	if command -v x-terminal-emulator &> /dev/null; then
		echo "x-terminal-emulator found"
		TERMINAL="x-terminal-emulator -e "
	elif command -v gnome-terminal &> /dev/null; then
		echo "gnome-terminal found"
		TERMINAL="gnome-terminal -- "
	elif command -v xterm &> /dev/null; then
		echo "xterm found"
		TERMINAL="xterm -e "
	else
		Terminal_Help
		exit 1
	fi
}

	# Check for various terminals. Do not define TERMINAL if already defined by commandline
	if [ -z $TERMINAL ]; then
		if command -v x-terminal-emulator &> /dev/null; then
			echo "x-terminal-emulator found"
			TERMINAL="x-terminal-emulator -e "
		elif command -v gnome-terminal &> /dev/null; then
			echo "gnome-terminal found"
			TERMINAL="gnome-terminal -- "
		elif command -v xterm &> /dev/null; then
			echo "xterm found"
			TERMINAL="xterm -e "
		else
            echo "No terminal recognized. Please install x-terminal-emulator or gnome-terminal or xterm."
            echo "Or define your own terminal alternatively."
			Terminal_Help
			exit 1
		fi
	fi
}

Make() {
	make debug DEBUG=1
	ret_val=$?

	if [[ $ret_val -ne 0 ]] ; then
		echo "Make failed with return value: $ret_val"
		exit 1
	fi
}


# Retrieve addresses from code (not used in this version)
# Get_Offsets() {
# IMAGEBASE=$(grep -P '#define\tIMAGE_BASE' header.S | cut -f3)
# BASEOFCODE=$(grep -P '#deinfe\tBASE_OF_CODE' header.S | cut -f3)

# TODO: get RELOCADDR
# }

Init() {

	QEMU="qemu-system-x86_64"
	QEMU_FLAGS=" -bios OVMF.fd"
	QEMU_FLAGS+=" -hda fat:rw:hda-contents -net none"
	QEMU_FLAGS+=" -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd"
	QEMU_FLAGS+=" -drive if=pflash,format=raw,file=OVMF_VARS.fd"

	GDB_FILE="gdbscript"
    # TODO Check if gdbscript exists - if yes do not create it
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

	# Define offsets for loading of symbol-table
	IMAGEBASE=0x200000
	BASEOFCODE=0x1000
	RELOCADDR=0x400000

	printf -v OFFSET "0x%X" $(($IMAGEBASE + $BASEOFCODE))

	sed '/DISCARD/d' ldscripts/memtest_shared.lds > memtest_shared_debug.lds

}

Prepare_Directory() {
    # Create dir hda-contents
    mkdir -p hda-contents/EFI/boot

    # Copy memtest.efi to hda-contents
    cp memtest.efi hda-contents/
    cp memtest.efi hda-contents/EFI/boot/BOOT_X64.efi
}

# Global checks
Check

# Initialize
Init

# Build
Make

# Create needed directories and move efi binary to appropriate location
Prepare_Directory

# Run QEMU and launch second terminal,
# wait for connection via gdb
$TERMINAL gdb -x $GDB_FILE &
$QEMU $QEMU_FLAGS -s -S