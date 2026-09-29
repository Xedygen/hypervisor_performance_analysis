/*
 * rt-bench for Zephyr: the Jailhouse rt-bench inmate
 * (jailhouse-rt/inmates/demos/arm/rt-bench.c) as a Zephyr thread.
 *
 * A periodic k_timer releases a cooperative thread at the highest priority.
 * The expiry callback reads the arch timer compare value (the deadline that
 * just fired; Zephyr reprograms it only after the announce), and the thread
 * measures its wake-up latency against it, so "lat" covers the timer IRQ
 * path plus the Zephyr scheduler, like cyclictest. The control workload and
 * the output line are the same as the bare-metal version:
 *  W <n> lat <min> <avg> <max> <over> exe <min> <avg> <max> resp <max> <over>
 *    pmu <l2_refill> <l3_refill> <bus_access> <inst> <cycles>
 * Times are in ns; <over> counts periods above the deadline.
 *
 * This work is licensed under the terms of the GNU GPL, version 2.
 */

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>
#include <inttypes.h>

#ifndef RTB_PERIOD_US
#define RTB_PERIOD_US	1000
#endif
#ifndef RTB_WINDOW
#define RTB_WINDOW	1000
#endif
#ifndef RTB_WS_KB
#define RTB_WS_KB	768
#endif
#ifndef RTB_LOADS
#define RTB_LOADS	1024
#endif
#ifndef RTB_DEADLINE_US
#define RTB_DEADLINE_US	100
#endif

#define LINE		64
#define MAX_WS		(2 * 1024 * 1024)

/* Cortex-A76 PMU event numbers */
#define EV_L2D_CACHE_REFILL	0x17
#define EV_L3D_CACHE_REFILL	0x2a
#define EV_BUS_ACCESS		0x19
#define EV_INST_RETIRED		0x08

BUILD_ASSERT(RTB_WS_KB * 1024 <= MAX_WS / 2, "working set too large");

static uint8_t buffer[MAX_WS] __aligned(LINE);

struct stats {
	uint64_t n;
	uint64_t lat_min, lat_max, lat_sum, lat_over;
	uint64_t exe_min, exe_max, exe_sum;
	uint64_t resp_max, resp_over;
};

static uint64_t deadline_cyc;
static void **chase_head;
static struct stats cur, done;
static volatile bool printing;
static volatile unsigned long sink;
static volatile uint64_t release_cyc;

K_SEM_DEFINE(release, 0, 1);
K_SEM_DEFINE(window_ready, 0, 1);

static inline uint64_t cycles(void)
{
	uint64_t v;

	__asm__ volatile("isb; mrs %0, cntvct_el0" : "=r"(v));
	return v;
}

static void stats_reset(struct stats *s)
{
	*s = (struct stats){ .lat_min = UINT64_MAX, .exe_min = UINT64_MAX };
}

static void pmu_init(void)
{
	const uint32_t events[4] = { EV_L2D_CACHE_REFILL, EV_L3D_CACHE_REFILL,
				     EV_BUS_ACCESS, EV_INST_RETIRED };

	for (uint64_t n = 0; n < 4; n++) {
		__asm__ volatile("msr pmselr_el0, %0; isb" : : "r"(n));
		__asm__ volatile("msr pmxevtyper_el0, %0" : : "r"((uint64_t)events[n]));
	}
	__asm__ volatile("msr pmccfiltr_el0, xzr");
	/* enable counters 0-3 and the cycle counter, reset, start */
	__asm__ volatile("msr pmcntenset_el0, %0" : : "r"((uint64_t)(0xf | (1UL << 31))));
	__asm__ volatile("msr pmcr_el0, %0; isb" : : "r"((uint64_t)(1 | 2 | 4)));
}

static uint64_t pmu_read(uint64_t n)
{
	uint64_t v;

	__asm__ volatile("msr pmselr_el0, %0; isb" : : "r"(n));
	__asm__ volatile("mrs %0, pmxevcntr_el0" : "=r"(v));
	return v;
}

static uint64_t pmu_cycles(void)
{
	uint64_t v;

	__asm__ volatile("mrs %0, pmccntr_el0" : "=r"(v));
	return v;
}

/* Sattolo shuffle: one random cycle through all lines of the working set */
static void chase_init(unsigned long ws)
{
	unsigned long lines = ws / LINE, i, j, t;
	unsigned long *order = (unsigned long *)(buffer + ws);
	uint64_t rnd = 0x2545f4914f6cdd1dULL;

	for (i = 0; i < lines; i++) {
		order[i] = i;
	}
	for (i = lines - 1; i > 0; i--) {
		rnd = rnd * 6364136223846793005ULL + 1442695040888963407ULL;
		j = (rnd >> 33) % i;
		t = order[i]; order[i] = order[j]; order[j] = t;
	}
	for (i = 0; i < lines; i++) {
		*(void **)(buffer + order[i] * LINE) =
			buffer + order[(i + 1) % lines] * LINE;
	}
	chase_head = (void **)buffer;
}

