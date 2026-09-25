/*
 * colorhog: keep root-cell Linux out of the guest cell's cache colours.
 *
 * jailhouse-rt only colours the guest's memory; root Linux still uses every
 * colour. This tool allocates free memory in chunks, looks up each page's
 * physical frame in /proc/self/pagemap and keeps (mlock'ed, never touched
 * again) the pages whose colour belongs to the guest, returning all other
 * pages. Afterwards new root allocations (stressors) can only get pages of
 * the root's colours. Kernel memory allocated earlier is not affected.
 *
 * colour = PFN mod NCOLORS (L3: 128 KB way / 4 KB page = 32 colours).
 * Usage (root): colorhog <first-guest-colour> <last-guest-colour> <keep-free-MB>
 *   e.g. colorhog 24 31 96   (guest colours 24-31 = jailhouse-rt mask 0xff)
 * Runs until killed, holding the pages.
 * Build: gcc -O2 -o colorhog colorhog.c
 */
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define NCOLORS		32
#define CHUNK		(32UL << 20)

static long mem_available_mb(void)
{
	char line[128];
	long kb = -1;
	FILE *f = fopen("/proc/meminfo", "r");

	while (f && fgets(line, sizeof(line), f))
		if (sscanf(line, "MemAvailable: %ld kB", &kb) == 1)
			break;
	if (f)
		fclose(f);
	return kb / 1024;
}

int main(int argc, char **argv)
{
	if (argc != 4) {
		fprintf(stderr, "usage: %s <first-colour> <last-colour> <keep-free-MB>\n", argv[0]);
		return 1;
	}
	unsigned int lo = atoi(argv[1]), hi = atoi(argv[2]);
	long keep_free = atol(argv[3]);
	long page = sysconf(_SC_PAGESIZE);
	int pm = open("/proc/self/pagemap", O_RDONLY);
	unsigned long held = 0, returned = 0;

	if (pm < 0 || lo > hi || hi >= NCOLORS) {
		perror("pagemap / colours");
		return 1;
	}

	/*
	 * Pass 1: take free memory down to keep_free. Nothing is returned yet,
	 * otherwise freed pages come straight back from the per-CPU free lists
	 * and later chunks would hardly contain any guest-colour pages.
	 */
	char *chunks[256];
	int nchunks = 0;

	while (mem_available_mb() > keep_free && nchunks < 256) {
		char *chunk = mmap(NULL, CHUNK, PROT_READ | PROT_WRITE,
				   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
		if (chunk == MAP_FAILED)
			break;
		/* 4 KB pages only: a huge page would pin a whole 2 MB block */
		madvise(chunk, CHUNK, MADV_NOHUGEPAGE);
		memset(chunk, 0, CHUNK);	/* fault every page in */
		chunks[nchunks++] = chunk;
	}

	/* Pass 2: keep the guest-colour pages, return everything else */
	for (int c = 0; c < nchunks; c++) {
		for (unsigned long off = 0; off < CHUNK; off += page) {
			char *pg = chunks[c] + off;
			uint64_t ent;
			off_t idx = ((uintptr_t)pg / page) * sizeof(ent);
			int keep = 0;

			if (pread(pm, &ent, sizeof(ent), idx) == sizeof(ent) &&
			    (ent >> 63)) {
				unsigned int colour = (ent & ((1ULL << 55) - 1)) % NCOLORS;
				keep = colour >= lo && colour <= hi &&
				       mlock(pg, page) == 0;
			}
			if (keep) {
				held++;
			} else {
				munmap(pg, page);
				returned++;
			}
		}
	}
	printf("colorhog: holding %lu MB in colours %u-%u (returned %lu MB), "
	       "MemAvailable %ld MB\n", held * page >> 20, lo, hi,
	       returned * page >> 20, mem_available_mb());
	fflush(stdout);
	pause();
	return 0;
}
