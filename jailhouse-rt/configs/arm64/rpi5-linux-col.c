/*
 * Jailhouse, a Linux-based partitioning hypervisor
 *
 * Raspberry Pi 5: PREEMPT_RT Linux guest on CPU 3 (as rpi5-linux-demo.c),
 * 32 MB of RAM coloured to 8 of the 32 L3 colours (colours 24-31, 25%, as the
 * Pi 4 thesis); the RAM spans 128 MB of physical memory (0x30000000-0x37ffffff).
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
	struct jailhouse_memory_colored col_mem[1];
} __attribute__((packed)) config = {
	.cell = {
		.signature = JAILHOUSE_CELL_DESC_SIGNATURE,
		.revision = JAILHOUSE_CONFIG_REVISION,
		.name = "linux-guest",
		.flags = JAILHOUSE_CELL_PASSIVE_COMMREG |
			 JAILHOUSE_CELL_VIRTUAL_CONSOLE_PERMITTED,

		.cpu_set_size = sizeof(config.cpus),
		.num_memory_regions = ARRAY_SIZE(config.mem_regions),
		.num_memory_regions_colored = ARRAY_SIZE(config.col_mem),

		.console = {
			.type = JAILHOUSE_CON_TYPE_NONE,
		},
	},

	.cpus = {
		0b1000,
	},

	.mem_regions = {
		/* loader */ {
			.phys_start = 0x38000000,
			.virt_start = 0,
			.size = 0x10000,
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

	.col_mem = {
		{
			/* RAM */
			.memory = {
				.phys_start = 0x30000000,
				.virt_start = 0x30000000,
				.size = 0x02000000,
				.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
					JAILHOUSE_MEM_EXECUTE | JAILHOUSE_MEM_DMA |
					JAILHOUSE_MEM_LOADABLE,
			},
			/* 8 of 32 colours: bit 0 = colour 31, so 0xff = colours 24-31 */
			.colors = 0x000000ff,
		},
	},
};
