// Diagnostic only: parallel mono analysers on existing destination connections.
// No AudioContext is created here; original connects/starts are forwarded intact.
(() => {
  const nativeConnect = AudioNode.prototype.connect;
  const nativeStart = AudioBufferSourceNode.prototype.start;
  const nodeIds = new WeakMap(), bufferIds = new WeakMap(), taps = new Map(), contexts = new Map(), edges = new Map();
  let serial = 0, bufferSerial = 0;
  const sources = [], failures = [];
  const id = node => { if (!nodeIds.has(node)) nodeIds.set(node, ++serial); return nodeIds.get(node); };
  const bufferId = buffer => { if (!bufferIds.has(buffer)) bufferIds.set(buffer, ++bufferSerial); return bufferIds.get(buffer); };
  AudioNode.prototype.connect = function (...args) {
    const result = Reflect.apply(nativeConnect, this, args);
    try {
      if (this instanceof AudioBufferSourceNode && args[0] instanceof GainNode)
        edges.set(id(this), id(args[0]));
      if (args[0] === this.context.destination && !taps.has(id(this))) {
        if (!contexts.has(this.context)) {
          const mix = this.context.createMediaStreamDestination();
          const mime = MediaRecorder.isTypeSupported('audio/webm;codecs=opus') ? 'audio/webm;codecs=opus' : 'audio/webm';
          const recorder = new MediaRecorder(mix.stream, { mimeType: mime, audioBitsPerSecond: 96000 });
          const chunks = [];
          recorder.ondataavailable = event => { if (event.data.size) chunks.push(event.data); };
          recorder.start(1000);
          contexts.set(this.context, { mix, recorder, chunks, id: contexts.size + 1 });
        }
        const analyser = this.context.createAnalyser();
        analyser.fftSize = 4096;
        analyser.smoothingTimeConstant = 0;
        Reflect.apply(nativeConnect, this, [analyser]);
        Reflect.apply(nativeConnect, this, [contexts.get(this.context).mix]);
        taps.set(id(this), { node: this, analyser, samples: new Float32Array(4096) });
      }
    } catch (e) { failures.push(String(e)); }
    return result;
  };
  AudioBufferSourceNode.prototype.start = function (...args) {
    const result = Reflect.apply(nativeStart, this, args);
    try {
      const b = this.buffer;
      sources.push({ wallMs: performance.now(), audioTime: this.context.currentTime,
        node: id(this), outputGainNode: edges.get(id(this)), buffer: b ? bufferId(b) : null,
        frames: b?.length, channels: b?.numberOfChannels, sampleRate: b?.sampleRate,
        duration: b?.duration, loop: this.loop, loopStart: this.loopStart, loopEnd: this.loopEnd,
        startArgs: args });
    } catch (e) { failures.push(String(e)); }
    return result;
  };
  window.audioObservation = {
    diagnostics() {
      const signal = [];
      for (const [nodeId, t] of taps) {
        t.analyser.getFloatTimeDomainData(t.samples);
        let sum = 0, peak = 0, nonFinite = 0;
        for (const value of t.samples) {
          if (!Number.isFinite(value)) { nonFinite++; continue; }
          sum += value * value; peak = Math.max(peak, Math.abs(value));
        }
        signal.push({ node: nodeId, context: contexts.get(t.node.context)?.id, type: t.node.constructor.name,
          contextState: t.node.context.state, audioTime: t.node.context.currentTime,
          sampleRate: t.node.context.sampleRate,
          gain: t.node.gain?.value ?? null, rms: Math.sqrt(sum / t.samples.length), peak, nonFinite });
      }
      return { wallMs: performance.now(), signal, sources: sources.slice(), failures: failures.slice(),
        backend: globalThis.__manusBgm ? JSON.parse(globalThis.__manusBgm.diagnostics()) : null,
        jsHeap: performance.memory ? { used: performance.memory.usedJSHeapSize, total: performance.memory.totalJSHeapSize, limit: performance.memory.jsHeapSizeLimit } : null };
    },
    pcm() {
      return [...taps].map(([nodeId, t]) => {
        t.analyser.getFloatTimeDomainData(t.samples);
        return { node: nodeId, sampleRate: t.node.context.sampleRate,
          audioTime: t.node.context.currentTime, mono: Array.from(t.samples) };
      });
    },
    async finishRecordings() {
      const result = [];
      for (const [ctx, recording] of contexts) {
        if (recording.recorder.state !== 'inactive') {
          await new Promise(resolve => { recording.recorder.onstop = resolve; recording.recorder.stop(); });
        }
        const blob = new Blob(recording.chunks, { type: recording.recorder.mimeType });
        const bytes = new Uint8Array(await blob.arrayBuffer());
        let binary = '';
        for (let offset = 0; offset < bytes.length; offset += 32768)
          binary += String.fromCharCode(...bytes.subarray(offset, offset + 32768));
        result.push({ context: recording.id, contextState: ctx.state, sampleRate: ctx.sampleRate,
          mime: recording.recorder.mimeType, bytes: bytes.length, base64: btoa(binary) });
      }
      return result;
    }
  };
})();
