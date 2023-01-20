# Purpose
The purpose of this branch 'boot_to_run_memmap' is to rewrite the memory map, such that UEFI regions are also recognized

# Made changes
efisetup.c - set_e820_map(boot_params_t params)

e820_type_t e820_type = E820_RESERVED;
        switch (mem_desc->type) {
          case EFI_ACPI_RECLAIM_MEMORY:
            e820_type = E820_ACPI;
            break;
          case EFI_LOADER_CODE: *e820_type = E820_RESERVED;*
          case EFI_LOADER_DATA: *e820_type = E820_RESERVED;*
          case EFI_BOOT_SERVICES_CODE: *e820_type = E820_RESERVED;*
          case EFI_BOOT_SERVICES_DATA: *e820_type = E820_RESERVED;*
          case EFI_CONVENTIONAL_MEMORY:
            e820_type = E820_RAM;
            break;
          default:
            continue;
        }

bootparams.h

typedef enum {
    E820_NONE       = 0,
    E820_RAM        = 1,
    E820_RESERVED   = 2,
    E820_ACPI       = 3,    // usable as RAM once ACPI tables have been read
    E820_NVS        = 4
} e820_type_t;

# Questions:
## Why is EFI_LOADER_CODE and EFI_LOADER_DATA also unrecognized?