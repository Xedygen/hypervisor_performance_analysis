/*
 * Jailhouse, a Linux-based partitioning hypervisor
 *
 * Raspberry Pi 5: Zephyr RTOS inmate on CPU 3 (zephyr/ in this repository),
 * RAM coloured to 8 of the 32 L3 colours (colours 24-31, as rpi5-rtbench-col.c);
 * the 8 MB span 32 MB of physical memory (0x30000000-0x31ffffff).
 *
 * RAM is identity-mapped at 0x30000000 (8 MB), matching the zephyr,sram node
 * in zephyr/rpi5-jailhouse.overlay; load zephyr.bin there and start at its
 * first byte. The GIC is set up by Jailhouse, the arch timer is a PPI, and
 * the console goes through the debug-console hypercall.
 *
 * This work is licensed under the terms of the GNU GPL, version 2.  See
 * the COPYING file in the top-level directory.
 */

#include <jailhouse/types.h>
#include <jailhouse/cell-config.h>

struct {
	struct jailhouse_cell_desc cell;
	__u64 cpus[1];
	struct jailhouse_memory mem_regions[1];
	struct jailhouse_memory_colored col_mem[1];
} __attribute__((packed)) config = {
	.cell = {
		.signature = JAILHOUSE_CELL_DESC_SIGNATURE,
		.revision = JAILHOUSE_CONFIG_REVISION,
		.name = "zephyr",
		.flags = JAILHOUSE_CELL_PASSIVE_COMMREG |
			 JAILHOUSE_CELL_VIRTUAL_CONSOLE_PERMITTED |
			 JAILHOUSE_CELL_VIRTUAL_CONSOLE_ACTIVE,

		.cpu_set_size = sizeof(config.cpus),
		.num_memory_regions = ARRAY_SIZE(config.mem_regions),
		.num_memory_regions_colored = ARRAY_SIZE(config.col_mem),
		.cpu_reset_address = 0x30000000,

		.console = {
			.type = JAILHOUSE_CON_TYPE_NONE,
		},
	},

	.cpus = {
		0b1000,
	},

	.mem_regions = {
		/* communication region */ {
			.virt_start = 0x80000000,
			.size = 0x00001000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_COMM_REGION,
		},
	},

	.col_mem = {
		{
			/* RAM */
			.memory = {
				.phys_start = 0x30000000,
				.virt_start = 0x30000000,
				.size = 0x00800000,
				.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
					JAILHOUSE_MEM_EXECUTE | JAILHOUSE_MEM_LOADABLE,
			},
			/* 8 of 32 colours: bit 0 = colour 31, so 0xff = colours 24-31 */
			.colors = 0x000000ff,
		},
	},
};
