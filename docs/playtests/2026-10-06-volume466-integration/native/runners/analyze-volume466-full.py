import hashlib
import json
import pathlib
import re
import subprocess

repo = pathlib.Path('/dev/shm/youjia-volume466')
out = pathlib.Path('/dev/shm/volume466-evidence/full-v1')
log = out / 'daily.log'
lines = log.read_text().splitlines()
starts = [i for i, line in enumerate(lines) if line.startswith('Godot Engine v4.7.2.stable.official.ed1daf0bf')]
all_records = [json.loads(line) for line in (out / 'engine-processes.jsonl').read_text().splitlines()]
version_queries = [row for row in all_records if row['argv'][1:] == ['--version']]
records = [row for row in all_records if row['argv'][1:] != ['--version']]
patterns = dict(line.split('\t') for line in (repo / 'tools/lib/godot_suite_completions.tsv').read_text().splitlines() if line and not line.startswith('#'))
assert len(starts) == len(records), (len(starts), len(records))
results = []
for index, record in enumerate(records):
    entry = next((arg.removeprefix('res://') for arg in record['argv'] if arg.startswith('res://')), None)
    start, end = starts[index], starts[index + 1] if index + 1 < len(starts) else len(lines)
    segment = '\n'.join(lines[start:end]) + '\n'
    scan = subprocess.run(['grep', '-En', r'^(SCRIPT ERROR|ERROR:)|(^|[[:space:]])FAIL([[:space:]:]|$)'], input=segment, capture_output=True, text=True)
    row = dict(record, entry=entry, log_first_line=start + 1, log_last_line=end, strict_error_scan_exit=scan.returncode, strict_error_lines=scan.stdout.splitlines())
    if entry:
        completion = subprocess.run(['grep', '-Ex', patterns[entry]], input=segment, capture_output=True, text=True)
        row.update({'expected_completion': patterns[entry], 'completion_exit': completion.returncode, 'actual_completion_lines': completion.stdout.splitlines()})
    row['verified'] = record['direct_exit'] == 0 and scan.returncode == 1 and (not entry or row['completion_exit'] == 0)
    results.append(row)
summary = {'source': json.loads((out / 'source.json').read_text())['source'], 'engine_starts': len(results), 'import_starts': sum(r['entry'] is None for r in results), 'suite_starts': sum(r['entry'] is not None for r in results), 'unique_suite_entries': len({r['entry'] for r in results if r['entry']}), 'publisher_fixture_version_queries': version_queries, 'all_recorded_engine_processes': len(all_records), 'all_direct_exit_zero': all(r['direct_exit'] == 0 for r in all_records), 'every_invocation_verified': all(r['verified'] for r in results), 'full_script_actual_exit': json.loads((out / 'process-results.json').read_text())[0]['direct_exit'], 'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(), 'node_tail': lines[-25:], 'invocations': results}
(out / 'actual-suite-completions.json').write_text(json.dumps(summary, indent=2) + '\n')
assert summary['every_invocation_verified'] and summary['full_script_actual_exit'] == 0
print(json.dumps({k: v for k, v in summary.items() if k not in ('invocations', 'node_tail')}, indent=2))
