from pathlib import Path
import json

root = Path(r'D:\games\youjia-test\assistant-recovery')
original = root / 'nearby-public-inputc282-desktop-observed/1280/loading-network.json'
d = json.loads(original.read_text(encoding='utf-8'))
requests = {}
for item in d['events']:
    event, data = item['event'], item['data']
    rid = data.get('requestId')
    if not rid:
        continue
    r = requests.setdefault(rid, {'requestId': rid, 'decodedBytes': 0, 'encodedDataBytes': 0})
    if event == 'Network.requestWillBeSent':
        r.update(url=data['request']['url'], start=data['timestamp'], requestHeaders=data['request']['headers'])
    elif event == 'Network.responseReceived':
        response = data['response']
        r.update(responseAt=data['timestamp'], status=response['status'], protocol=response.get('protocol'), headers=response['headers'], fromDiskCache=response.get('fromDiskCache'), fromServiceWorker=response.get('fromServiceWorker'))
    elif event == 'Network.dataReceived':
        r['decodedBytes'] += data['dataLength']
        r['encodedDataBytes'] += data['encodedDataLength']
        r.setdefault('firstData', data['timestamp'])
        r['lastData'] = data['timestamp']
    elif event == 'Network.loadingFinished':
        r.update(finished=data['timestamp'], encodedTotalBytes=data['encodedDataLength'])
    elif event == 'Network.loadingFailed':
        r['failure'] = data
assets = [r for r in requests.values() if r.get('url', '').endswith(('.pck', '.wasm'))]
for r in assets:
    if 'finished' in r:
        r['totalSeconds'] = r['finished'] - r['start']
        r['bodySeconds'] = r['finished'] - r['responseAt']
        r['meanEncodedMiBPerSecond'] = r['encodedDataBytes'] / 1048576 / max(r['bodySeconds'], .001)
snapshots = d['snapshots']
out = {
    'source': d['source'],
    'original': str(original.relative_to(root)).replace('\\', '/'),
    'browser': 'Chrome154 fresh isolated context, no extensions, launch --disable-http2; actual HTTP1.1 through local proxy. Not the user browser/network or strict A/B.',
    'assets': assets,
    'coldComplete': next(s for s in snapshots if s.get('stage') == 'cold-complete'),
    'warmComplete': next(s for s in snapshots if s.get('stage') == 'warm-complete'),
    'pageConsoleErrors': d['page_console_errors'],
    'loadingFailures': [r['failure'] for r in requests.values() if 'failure' in r],
    'rangeRequests': [r for r in requests.values() if any(k.lower() == 'range' for k in r.get('requestHeaders', {}))],
    'interpretation': 'Cold assets continuously received and finished successfully; no extension/game exception or network failure observed. Dominant elapsed stage is large response delivery. This does not identify whether upstream/CDN/proxy/network is causal, or promise other-network speed.',
}
output = root / 'input-public-network-analysis-oct11.json'
output.write_bytes((json.dumps(out, indent=2) + '\n').encode('utf-8'))
print(json.dumps({'assets': [{k: r.get(k) for k in ['url', 'status', 'protocol', 'decodedBytes', 'encodedDataBytes', 'totalSeconds', 'bodySeconds', 'meanEncodedMiBPerSecond']} for r in assets], 'cold': out['coldComplete']['timings'], 'warm': out['warmComplete']['timings'], 'errors': out['pageConsoleErrors'], 'failures': len(out['loadingFailures']), 'rangeRequests': len(out['rangeRequests'])}, indent=2))
