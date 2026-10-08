#!/usr/bin/env bash
# 将 Godot Web 导出产物发布到 gh-pages 分支
#
# 使用方式:
#   bash tools/publish_gh_pages.sh [commit-sha]
#
# 如不提供 commit-sha，则使用当前 HEAD 的短 SHA。
# 导出产物来自 dist/ 目录（export_path = dist/index.html）。
#
# 本脚本完成以下任务:
#   1. PCK 使用 game-{sha}，相同引擎字节使用稳定的 engine-{content-hash}
#   2. executable 指向引擎，mainPack 独立指向本次游戏资源包
#   3. script.src 与音频 worklet 使用同一引擎内容版本
#   4. fileSizes 使用实际引擎/资源包名称，保留旧 game/index 链接
#   5. 注入 cache-control meta 标签，对抗浏览器/CDN 缓存 index.html
#   6. 将所有文件推送到 gh-pages 分支
#   7. 自动剪除超出 KEEP_BUNDLES 数量的旧 game-* 资源包（默认保留最近 4 个）
#
# 环境变量:
#   KEEP_BUNDLES=N  保留最近 N 组 game-* 资源包（默认 4）；设 0 则不剪除

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
SHA="${1:-$(git -C "$REPO_ROOT" rev-parse --short HEAD)}"
ENTRY="game-${SHA}"
KEEP_BUNDLES="${KEEP_BUNDLES:-4}"

echo "[publish] source commit: ${SHA}"
echo "[publish] bundle entry name: ${ENTRY}"

# 确认 dist/ 存在且有导出产物
if [[ ! -f "$DIST_DIR/index.html" ]]; then
    echo "[publish] ERROR: dist/index.html not found. Run Godot Web export first." >&2
    exit 1
fi
if [[ ! -f "$DIST_DIR/index.js" ]]; then
    echo "[publish] ERROR: dist/index.js not found. Godot export may have failed." >&2
    exit 1
fi

# ---- 准备工作目录 ----
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
echo "[publish] staging in $WORK_DIR"

# 复制静态文件（不重命名）
for f in index.html; do
    cp "$DIST_DIR/$f" "$WORK_DIR/$f"
done

# 复制并重命名 index.* → game-{sha}.*（以及保留 index.* 作为 symlink-level alias）
for ext in js wasm pck \
           audio.worklet.js audio.position.worklet.js \
           icon.png apple-touch-icon.png png; do
    src="$DIST_DIR/index.${ext}"
    if [[ -f "$src" ]]; then
        cp "$src" "$WORK_DIR/${ENTRY}.${ext}"
        # 也保留 index.* 让旧链接仍可访问（内容与 game-{sha}.* 完全相同）
        cp "$src" "$WORK_DIR/index.${ext}"
    fi
done

