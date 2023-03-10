# Purpose
The purpose of this branch 'boot_to_run_memmap' is to rewrite the memory map, such that UEFI regions are also recognized

# Made changes
## Mark more areas in memory map
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

## Outcomment exit_boot_services
efisetup.c
527, 546   //status = efi_call_bs(exit_boot_services, handle, mem_map_key);

## Complete table of memory types
efi.h

/\*\*\* EFI_MEMORY_TYPE values.
 \*/
#define EFI_RESERVED_TYPE               0
#define EFI_LOADER_CODE                 1
#define EFI_LOADER_DATA                 2
#define EFI_BOOT_SERVICES_CODE          3
#define EFI_BOOT_SERVICES_DATA          4
#define EFI_RUNTIME_SERVICES_CODE       5
#define EFI_RUNTIME_SERVICES_DATA       6
#define EFI_CONVENTIONAL_MEMORY         7
#define EFI_UNUSABLE_MEMORY             8
#define EFI_ACPI_RECLAIM_MEMORY         9
#define EFI_ACPI_MEMORY_NVS             10
#define EFI_MEMORY_MAPPED_IO            11
#define EFI_MEMORY_MAPPED_IO_PORT_SPACE 12
#define EFI_PAL_CODE                    13
#define EFI_PERSISTENT_MEMORY           14
#define EFI_MAX_MEMORY_TYPE             15


# Questions:
## Why is EFI_LOADER_CODE and EFI_LOADER_DATA also unrecognized?