#!/usr/bin/env python3
import datetime
import json
import os
import pathlib
import signal
import subprocess
import sys

engine = '/tmp/youjia-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'
ledger = pathlib.Path(os.environ['VOLUME466_ENGINE_LEDGER'])
now = lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
row = {'argv': [engine] + sys.argv[1:], 'started': now(), 'pid': os.getpid()}
child = subprocess.Popen(row['argv'])
def forward(signum, frame):
    row['received_signal'] = signum
    child.send_signal(signum)
signal.signal(signal.SIGTERM, forward)
signal.signal(signal.SIGINT, forward)
code = child.wait()
row.update({'ended': now(), 'direct_exit': code})
with ledger.open('a') as stream:
    stream.write(json.dumps(row) + '\n')
sys.exit(code if code >= 0 else 128 - code)
