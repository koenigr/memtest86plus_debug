// SPDX-License-Identifier: GPL-2.0
// Copyright (C) 2020-2022 Martin Whitaker.
//
// Derived from memtest86+ main.c:
//
// MemTest86+ V5 Specific code (GPL V2.0)
// By Samuel DEMEULEMEESTER, memtest@memtest.org
// https://www.memtest.org
// ------------------------------------------------
// main.c - MemTest-86  Version 3.5
//
// Released under version 2 of the Gnu Public License.
// By Chris Brady

#include <stdbool.h>
#include <stdint.h>

#include "boot.h"
#include "bootparams.h"

#include "acpi.h"
#include "cache.h"
#include "cpuid.h"
#include "cpuinfo.h"
#include "heap.h"
#include "hwctrl.h"
#include "hwquirks.h"
#include "io.h"
#include "keyboard.h"
#include "pmem.h"
#include "memctrl.h"
#include "memsize.h"
#include "pci.h"
#include "screen.h"
#include "serial.h"
#include "smbios.h"
#include "smp.h"
#include "temperature.h"
#include "timers.h"
#include "vmem.h"

#include "unistd.h"

#include "badram.h"
#include "config.h"
#include "display.h"
#include "error.h"
#include "test.h"

#include "tests.h"

#include "tsc.h"

#include "print.h"

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

#ifndef TRACE_BARRIERS
#define TRACE_BARRIERS      0
#endif

#ifndef TEST_INTERRUPT
#define TEST_INTERRUPT      0
#endif

#define LOW_LOAD_LIMIT      SIZE_C(4,MB)  // must be a multiple of the page size

#define HIGH_LOAD_LIMIT     (VM_PINNED_SIZE << PAGE_SHIFT)


//------------------------------------------------------------------------------
// Public Variables
//------------------------------------------------------------------------------

// These are exposed in test.h.

uint8_t     chunk_index[MAX_CPUS];

int         num_active_cpus = 0;
int         num_enabled_cpus = 1;

int         master_cpu = 0;

barrier_t   *run_barrier = NULL;

spinlock_t  *error_mutex = NULL;

vm_map_t    vm_map[MAX_MEM_SEGMENTS];
int         vm_map_size = 0;

int         pass_num = 0;
int         test_num = 0;

int         window_num = 0;

bool        restart = false;
bool        bail    = false;

uintptr_t   test_addr[MAX_CPUS];


void main(void) {
    prints(16, 5, "Hello Memtest!");
    prints(17, 5, "Hello Memtest!");
    prints(18, 5, "Hello Memtest!");
    prints(19, 5, "Hello Memtest!");
    prints(20, 5, "Hello Memtest!");
    while(1);
}
