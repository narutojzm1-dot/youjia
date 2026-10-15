"""Test response observer only: python server.py <Web export dir> <output dir>."""
import http.server, pathlib, sys, json, time
root=pathlib.Path(sys.argv[1]).resolve()
out=pathlib.Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=True)
probe=(pathlib.Path(__file__).parent/'observer.js').read_bytes()
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(root),**kw)
    def end_headers(self):
        self.send_header('Cache-Control','no-store');super().end_headers()
    def do_GET(self):
        if self.path=='/ui704-probe.js':
            self.send_response(200);self.send_header('Content-Type','text/javascript');self.end_headers();self.wfile.write(probe);return
        if self.path.split('?')[0] in ['/','/index.html']:
            body=(root/'index.html').read_bytes().replace(b'<head>',b'<head><script src="/ui704-probe.js"></script>',1)
            self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.end_headers();self.wfile.write(body);return
        super().do_GET()
    def do_POST(self):
        if self.path!='/__probe':self.send_error(404);return
        body=self.rfile.read(int(self.headers['Content-Length']));json.loads(body)
        (out/('web-probe-'+str(time.time_ns())+'.json')).write_bytes(body)
        self.send_response(204);self.end_headers()
http.server.ThreadingHTTPServer(('127.0.0.1',8174),Handler).serve_forever()
