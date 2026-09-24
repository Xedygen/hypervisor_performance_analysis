/*
 * Jailhouse, a Linux-based partitioning hypervisor
 *
 * Configuration for Raspberry Pi 5 (BCM2712, 4x Cortex-A76, GIC-400), 1 GB
 *
 * Memory layout (Linux booted with mem=768M):
 *   0x00000000 - 0x2fffffff  root cell Linux
 *   0x30000000 - 0x3ebfffff  inmate cells
 *   0x3ec00000 - 0x3fbfffff  hypervisor (16 MB)
 *   0x3fc00000 -             VideoCore (firmware /memreserve/), not touched
 *
 * No debug UART is configured: hypervisor output goes to the virtual
 * console only, read with "jailhouse console -f".
 *
 * This work is licensed under the terms of the GNU GPL, version 2.  See
 * the COPYING file in the top-level directory.
 */

#include <jailhouse/types.h>
#include <jailhouse/cell-config.h>

struct {
	struct jailhouse_system header;
	__u64 cpus[1];
	struct jailhouse_memory mem_regions[4];
	struct jailhouse_irqchip irqchips[2];
} __attribute__((packed)) config = {
	.header = {
		.signature = JAILHOUSE_SYSTEM_SIGNATURE,
		.revision = JAILHOUSE_CONFIG_REVISION,
		.flags = JAILHOUSE_SYS_VIRTUAL_DEBUG_CONSOLE,
		.hypervisor_memory = {
			.phys_start = 0x3ec00000,
			.size       = 0x01000000,
		},
		.debug_console = {
			.type = JAILHOUSE_CON_TYPE_NONE,
		},
		.platform_info = {
			.arm = {
				.gic_version = 2,
				.gicd_base = 0x107fff9000,
				.gicc_base = 0x107fffa000,
				.gich_base = 0x107fffc000,
				.gicv_base = 0x107fffe000,
				.maintenance_irq = 25,
			},
		},
		.root_cell = {
			.name = "Raspberry-Pi5",

			.cpu_set_size = sizeof(config.cpus),
			.num_memory_regions = ARRAY_SIZE(config.mem_regions),
			.num_irqchips = ARRAY_SIZE(config.irqchips),
		},
	},

	.cpus = {
		0b1111,
	},

	.mem_regions = {
		/* SoC peripherals, up to (not including) the GIC */ {
			.phys_start = 0x1000000000,
			.virt_start = 0x1000000000,
			.size =         0x7fff9000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_IO,
		},
		/* PCIe windows, incl. RP1 (Ethernet, GPIO UARTs) */ {
			.phys_start = 0x1c00000000,
			.virt_start = 0x1c00000000,
			.size =        0x400000000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_IO,
		},
		/* RAM: Linux */ {
			.phys_start = 0x0,
			.virt_start = 0x0,
			.size = 0x30000000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_EXECUTE | JAILHOUSE_MEM_DMA,
		},
		/* RAM: inmate cells, loadable from the root cell */ {
			.phys_start = 0x30000000,
			.virt_start = 0x30000000,
			.size = 0x0ec00000,
			.flags = JAILHOUSE_MEM_READ | JAILHOUSE_MEM_WRITE |
				JAILHOUSE_MEM_EXECUTE | JAILHOUSE_MEM_DMA,
		},
	},

	.irqchips = {
		/* GIC-400, SPIs 32..159 */ {
			.address = 0x107fff9000,
			.pin_base = 32,
			.pin_bitmap = {
				0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
			},
		},
		/* GIC-400, SPIs 160..287 (highest in use: 282) */ {
			.address = 0x107fff9000,
			.pin_base = 160,
			.pin_bitmap = {
				0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
			},
		},
	},
};
