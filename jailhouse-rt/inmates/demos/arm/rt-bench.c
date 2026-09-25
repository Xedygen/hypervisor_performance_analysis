/*
 * rt-bench: periodic real-time task for measuring interference on a
 * Jailhouse guest cell (bare-metal stand-in for cyclictest).
 *
 * Every period (default 1 ms, i.e. 1 kHz) the timer IRQ fires and the task:
 *  1. records the wake-up latency (actual - expected fire time),
 *  2. runs a fixed control workload: a random pointer chase over a working
 *     set larger than the private L2, so it depends on the shared L3,
 *  3. records the workload execution time.
 * Once per window (default 1000 periods) it prints one summary line:
 *  W <n> lat <min> <avg> <max> <over> exe <min> <avg> <max> resp <max> <over>
 *    pmu <l2_refill> <l3_refill> <bus_access> <inst> <cycles>
 * Times are in ns; <over> counts periods above the deadline (100 us).
 * PMU values are totals for the window on this CPU (EL0/EL1 only).
 *
 * Command line: period-us=, window=, ws-kb=, loads=, deadline-us=
 *
 * This work is licensed under the terms of the GNU GPL, version 2.  See
 * the COPYING file in the top-level directory.
 */

#include <inmate.h>
#include <gic.h>

#define LINE		64
#define MAX_WS		(2 * 1024 * 1024)

/* Cortex-A76 PMU event numbers */
#define EV_L2D_CACHE_REFILL	0x17
#define EV_L3D_CACHE_REFILL	0x2a
#define EV_BUS_ACCESS		0x19
#define EV_INST_RETIRED		0x08

static u8 buffer[MAX_WS] __attribute__((aligned(LINE)));

struct stats {
	u64 n;
	u64 lat_min, lat_max, lat_sum, lat_over;
	u64 exe_min, exe_max, exe_sum;
	u64 resp_max, resp_over;
};

static u64 period_ticks, deadline_ticks, expected_ticks;
static unsigned int loads, window;
static void **chase_head;
static struct stats cur, done;
static volatile bool window_ready;
static volatile unsigned long sink;

static void stats_reset(struct stats *s)
{
	*s = (struct stats){ .lat_min = ~0ULL, .exe_min = ~0ULL };
}

static void pmu_init(void)
{
	const u32 events[4] = { EV_L2D_CACHE_REFILL, EV_L3D_CACHE_REFILL,
				EV_BUS_ACCESS, EV_INST_RETIRED };
	unsigned int n;

	for (n = 0; n < 4; n++) {
		asm volatile("msr pmselr_el0, %0; isb" : : "r"((u64)n));
		asm volatile("msr pmxevtyper_el0, %0" : : "r"((u64)events[n]));
	}
	asm volatile("msr pmccfiltr_el0, xzr");
	/* enable counters 0-3 and the cycle counter, reset, start */
	asm volatile("msr pmcntenset_el0, %0" : : "r"((u64)(0xf | (1UL << 31))));
	asm volatile("msr pmcr_el0, %0; isb" : : "r"((u64)(1 | 2 | 4)));
}

static u64 pmu_read(unsigned int n)
{
	u64 v;

	asm volatile("msr pmselr_el0, %0; isb" : : "r"((u64)n));
	asm volatile("mrs %0, pmxevcntr_el0" : "=r"(v));
	return v;
}

static u64 pmu_cycles(void)
{
	u64 v;

	asm volatile("mrs %0, pmccntr_el0" : "=r"(v));
	return v;
}

/* Sattolo shuffle: one random cycle through all lines of the working set */
static void chase_init(unsigned long ws)
{
	unsigned long lines = ws / LINE, i, j;
	unsigned long *order = (unsigned long *)(buffer + ws);
	u64 rnd = 0x2545f4914f6cdd1dULL;

	for (i = 0; i < lines; i++)
		order[i] = i;
	for (i = lines - 1; i > 0; i--) {
		rnd = rnd * 6364136223846793005ULL + 1442695040888963407ULL;
		j = (rnd >> 33) % i;
		unsigned long t = order[i]; order[i] = order[j]; order[j] = t;
	}
	for (i = 0; i < lines; i++)
		*(void **)(buffer + order[i] * LINE) =
			buffer + order[(i + 1) % lines] * LINE;
	chase_head = (void **)buffer;
}

