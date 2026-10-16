#!/usr/bin/env python3
"""#749 隔离 Web 探针专用静态服务器（仍只是候选工具，不服务主游戏）。

自己 bind(127.0.0.1, 0) 并一直持有这个监听 socket，没有"先探端口再交给别的进程"的移交窗口；
真正绑定到的端口写进 --port-file。另外 GET /__probe_server_id 返回启动时给的 --server-id，
web_export_check.sh 用它确认这个端口上应答的就是本轮这台服务器。
"""
import argparse
import functools
import http.server
import os


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--directory", required=True)
    ap.add_argument("--port-file", required=True)
    ap.add_argument("--server-id", required=True)
    a = ap.parse_args()
    server_id = a.server_id.encode()

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
