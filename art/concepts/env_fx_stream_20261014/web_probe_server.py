#!/usr/bin/env python3
"""#749 隔离 Web 探针专用静态服务器（仍只是候选工具，不服务主游戏）。

自己 bind(127.0.0.1, 0) 并一直持有这个监听 socket，没有"先探端口再交给别的进程"的移交窗口；
真正绑定到的端口写进 --port-file。另外 GET /__probe_server_id 返回启动时给的 --server-id，
web_export_check.sh 用它确认这个端口上应答的就是本轮这台服务器。

可选 --upload-dir（仅 web_matrix_20261017/run_web_matrix.sh 使用；不给时行为与原来完全相同，POST 一律 405）：
浏览器把真实画布读回的无损 PNG 以 POST /__upload?name=..&sha256=..&build_id=.. 发来；
服务器复算 SHA256，与页面自报值不一致、文件名不合规、已存在（不覆盖）或 build_id 不符都拒收，
通过的写进 upload-dir，并逐条追加到 upload-dir/uploads.jsonl。
"""
import argparse
import functools
import hashlib
import http.server
import json
import os
import re
import threading
import urllib.parse

NAME_RE = re.compile(r"^[A-Za-z0-9_.-]{1,96}\.(png|json)$")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--directory", required=True)
    ap.add_argument("--port-file", required=True)
    ap.add_argument("--server-id", required=True)
    ap.add_argument("--upload-dir", default="")
    ap.add_argument("--build-id", default="", help="与 --upload-dir 同用：只收该 build_id 的上传")
    a = ap.parse_args()
    server_id = a.server_id.encode()
    lock = threading.Lock()

    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):  # noqa: N802
            if self.path == "/__probe_server_id":
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(server_id)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(server_id)
                return
            super().do_GET()

        def _reply(self, code, text):
            body = text.encode()
            self.send_response(code)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_POST(self):  # noqa: N802
            u = urllib.parse.urlsplit(self.path)
            if not a.upload_dir or u.path != "/__upload":
                return self._reply(405, "uploads disabled")
            q = urllib.parse.parse_qs(u.query)
            name = q.get("name", [""])[0]
            want = q.get("sha256", [""])[0].lower()
            bid = q.get("build_id", [""])[0]
            if not NAME_RE.match(name):
                return self._reply(400, "bad name")
            if a.build_id and bid != a.build_id:
                return self._reply(403, "build_id mismatch")
            n = int(self.headers.get("Content-Length", "0"))
            data = self.rfile.read(n)
            got = hashlib.sha256(data).hexdigest()
            if len(data) != n or got != want:
                return self._reply(422, f"sha256 mismatch {got}")
            path = os.path.join(a.upload_dir, name)
            with lock:
                if os.path.exists(path):
                    return self._reply(409, "exists")
                with open(path, "xb") as f:
                    f.write(data)
                with open(os.path.join(a.upload_dir, "uploads.jsonl"), "a") as f:
                    f.write(json.dumps({"name": name, "sha256": got, "bytes": n, "build_id": bid}) + "\n")
            return self._reply(200, got)

        def end_headers(self):
            # 不让浏览器沿用旧导出的缓存。
            self.send_header("Cache-Control", "no-store")
            super().end_headers()

    handler = functools.partial(Handler, directory=a.directory)
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    port = httpd.server_address[1]
    tmp = a.port_file + ".tmp"
    with open(tmp, "w") as f:
        f.write(f"{port}\n")
    os.replace(tmp, a.port_file)
    print(f"serving {a.directory} on 127.0.0.1:{port}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
