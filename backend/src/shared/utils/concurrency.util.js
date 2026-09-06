/**
 * Run async work over items with a fixed concurrency ceiling.
 * @template T
 * @param {T[]} items
 * @param {number} concurrency
 * @param {(item: T, index: number) => Promise<void>} worker
 */
export async function mapWithConcurrency(items, concurrency, worker) {
  const list = Array.isArray(items) ? items : [];
  const limit = Math.max(1, Number(concurrency) || 1);
  if (!list.length) return;

  let nextIndex = 0;

  async function runWorker() {
    while (nextIndex < list.length) {
      const current = nextIndex;
      nextIndex += 1;
      await worker(list[current], current);
    }
  }

  const runners = Array.from({ length: Math.min(limit, list.length) }, () =>
    runWorker()
  );
  await Promise.all(runners);
}

export default { mapWithConcurrency };
