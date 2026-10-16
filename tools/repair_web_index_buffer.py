#!/usr/bin/env python3
"""Repair the pinned Godot 4.7.2 single-threaded release Web template.

Source counterpart: GLES3::MeshStorage::mesh_surface_update_index_region,
drivers/gles3/storage/mesh_storage.cpp @ ed1daf0bf. Its three ARRAY_BUFFER
targets must be COPY_WRITE_BUFFER on WebGL2. This updates the index buffer
without changing an active VAO's ELEMENT_ARRAY_BUFFER binding.

Only the exact upstream binary and exact repaired binary are accepted. No
search/replace across arbitrary WASM, browser monkey patch, or error filtering.
See docs/playtests/2026-10-16-webgl-index-buffer/README.md.
"""
import hashlib
import json
from pathlib import Path
import sys

FIX_ID = 'godot-4.7.2-webgl2-index-update-target-v1'
ORIGINAL_SHA256 = 'fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0'
REPAIRED_SHA256 = 'fdab8cf15509d9042cd7f6f9f9eafb5201c85a59ed161d91346046b2a9268fe4'
FUNCTION_SHA256 = 'c0779bd094d8caeae344bda5ef35a9470a05be009ade6647c1b4f45d5bae166c'
FUNCTION_OFFSET = 33047519
FUNCTION_SIZE = 344
TARGET_OFFSETS = (311, 322, 335)
ARRAY_BUFFER = bytes.fromhex('41 92 91 02')  # i32.const 34962
COPY_WRITE_BUFFER = bytes.fromhex('41 b7 9e 02')  # i32.const 36663


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def repair(data: bytes) -> bytes:
    digest = sha256(data)
    if digest == REPAIRED_SHA256:
        return data
    if digest != ORIGINAL_SHA256:
        raise ValueError('Unsupported Web template SHA256: ' + digest)
    body = data[FUNCTION_OFFSET:FUNCTION_OFFSET + FUNCTION_SIZE]
    if sha256(body) != FUNCTION_SHA256:
        raise ValueError('Pinned index-update function does not match')
    fixed = bytearray(data)
    for relative in TARGET_OFFSETS:
        offset = FUNCTION_OFFSET + relative
        if data[offset:offset + 4] != ARRAY_BUFFER:
            raise ValueError('Pinned target instruction does not match')
        fixed[offset:offset + 4] = COPY_WRITE_BUFFER
    result = bytes(fixed)
    if len(result) != len(data) or sha256(result) != REPAIRED_SHA256:
        raise ValueError('Repaired Web template does not match expected bytes')
    return result


def repair_record(digest: str) -> list:
    if digest != REPAIRED_SHA256:
        return []
    return [{'id': FIX_ID, 'upstreamSha256': ORIGINAL_SHA256,
             'sha256': REPAIRED_SHA256,
             'scope': 'MeshStorage::mesh_surface_update_index_region; three buffer targets'}]


def main() -> None:
    path = Path(sys.argv[1])
    before = path.read_bytes()
    after = repair(before)  # Validate fully before writing anything.
    if before != after:
        path.write_bytes(after)
    print(json.dumps({'bytes': len(after), 'changed': before != after,
                      'repairs': repair_record(sha256(after))}, sort_keys=True))


if __name__ == '__main__':
    main()
