"""Verify the actual exported template, including unsupported/corrupt rejection.

Run after a real Web export: python3 test/web_index_buffer_repair_test.py dist/index.wasm
The separate browser reproduction checks real buffer writes and visible geometry.
"""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from repair_web_index_buffer import (repair, sha256, ORIGINAL_SHA256,
                                     REPAIRED_SHA256, FUNCTION_OFFSET)

original = Path(sys.argv[1]).read_bytes()
assert sha256(original) == ORIGINAL_SHA256, 'Run against the original export before repair'
fixed = repair(original)
assert len(fixed) == len(original)
assert sha256(fixed) == REPAIRED_SHA256
assert repair(fixed) is fixed, 'Idempotent repair'
changes = [i for i, (a, b) in enumerate(zip(original, fixed)) if a != b]
assert changes == [FUNCTION_OFFSET + p for p in (312, 313, 323, 324, 336, 337)]
for candidate in (b'', original[:-1], b'not a WASM template',
                  bytes([original[0] ^ 1]) + original[1:],
                  fixed[:FUNCTION_OFFSET] + bytes([fixed[FUNCTION_OFFSET] ^ 1]) + fixed[FUNCTION_OFFSET + 1:]):
    try:
        repair(candidate)
    except ValueError:
        pass
    else:
        raise AssertionError('Unknown/corrupt binary was accepted')
print('[web-index-buffer] actual template / exact delta / idempotence / 5 rejection cases PASS')