# Pin every module and its relative imports to the same source build.
MODULE_ENTRY="save-${SHA}"
mkdir -p "$WORK_DIR/$MODULE_ENTRY"
cp "$REPO_ROOT"/web/save/*.mjs "$WORK_DIR/$MODULE_ENTRY/"
BOOT_ENTRY="boot-${SHA}"
mkdir -p "$WORK_DIR/$BOOT_ENTRY"
cp "$REPO_ROOT"/web/boot/*.mjs "$WORK_DIR/$BOOT_ENTRY/"
printf '*.mjs -text\n' > "$WORK_DIR/$BOOT_ENTRY/.gitattributes"

# ---- 修补 index.html 中的三处关键配置 ----
HTML="$WORK_DIR/index.html"
sed -i "s|./web/save/|./${MODULE_ENTRY}/|g" "$HTML"
sed -i "s|./web/boot/|./${BOOT_ENTRY}/|g" "$HTML"

# 0. 注入 Cache-Control meta，防止浏览器将 index.html 长期缓存（gh-pages 无自定义响应头）
#    只在尚未注入时才添加，避免重复发布时重复插入。
if ! grep -q 'Cache-Control.*no-cache' "$HTML"; then
    sed -i 's|<meta charset="utf-8">|<meta charset="utf-8">\n  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n  <meta http-equiv="Pragma" content="no-cache">\n  <meta http-equiv="Expires" content="0">|' "$HTML"
    echo "[publish] injected cache-control meta into index.html"
fi

# Reuse engine bytes across code-only releases. Both generated worklets and
# WASM belong to this content hash; startGame loads the separate mainPack.
python3 "$REPO_ROOT/tools/stage_web_engine.py" "$DIST_DIR" "$WORK_DIR" "$ENTRY"

# 4. icon href 已由导出过程正确设置；如有需要也修补
sed -i "s/href=\"index\.icon\.png\"/href=\"${ENTRY}.icon.png\"/" "$HTML"
sed -i "s/href=\"index\.apple-touch-icon\.png\"/href=\"${ENTRY}.apple-touch-icon.png\"/" "$HTML"

# 5. 注入 cache-control meta 标签至 <head>
# GitHub Pages CDN (Fastly) 默认缓存 HTML；meta 标签可降低浏览器层缓存的生命周期
# 同时用 data-build 属性将版本 SHA 嵌入 <html> 根节点，便于控制台快速核验
sed -i "s|<html|<html data-build=\"${ENTRY}\"|" "$HTML"
sed -i "s|<head>|<head>\n  <meta http-equiv=\"Cache-Control\" content=\"no-cache, must-revalidate, max-age=0\">\n  <meta http-equiv=\"Pragma\" content=\"no-cache\">|" "$HTML"

echo "[publish] cache-control meta tags injected; data-build=${ENTRY}"

# 验证三处均已替换
echo "[publish] verifying HTML patches..."
python3 - "$HTML" "$ENTRY" "$WORK_DIR/engine-assets.json" <<'PYEOF'
import sys, json, re

html_path = sys.argv[1]
entry = sys.argv[2]
content = open(html_path, encoding='utf-8').read()
engine = json.load(open(sys.argv[3]))['entry']

# 提取 config 对象
m = re.search(r'const config = ({.*?});', content)
if not m:
    print("ERROR: could not find config in HTML", file=sys.stderr)
    sys.exit(1)
cfg = json.loads(m.group(1))

errors = []
if cfg.get('executable') != engine or cfg.get('mainPack') != f'{entry}.pck':
    errors.append('engine/mainPack do not match this staged build')

file_sizes = cfg.get('fileSizes', {})
pck_key = f"{entry}.pck"
wasm_key = f"{engine}.wasm"
if pck_key not in file_sizes:
    errors.append(f"fileSizes missing key '{pck_key}' (got: {list(file_sizes.keys())})")
if wasm_key not in file_sizes:
    errors.append(f"fileSizes missing key '{wasm_key}'")

if f"script.src = '{engine}.js'" not in content:
    errors.append('script.src does not match engine bytes')

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
else:
    print(f"[publish] HTML verification passed: executable={engine}, mainPack={entry}.pck, fileSizes keys correct")
PYEOF

# ---- 更新 game-release.json ----
RELEASE_JSON="$WORK_DIR/game-release.json"
if [[ -f "$DIST_DIR/../site/game-release.json" ]]; then
    cp "$DIST_DIR/../site/game-release.json" "$RELEASE_JSON"
fi
# 检测 Godot 引擎版本：优先 $GODOT 环境变量，再尝试 PATH 中的 godot，最后回退 unknown
_detect_engine_version() {
    for _bin in "${GODOT:-}" godot4 godot /tmp/Godot_v4.7.2-stable_linux.x86_64; do
        [[ -z "$_bin" ]] && continue
        if command -v "$_bin" &>/dev/null || [[ -x "$_bin" ]]; then
            _ver="$("$_bin" --version 2>/dev/null || true)"
            if [[ -n "$_ver" ]]; then echo "$_ver"; return; fi
        fi
    done
    echo "unknown"
}
ENGINE_VERSION="$(_detect_engine_version)"
echo "[publish] engine version: ${ENGINE_VERSION}"

cat > "$RELEASE_JSON" <<JSON
{
  "schema": "youjia.release/v1",
  "sourceCommit": "$(git -C "$REPO_ROOT" rev-parse HEAD)",
  "engine": "${ENGINE_VERSION}",
  "entry": "${ENTRY}",
  "publishedAt": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
JSON

# The manifest lists hashes of the actual published module bytes.
python3 - "$RELEASE_JSON" "$WORK_DIR/$MODULE_ENTRY" "$MODULE_ENTRY" <<'PYMODULE'
import hashlib, json, pathlib, sys
manifest, directory, entry = sys.argv[1:]
p = pathlib.Path(manifest)
v = json.loads(p.read_text())
v['storageModules'] = {'entry': entry, 'sha256': {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(pathlib.Path(directory).glob('*.mjs'))}}
p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + '\n')
PYMODULE
python3 - "$RELEASE_JSON" "$WORK_DIR/engine-assets.json" "$WORK_DIR/$BOOT_ENTRY" "$BOOT_ENTRY" <<'PYBOOT'
import hashlib, json, pathlib, sys
manifest, engine, directory, entry = sys.argv[1:]
p = pathlib.Path(manifest)
v = json.loads(p.read_text())
v['engineAssets'] = json.loads(pathlib.Path(engine).read_text())
v['loaderModules'] = {'entry': entry, 'sha256': {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(pathlib.Path(directory).glob('*.mjs'))}}
p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + '\n')
pathlib.Path(engine).unlink()  # Staging metadata belongs in the release manifest.
PYBOOT

# ---- 推送到 gh-pages ----
echo "[publish] switching to gh-pages branch..."
cd "$REPO_ROOT"
git fetch origin gh-pages:refs/remotes/origin/gh-pages

# 检出 gh-pages（orphan-safe）
GH_PAGES_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR" "$GH_PAGES_DIR"' EXIT
git worktree add "$GH_PAGES_DIR" origin/gh-pages

# 复制新产物到 gh-pages 工作目录
cp -R "$WORK_DIR"/* "$GH_PAGES_DIR/"
touch "$GH_PAGES_DIR/.nojekyll"
# The URL hash describes exact engine bytes, including line endings.
touch "$GH_PAGES_DIR/.gitattributes"
if ! grep -Fxq 'engine-*.js -text' "$GH_PAGES_DIR/.gitattributes"; then
    printf '\nengine-*.js -text\n' >> "$GH_PAGES_DIR/.gitattributes"
fi

# ---- 剪除旧 game-* 资源包（可选，由 KEEP_BUNDLES 控制）----
# 以 .pck 为锚点，按 gh-pages 实际发布历史保留当前与最近版本。
cd "$GH_PAGES_DIR"
if [[ "${KEEP_BUNDLES}" -gt 0 ]]; then
    # Git commit spelling carries no timestamp. Select from actual Pages
    # publication history, protecting this staged bundle before any deletion.
    PRUNE_LIST="$(python3 "$REPO_ROOT/tools/select_web_bundle_pruning.py" "$ENTRY" "$KEEP_BUNDLES")"
    if [[ -n "$PRUNE_LIST" ]]; then
        mapfile -t DELETE_BUNDLES <<< "$PRUNE_LIST"
        echo "[publish] pruning ${#DELETE_BUNDLES[@]} old bundle(s), retaining current and recent publications..."
        for OLD in "${DELETE_BUNDLES[@]}"; do
            echo "[publish]   removing ${OLD}.*"
            rm -f "${OLD}".*
        done
    else
        echo "[publish] no proven old bundles to prune."
    fi
else
    echo "[publish] KEEP_BUNDLES=0, skipping pruning."
fi

cd "$GH_PAGES_DIR"
git add -A
git commit -m "Publish $(git -C "$REPO_ROOT" log --oneline -1 | sed 's/^[a-f0-9]* //'|head -c 80) (${SHA})" \
    --author="Cursor Agent <cursoragent@cursor.com>"
git push origin HEAD:gh-pages

git -C "$REPO_ROOT" worktree remove --force "$GH_PAGES_DIR"

# ---- 摘要报告 ----
echo "[publish] ✓ done."
echo "[publish]   entry:  ${ENTRY}"
echo "[publish]   pages:  https://narutojzm1-dot.github.io/youjia/"
echo "[publish]   verify: document.documentElement.dataset.build in browser console should equal '${ENTRY}'"
