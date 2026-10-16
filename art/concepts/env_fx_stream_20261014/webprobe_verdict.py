#!/usr/bin/env python3
"""#749 Web 探针判定：把浏览器日志里的 WEBPROBE 结果解析为 JSON，只看顶层字段。

不用全文子串匹配（缩放子项里也有 "ok":true，会把顶层失败误判为通过）。
规则：日志里必须恰好一条可解析的 WEBPROBE 对象；顶层 ok 必须是布尔 true；
build_id 必须是字符串且等于本轮导出值；需要缩放子集时，顶层 scale_subpixel_ok 必须是布尔 true，
scale_subpixel 必须是两项、每项 ok 为布尔 true（与顶层互相印证）。缺失、类型不对、多条或无法解析都判失败。
用法：python3 webprobe_verdict.py --log LOG --build-id ID [--no-scale]
      python3 webprobe_verdict.py --self-test
退出码 0 = 通过，非 0 = 失败（原因打印在 stderr）。
"""
import argparse
import json
import sys

MARK = "WEBPROBE "


def extract(text):
    """返回日志里所有 WEBPROBE 对象（dict）；遇到无法解析的条目抛 ValueError。"""
    dec = json.JSONDecoder()
    found = []
    pos = 0
    while True:
        i = text.find(MARK, pos)
        if i < 0:
            return found
        j = i + len(MARK)
        try:
            obj, end = dec.raw_decode(text, j)
        except json.JSONDecodeError as e:
            raise ValueError(f"WEBPROBE entry at offset {i} is not valid JSON: {e.msg}")
        if not isinstance(obj, dict):
            raise ValueError(f"WEBPROBE entry at offset {i} is not a JSON object")
        found.append(obj)
        pos = end


def verdict(text, build_id, need_scale=True):
    """返回 (passed, reason)。"""
    try:
        results = extract(text)
    except ValueError as e:
        return False, str(e)
    if not results:
        return False, "no WEBPROBE result in log"
    if len(results) > 1:
        return False, f"ambiguous: {len(results)} WEBPROBE results in log (expected exactly 1)"
    r = results[0]
    bid = r.get("build_id")
    if not isinstance(bid, str) or not bid:
        return False, "top-level build_id missing or not a string"
    if bid != build_id:
        return False, f"build_id mismatch (got {bid}, expected {build_id}): page did not load this run's export"
    if "ok" not in r:
        return False, "top-level ok missing"
    if r["ok"] is not True:
        return False, f"top-level ok is {json.dumps(r['ok'])} (must be boolean true)"
    if need_scale:
        if r.get("scale_subpixel_ok") is not True:
            return False, f"top-level scale_subpixel_ok is {json.dumps(r.get('scale_subpixel_ok'))} (must be boolean true)"
        cases = r.get("scale_subpixel")
        if not isinstance(cases, list) or len(cases) != 2:
            return False, "scale_subpixel must be a list of exactly 2 cases"
        for k, c in enumerate(cases):
            if not isinstance(c, dict) or c.get("ok") is not True:
                return False, f"scale_subpixel[{k}].ok is not boolean true"
    return True, "ok"


def _self_test():
    bid = "b" * 32
    good_case = {"scale": 0.75, "ok": True}

    def line(obj):
        return f'[1:2:INFO:CONSOLE(452)] "WEBPROBE {json.dumps(obj)}", source: http://127.0.0.1:1/index.js (452)\n'

    good = {"build_id": bid, "ok": True, "sequence_ok": True, "scale_subpixel_ok": True,
            "scale_subpixel": [good_case, dict(good_case, scale=2.0)]}
    cases = [
        ("valid top-level pass", line(good), True, True),
        ("valid pass, scale disabled", line({"build_id": bid, "ok": True}), False, True),
        # 审查点名的负例：顶层 ok:false、嵌套 ok:true、scale_subpixel_ok:true
        ("top ok false, nested ok true (sequence fail)", line(dict(good, ok=False, sequence_ok=False)), True, False),
        ("top ok false, 1:1 fail but scale pass", line(dict(good, ok=False)), True, False),
        ("top ok missing", line({k: v for k, v in good.items() if k != "ok"}), True, False),
        ("top ok string 'true'", line(dict(good, ok="true")), True, False),
        ("top ok number 1", line(dict(good, ok=1)), True, False),
        ("scale_subpixel_ok false", line(dict(good, scale_subpixel_ok=False)), True, False),
        ("scale_subpixel_ok missing", line({k: v for k, v in good.items() if k != "scale_subpixel_ok"}), True, False),
        ("scale_subpixel_ok string", line(dict(good, scale_subpixel_ok="true")), True, False),
        ("scale case ok false", line(dict(good, scale_subpixel=[good_case, dict(good_case, ok=False)])), True, False),
        ("scale cases wrong count", line(dict(good, scale_subpixel=[good_case])), True, False),
        ("build_id mismatch", line(dict(good, build_id="c" * 32)), True, False),
        ("build_id missing", line({k: v for k, v in good.items() if k != "build_id"}), True, False),
        ("build_id wrong type", line(dict(good, build_id=123)), True, False),
        ("no WEBPROBE line", "nothing here\n", True, False),
        ("malformed JSON", '"WEBPROBE {"ok":true,"build_id":', True, False),
        ("non-object JSON", 'WEBPROBE [{"ok":true}]\n', True, False),
        ("two results (ambiguous)", line(good) + line(good), True, False),
        ("pass + fail results (ambiguous)", line(good) + line(dict(good, ok=False)), True, False),
    ]
    bad = 0
    for name, text, need_scale, expect in cases:
        got, why = verdict(text, bid, need_scale)
        mark = "PASS" if got == expect else "FAIL"
        if got != expect:
            bad += 1
        print(f"{mark}  {name}: verdict={got} ({why})")
    print(f"self-test: {len(cases) - bad}/{len(cases)} as expected")
    return 0 if bad == 0 else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log")
    ap.add_argument("--build-id")
    ap.add_argument("--no-scale", action="store_true", help="WEBPROBE_SCALE=0 时不要求缩放子集")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return _self_test()
    if not a.log or not a.build_id:
        ap.error("--log and --build-id are required")
    with open(a.log, encoding="utf-8", errors="replace") as f:
        text = f.read()
    passed, why = verdict(text, a.build_id, not a.no_scale)
    print(f"WEBPROBE verdict: {'PASS' if passed else 'FAIL'} ({why})", file=sys.stderr)
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