static void workload(void)
{
	void **p = chase_head;

	for (unsigned int n = 0; n < RTB_LOADS; n++) {
		p = *p;
	}
	chase_head = p;
	sink = (unsigned long)p;
}

/* Timer ISR context: the compare register still holds the deadline that fired */
static void expiry(struct k_timer *t)
{
	uint64_t cval;

	ARG_UNUSED(t);
	__asm__ volatile("mrs %0, cntv_cval_el0" : "=r"(cval));
	release_cyc = cval;
	k_sem_give(&release);
}

K_TIMER_DEFINE(period_timer, expiry, NULL);

static void rt_task(void *a, void *b, void *c)
{
	uint64_t lat, start, exe, resp;

	ARG_UNUSED(a); ARG_UNUSED(b); ARG_UNUSED(c);

	for (;;) {
		/* limit 1: a release missed during an overrun is dropped */
		k_sem_take(&release, K_FOREVER);
		start = cycles();
		lat = start - release_cyc;

		workload();
		exe = cycles() - start;
		resp = lat + exe;

		cur.n++;
		cur.lat_sum += lat;
		cur.exe_sum += exe;
		cur.lat_min = MIN(cur.lat_min, lat);
		cur.lat_max = MAX(cur.lat_max, lat);
		cur.exe_min = MIN(cur.exe_min, exe);
		cur.exe_max = MAX(cur.exe_max, exe);
		cur.resp_max = MAX(cur.resp_max, resp);
		cur.lat_over += lat > deadline_cyc;
		cur.resp_over += resp > deadline_cyc;

		/* if main is still printing, keep accumulating */
		if (cur.n >= RTB_WINDOW && k_sem_count_get(&window_ready) == 0 &&
		    !printing) {
			done = cur;
			stats_reset(&cur);
			k_sem_give(&window_ready);
		}
	}
}

K_THREAD_STACK_DEFINE(rt_stack, 4096);
static struct k_thread rt_thread;

static long ns(uint64_t cyc)
{
	return (long)k_cyc_to_ns_floor64(cyc);
}

int main(void)
{
	uint64_t pmu_prev[5] = { 0 }, pmu_now[5];

	printk("rt-bench (zephyr): ws %u KB, %u loads/period, window %u, period %u us\n",
	       RTB_WS_KB, RTB_LOADS, RTB_WINDOW, RTB_PERIOD_US);
	chase_init(RTB_WS_KB * 1024UL);
	pmu_init();
	stats_reset(&cur);
	deadline_cyc = k_us_to_cyc_ceil64(RTB_DEADLINE_US);

	k_thread_create(&rt_thread, rt_stack, K_THREAD_STACK_SIZEOF(rt_stack),
			rt_task, NULL, NULL, NULL, K_HIGHEST_THREAD_PRIO, 0, K_NO_WAIT);
	k_timer_start(&period_timer, K_USEC(RTB_PERIOD_US), K_USEC(RTB_PERIOD_US));

	for (unsigned int n = 0; ; n++) {
		k_sem_take(&window_ready, K_FOREVER);
		printing = true;

		for (unsigned int i = 0; i < 4; i++) {
			pmu_now[i] = pmu_read(i);
		}
		pmu_now[4] = pmu_cycles();

		printk("W %u lat %ld %ld %ld %" PRIu64 " exe %ld %ld %ld resp %ld %" PRIu64
		       " pmu %" PRIu64 " %" PRIu64 " %" PRIu64 " %" PRIu64 " %" PRIu64 "\n", n,
		       ns(done.lat_min), ns(done.lat_sum / done.n),
		       ns(done.lat_max), done.lat_over,
		       ns(done.exe_min), ns(done.exe_sum / done.n),
		       ns(done.exe_max), ns(done.resp_max), done.resp_over,
		       (pmu_now[0] - pmu_prev[0]) & 0xffffffff,
		       (pmu_now[1] - pmu_prev[1]) & 0xffffffff,
		       (pmu_now[2] - pmu_prev[2]) & 0xffffffff,
		       (pmu_now[3] - pmu_prev[3]) & 0xffffffff,
		       pmu_now[4] - pmu_prev[4]);
		for (unsigned int i = 0; i < 5; i++) {
			pmu_prev[i] = pmu_now[i];
		}
		printing = false;
	}
	return 0;
}
