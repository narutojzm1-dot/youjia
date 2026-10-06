#!/usr/bin/env python3
"""Read-only comparison of two Godot v4 PCKs; validates every entry's MD5."""
import hashlib
import json
from pathlib import Path
import struct
import sys

def read_pck(path):
    data = Path(path).read_bytes()
    magic, version, major, minor, patch, flags = struct.unpack_from('<6I', data)
    assert magic == 0x43504447 and version == 4
    base, directory = struct.unpack_from('<QQ', data, 24)
    count = struct.unpack_from('<I', data, directory)[0]
    cursor = directory + 4
    contents = {}
    for _ in range(count):
        length = struct.unpack_from('<I', data, cursor)[0]
        cursor += 4
        name = data[cursor:cursor + length].rstrip(b'\0').decode()
        cursor += length
        offset, size = struct.unpack_from('<QQ', data, cursor)
        cursor += 16
        expected = data[cursor:cursor + 16]
        cursor += 16
        entry_flags = struct.unpack_from('<I', data, cursor)[0]
        cursor += 4
        assert not entry_flags & 1, 'encrypted member is unsupported'
        start = offset + base if flags & 2 else offset
        content = data[start:start + size]
        assert len(content) == size and hashlib.md5(content).digest() == expected, name
        assert name not in contents
        contents[name] = content
    return hashlib.sha256(data).hexdigest(), contents

def uids(data):
    count = struct.unpack_from('<I', data)[0]
    cursor = 4
    by_path = {}
    order = []
    for _ in range(count):
        uid, length = struct.unpack_from('<QI', data, cursor)
        cursor += 12
        path = data[cursor:cursor + length].decode()
        cursor += length
        assert path not in by_path
        by_path[path] = uid
        order.append(path)
    assert cursor == len(data)
    return by_path, order

left_hash, left = read_pck(sys.argv[1])
right_hash, right = read_pck(sys.argv[2])
lu, lo = uids(left['.godot/uid_cache.bin'])
ru, ro = uids(right['.godot/uid_cache.bin'])
changed_uids = [{'path': p, 'baseline_uid': lu.get(p), 'candidate_uid': ru.get(p)} for p in sorted(lu.keys() | ru.keys()) if lu.get(p) != ru.get(p)]
result = {'baseline_pck_sha256': left_hash, 'candidate_pck_sha256': right_hash,
          'baseline_entries': len(left), 'candidate_entries': len(right),
          'all_member_md5_valid': True,
          'only_baseline': sorted(left.keys() - right.keys()), 'only_candidate': sorted(right.keys() - left.keys()),
          'uid_cache': {'baseline_count': len(lu), 'candidate_count': len(ru), 'order_identical': lo == ro, 'changed_uids': changed_uids},
          'changed_entries': []}
for name in sorted(left.keys() & right.keys()):
    a, b = left[name], right[name]
    if a == b:
        continue
    entry = {'path': name, 'baseline': {'size': len(a), 'sha256': hashlib.sha256(a).hexdigest()}, 'candidate': {'size': len(b), 'sha256': hashlib.sha256(b).hexdigest()}}
    if name.endswith('.scn') and len(a) == len(b):
        ranges = []
        for index in range(len(a)):
            if a[index] != b[index]:
                if ranges and index == ranges[-1][-1] + 1:
                    ranges[-1].append(index)
                else:
                    ranges.append([index])
        entry['changed_byte_ranges'] = [{'offset': r[0], 'length': len(r), 'baseline_hex': a[r[0]:r[-1] + 1].hex(), 'candidate_hex': b[r[0]:r[-1] + 1].hex()} for r in ranges]
        entry['known_changed_uid_occurrences'] = []
        for uid in changed_uids:
            if uid['baseline_uid'] is None or uid['candidate_uid'] is None:
                continue
            old, new = struct.pack('<Q', uid['baseline_uid']), struct.pack('<Q', uid['candidate_uid'])
            start = a.find(old)
            if start >= 0 and b[start:start + 8] == new:
                entry['known_changed_uid_occurrences'].append({'path': uid['path'], 'offset': start, 'length': 8})
        normalized = bytearray(b)
        for match in entry['known_changed_uid_occurrences']:
            start = match['offset']
            normalized[start:start + 8] = a[start:start + 8]
        entry['identical_after_restoring_known_uid_bytes'] = bytes(normalized) == a
    result['changed_entries'].append(entry)
print(json.dumps(result, ensure_ascii=False, indent=2))
