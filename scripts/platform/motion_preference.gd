extends Node
## Web system preference only. No player override, save schema, or debug API.
const SOURCE := """
(() => {
  try { window.__YoujiaMotionPreferenceBinding?.stop(); } catch (_) {}
  let query = null, callback = null, stopped = false, bound = false;
  const report = () => {
    if (stopped || !query || !callback) return;
    try { if (typeof query.matches === 'boolean') callback(query.matches); } catch (_) {}
  };
  const visible = () => { if (document.visibilityState === 'visible') report(); };
  const stop = () => {
    if (stopped) return;
    stopped = true;
    try { if (query && bound) query.removeEventListener('change', report); } catch (_) {}
    try { document.removeEventListener('visibilitychange', visible); } catch (_) {}
    try { window.removeEventListener('pageshow', report); } catch (_) {}
    callback = null;
    if (window.__YoujiaMotionPreferenceBinding === binding) delete window.__YoujiaMotionPreferenceBinding;
  };
  const binding = {
    start(cb) {
      if (stopped || callback) return;
      callback = cb;
      try {
        if (typeof window.matchMedia !== 'function') return;
        query = window.matchMedia('(prefers-reduced-motion: reduce)');
        report();
        if (query && typeof query.addEventListener === 'function') {
          query.addEventListener('change', report); bound = true;
        }
        document.addEventListener('visibilitychange', visible);
        window.addEventListener('pageshow', report);
      } catch (_) { /* Keep the valid initial/default value; boot must continue. */ }
    },
    stop
  };
  window.__YoujiaMotionPreferenceBinding = binding;
  return binding;
})()
"""
var _binding: JavaScriptObject
var _callback: JavaScriptObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	_callback = JavaScriptBridge.create_callback(_receive)
	JavaScriptBridge.eval(SOURCE, true)
	_binding = JavaScriptBridge.get_interface("__YoujiaMotionPreferenceBinding")
	if _binding != null:
		_binding.start(_callback)

func _receive(args: Array) -> void:
	if args.size() != 1 or not args[0] is bool:
		return
	TuningStore.set_value("ui.reduced_motion", args[0], false)

func _exit_tree() -> void:
	if _binding != null:
		_binding.stop()
	_binding = null
	_callback = null
