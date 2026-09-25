/*
 * Jailhouse, a Linux-based partitioning hypervisor
 *
 * rt-bench cell on Raspberry Pi 5: 2 CPUs (cores 2-3; rt-bench runs on core 2,
 * core 3 stays parked), 4 MB RAM, no cache colouring.
 * No UART: the inmate prints through the hypervisor virtual console
 * (read with "jailhouse console -f" in the root cell).
 *
 * This work is licensed under the terms of the GNU GPL, version 2.  See
 * the COPYING file in the top-level directory.
 */

#include <jailhouse/types.h>
#include <jailhouse/cell-config.h>

struct {
	struct jailhouse_cell_desc cell;
	__u64 cpus[1];
	struct jailhouse_memory mem_regions[2];
} __attribute__((packed)) config = {
	.cell = {
		.signature = JAILHOUSE_CELL_DESC_SIGNATURE,
		.revision = JAILHOUSE_CONFIG_REVISION,
		.name = "rt-bench",
		.flags = JAILHOUSE_CELL_PASSIVE_COMMREG |
			 JAILHOUSE_CELL_VIRTUAL_CONSOLE_ACTIVE,

		.cpu_set_size = sizeof(config.cpus),
		.num_memory_regions = ARRAY_SIZE(config.mem_regions),

		.console = {
			.type = JAILHOUSE_CON_TYPE_NONE,
		},
	},

	.cpus = {
		0b1100,
	},

	.mem_regions = {
		/* RAM */ {
			.phys_start = 0x30000000,
			.virt_start = 0,
			.size = 0x00400000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_EXECUTE | JAILHOUSE_MEM_LOADABLE,
		},
		/* communication region */ {
			.virt_start = 0x80000000,
			.size = 0x00001000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_COMM_REGION,
		},
	},
};
