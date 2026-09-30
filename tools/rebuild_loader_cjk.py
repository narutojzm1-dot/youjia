#!/usr/bin/env python3
"""Rebuild the loader WOFF2 subset so 悠长的假期 is covered."""
from __future__ import annotations

import base64
import hashlib
import json
import re
from pathlib import Path

from fontTools.subset import Subsetter, Options
from fontTools.ttLib import TTFont

ROOT = Path("/home/ubuntu/youjia")
SOURCE = ROOT / "assets/template/fonts/NotoSansSC-VF.subset.woff2"
LOADING = ROOT / "web/loading.html"
META = ROOT / "web/loader-cjk.json"
LICENSE = ROOT / "assets/template/fonts/NotoSansSC-OFL.txt"

EXISTING = (
    " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~…。"
    "下仍以到加动可启在失度待戏或新暂未正游的看等继续试请败载进重，"
)
EXTRA = "悠长的假期"


def main() -> None:
    corpus = "".join(sorted(set(EXISTING + EXTRA), key=lambda ch: ord(ch)))
    options = Options()
    options.layout_features = ["*"]
    options.desubroutinize = True
    options.hinting = False
    options.flavor = "woff2"
    font = TTFont(SOURCE)
    subsetter = Subsetter(options=options)
    subsetter.populate(text=corpus)
    subsetter.subset(font)
    out_path = ROOT / "web/.loader-cjk.woff2"
    font.save(str(out_path))
    data = out_path.read_bytes()
    out_path.unlink()
    b64 = base64.b64encode(data).decode("ascii")
    html = LOADING.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(/* manus-loader-cjk:start \*/.*?src:url\(data:font/woff2;base64,)([A-Za-z0-9+/=]+)(\) format\(\"woff2\"\))",
        re.S,
    )
    if not pattern.search(html):
        raise SystemExit("loading.html font payload not found")
    html = pattern.sub(lambda m: m.group(1) + b64 + m.group(3), html, count=1)
    html = html.replace('<html lang="en">', '<html lang="zh-CN">')
    html = html.replace('<html lang="zh-CN">', '<html lang="zh-CN">')
    html = html.replace(
        "      // No saved game preference is visible here: follow the browser's preferred language.\n"
        "      const zh = String((navigator.languages && navigator.languages[0]) || navigator.language || '').toLowerCase().startsWith('zh');\n"
        "      document.documentElement.lang = zh ? 'zh-CN' : 'en';\n",
        "      // Single-language holiday: pin Simplified Chinese on the loader.\n"
        "      const zh = true;\n"
        "      document.documentElement.lang = 'zh-CN';\n",
    )
    LOADING.write_text(html, encoding="utf-8")
    codepoints = sorted({ord(ch) for ch in corpus if ord(ch) >= 32})
    META.write_text(
        json.dumps(
            {
                "version": 2,
                "family": "Noto Sans SC",
                "role": "Complete loader face (Latin and Chinese); loader only",
                "source": {
                    "name": "Noto Sans SC",
                    "sha256": "38f4c5f927f746b3dfa4c3a5d7edf0b7a3e828e27438418fa54f9e1565289412",
                    "license": "OFL-1.1",
                    "licenseFile": "assets/template/fonts/NotoSansSC-OFL.txt",
                },
                "format": "woff2",
                "weights": [400, 700],
                "sha256": hashlib.sha256(data).hexdigest(),
                "bytes": len(data),
                "corpusSources": [
                    "web/loading.html",
                    "runtime shared loading-shell.html baseline",
                    "game title 悠长的假期",
                ],
                "codepoints": codepoints,
                "corpus": corpus,
                "generator": "tools/rebuild_loader_cjk.py (fontTools)",
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    if "SIL Open Font License" not in LICENSE.read_text(encoding="utf-8", errors="replace"):
        raise SystemExit("OFL notice missing")
    print("loader font", len(data), "bytes; extra glyphs", EXTRA)


if __name__ == "__main__":
    main()