static void workload(void)
{
	void **p = chase_head;
	unsigned int n;

	for (n = 0; n < loads; n++)
		p = *p;
	chase_head = p;
	sink = (unsigned long)p;
}

static void handle_IRQ(unsigned int irqn)
{
	u64 now, lat, start, exe, resp;

	if (irqn != TIMER_IRQ)
		return;

	now = timer_get_ticks();
	lat = now - expected_ticks;
	expected_ticks += period_ticks;
	/* after an overrun, restart the period grid instead of arming
	 * the timer with a negative (= huge) delta */
	if ((s64)(expected_ticks - timer_get_ticks()) <= 0)
		expected_ticks = timer_get_ticks() + period_ticks;
	timer_start(expected_ticks - timer_get_ticks());

	start = timer_get_ticks();
	workload();
	exe = timer_get_ticks() - start;
	resp = lat + exe;

	cur.n++;
	cur.lat_sum += lat;
	cur.exe_sum += exe;
	if (lat < cur.lat_min) cur.lat_min = lat;
	if (lat > cur.lat_max) cur.lat_max = lat;
	if (exe < cur.exe_min) cur.exe_min = exe;
	if (exe > cur.exe_max) cur.exe_max = exe;
	if (resp > cur.resp_max) cur.resp_max = resp;
	if (lat > deadline_ticks) cur.lat_over++;
	if (resp > deadline_ticks) cur.resp_over++;

	if (cur.n >= window && !window_ready) {
		done = cur;
		stats_reset(&cur);
		window_ready = true;
	}
}

static long ns(u64 ticks)
{
	return (long)timer_ticks_to_ns(ticks);
}

void inmate_main(void)
{
	unsigned long ws = cmdline_parse_int("ws-kb", 768) * 1024;
	u64 pmu_prev[5] = { 0 }, pmu_now[5];
	unsigned int n;

	if (ws > MAX_WS / 2)
		ws = MAX_WS / 2;
	loads = cmdline_parse_int("loads", 1024);
	window = cmdline_parse_int("window", 1000);

	printk("rt-bench: ws %lu KB, %u loads/period, window %u\n",
	       ws / 1024, loads, window);
	chase_init(ws);
	pmu_init();
	stats_reset(&cur);

	irq_init(handle_IRQ);
	irq_enable(TIMER_IRQ);

	period_ticks = timer_get_frequency() / 1000000 *
		cmdline_parse_int("period-us", 1000);
	deadline_ticks = timer_get_frequency() / 1000000 *
		cmdline_parse_int("deadline-us", 100);
	expected_ticks = timer_get_ticks() + period_ticks;
	timer_start(period_ticks);

	for (n = 0; ; n++) {
		while (!window_ready)
			asm volatile("wfi");

		for (unsigned int i = 0; i < 4; i++)
			pmu_now[i] = pmu_read(i);
		pmu_now[4] = pmu_cycles();

		printk("W %u lat %ld %ld %ld %llu exe %ld %ld %ld resp %ld %llu "
		       "pmu %llu %llu %llu %llu %llu\n", n,
		       ns(done.lat_min), ns(done.lat_sum / done.n),
		       ns(done.lat_max), done.lat_over,
		       ns(done.exe_min), ns(done.exe_sum / done.n),
		       ns(done.exe_max), ns(done.resp_max), done.resp_over,
		       (pmu_now[0] - pmu_prev[0]) & 0xffffffff,
		       (pmu_now[1] - pmu_prev[1]) & 0xffffffff,
		       (pmu_now[2] - pmu_prev[2]) & 0xffffffff,
		       (pmu_now[3] - pmu_prev[3]) & 0xffffffff,
		       pmu_now[4] - pmu_prev[4]);
		for (unsigned int i = 0; i < 5; i++)
			pmu_prev[i] = pmu_now[i];
		window_ready = false;
	}
}
