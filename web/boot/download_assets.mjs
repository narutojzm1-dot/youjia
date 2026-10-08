// Recover only Godot's two immutable startup assets. Keep the browser's normal
// full-response HTTP cache on the successful path; resume decoded bytes on idle.
// Large PCK files may exceed the HTTP cache's per-entry limit. CacheStorage is
// optional, stores only completed assets, and never touches the save database.
export function installAssetRecovery(config, {
  target = window, idleMs = 20000, maxRetries = 3,
  onRetry = () => {}, onError = () => {},
  onCacheHit = () => {},
} = {}) {
  const assets = new Map(Object.entries(config.fileSizes || {})
    .filter(([name, size]) => /\.(wasm|pck)$/.test(name) && Number.isSafeInteger(size) && size > 0)
    .map(([name, size]) => [new URL(name, target.location.href).href, size]));
  const original = target.fetch;
  const active = new Set();
  let stopped = false;
  const restore = () => {
    stopped = true;
    if (target.fetch === wrapped) target.fetch = original;
    for (const controller of active) controller.abort();
    active.clear();
  };
  const fatal = (message) => Object.assign(new Error(message), {invalidAsset: true});
  async function recover(url, size) {
    let cache;
    try {
      cache = await target.caches?.open('youjia-startup-assets-v1');
      const saved = await cache?.match(url);
      if (saved?.headers.get('x-youjia-asset-size') === String(size)) {
        onCacheHit({url});
        return saved;
      }
      if (saved) await cache.delete(url);
    } catch { /* Private mode, quota or storage failures must not block startup. */ }
    let offset = 0, retries = 0, etag;
    const stream = new ReadableStream({
      async start(output) {
        try {
          while (offset < size) {
            const abort = new AbortController();
            active.add(abort);
            let timer, reader;
            const arm = () => {
              clearTimeout(timer);
              timer = setTimeout(() => abort.abort(), idleMs);
            };
            try {
              if (stopped) throw new Error('资源下载已取消');
              arm();
              const response = await original.call(target, url, {
                signal: abort.signal,
                ...(offset ? {headers: {Range: `bytes=${offset}-`}} : {}),
              });
              if (!response.ok || !response.body) throw new Error(`资源请求失败 (${response.status})`);
              const nextEtag = response.headers.get('etag')?.replace(/^W\//, '');
              if (etag && nextEtag && etag !== nextEtag) throw fatal('重试时资源版本发生变化，请重新加载');
              etag ||= nextEtag;
              let skip = offset;
              if (response.status === 206) {
                const range = /^bytes (\d+)-(\d+)\/(\d+)$/.exec(response.headers.get('content-range') || '');
                if (!range || +range[1] !== offset || +range[2] !== size - 1 || +range[3] !== size || response.headers.get('content-encoding')) {
                  throw fatal('资源断点响应不正确，请重新加载');
                }
                skip = 0;
              } else if (response.status !== 200) {
                throw fatal('资源响应不正确，请重新加载');
              }
              // A server may ignore Range and return 200. Discard the already
              // delivered prefix rather than concatenate duplicate pack bytes.
              reader = response.body.getReader();
              while (true) {
                arm();
                const {done, value} = await reader.read();
                if (done) break;
                if (!value.byteLength) continue;
                const ignored = Math.min(skip, value.byteLength);
                skip -= ignored;
                const chunk = value.subarray(ignored);
                if (offset + chunk.byteLength > size) throw fatal('资源大小与构建不符，请重新加载');
                if (chunk.byteLength) {
                  output.enqueue(chunk);
                  offset += chunk.byteLength;
                }
              }
              if (offset !== size || skip) throw new Error('资源下载中断');
            } catch (error) {
              if (stopped || error.invalidAsset || retries >= maxRetries) throw error;
              retries++;
              onRetry({url, offset, retry: retries, maxRetries});
            } finally {
              clearTimeout(timer);
              abort.abort();
              await reader?.cancel().catch(() => {});
              active.delete(abort);
            }
          }
          output.close();
        } catch (error) {
          output.error(error);
          if (!stopped) onError(error);
        }
      },
      cancel() { restore(); },
    });
    const response = new Response(stream, {headers: {
      'content-type': url.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream',
      'content-length': String(size),
      'x-youjia-asset-size': String(size),
    }});
    if (cache) {
      // put() rejects if any part of the body fails. No partial pack is stored.
      try { cache.put(url, response.clone()).then(async () => {
        const keys = await cache.keys();
        const old = keys.filter(key => !assets.has(key.url));
        for (const key of old.slice(0, Math.max(0, keys.length - 4))) await cache.delete(key);
      }).catch(() => {}); } catch { /* Optional asset cache remains best-effort. */ }
    }
    return response;
  }
  function wrapped(input, init) {
    // Do not intercept save modules, game HTTP traffic, explicit requests or
    // third party fetches. The exported Godot preloader calls fetch(URL) only.
    const url = typeof input === 'string' ? new URL(input, target.location.href).href : null;
    return !stopped && init === undefined && assets.has(url)
      ? recover(url, assets.get(url)) : original.call(target, input, init);
  }
  target.fetch = wrapped;
  return restore;
}
