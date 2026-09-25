/*
 * pwalk: pointer-chasing memory walker used as a noisy neighbour (thesis
 * scenario 3). Walks a random single cycle through a working set with a
 * given stride, so every step is a dependent load that misses the caches
 * (and, with a 4 KB stride, the TLB) once the working set is large enough.
 *
 * Usage: pwalk <working-set-MB> <stride-bytes> <seconds>
 * Build: gcc -O2 -o pwalk pwalk.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char **argv)
{
	if (argc != 4) {
		fprintf(stderr, "usage: %s <ws-MB> <stride-bytes> <seconds>\n", argv[0]);
		return 1;
	}
	size_t ws = strtoul(argv[1], NULL, 0) << 20;
	size_t stride = strtoul(argv[2], NULL, 0);
	time_t end = time(NULL) + strtol(argv[3], NULL, 0);

	if (stride < sizeof(void *) || ws < 2 * stride) {
		fprintf(stderr, "bad working set / stride\n");
		return 1;
	}
	size_t nodes = ws / stride;
	char *buf = malloc(ws);
	size_t *order = malloc(nodes * sizeof(*order));
	if (!buf || !order) {
		perror("malloc");
		return 1;
	}

	/* Sattolo: a single random cycle through all nodes */
	for (size_t i = 0; i < nodes; i++)
		order[i] = i;
	srand(12345);
	for (size_t i = nodes - 1; i > 0; i--) {
		size_t j = (((size_t)rand() << 31) ^ rand()) % i, t = order[i];
		order[i] = order[j];
		order[j] = t;
	}
	for (size_t i = 0; i < nodes; i++)
		*(void **)(buf + order[i] * stride) =
			buf + order[(i + 1) % nodes] * stride;
	free(order);

	void **p = (void **)buf;
	unsigned long long steps = 0;
	while (time(NULL) < end) {
		for (int k = 0; k < 1000000; k++)
			p = *p;
		steps += 1000000;
	}
	printf("pwalk: %llu steps, last %p\n", steps, (void *)p);
	return 0;
}
