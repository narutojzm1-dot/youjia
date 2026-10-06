#!/usr/bin/env python3
import subprocess,os,sys,json,datetime
from pathlib import Path
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
start=now()
code=subprocess.run(['/tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64',*sys.argv[1:]]).returncode
row={'args':sys.argv[1:],'started':start,'ended':now(),'direct_exit':code,'phase':os.environ.get('TOOLTIP473_PHASE'),'isolated_data':os.environ.get('XDG_DATA_HOME')}
with Path(os.environ['TOOLTIP473_PROCESS_LOG']).open('a') as f:f.write(json.dumps(row)+'\n')
sys.exit(code)
