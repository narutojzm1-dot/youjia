# #167 公开三尺寸加载与失败/重试复验

CODEX-LEAD-ASSISTANT，原单先登记5991049665，不改加载壳或Main。三个全新Chromium context：1280×720、390×844、844×390均实际game-a75ae22/source a75ae229430ef4f0329953af70e213ca7d59d622。构建Actions/Pages与三资源完整字节/hash证明见[公开版本](../2026-10-05-fish-miss-release/README.md)。不同后续main不冒本次被测构建。

为保留加载画面截图，在各冷context真实WASM请求加明确4秒受控延迟，不伪造引擎/加载状态。实际小院水彩背景、标题、进度、版本号三尺寸可读；加载完真实youjia:first-frame到达、loading.hidden，JS/WASM/PCK HTTP200，标题后按真实鼠标入院，三张院内截图均实际查看。桌面/竖屏/横屏errors=[]。result.json分别记录真实资源URL/HTTP、加载文字、firstFrame和hidden。界面标识的58.6MiB是解压后资源，不当公网网络传输量；不是稳定加载性能样本或手机真机。

故障/重试另用独立冷context：明确一次engine-bootstrap JS请求网络abort，真实加载壳显示“游戏加载失败，请重试。”、具体错误、可见“重试”。实际点DOM重试按钮reload，第二次请求放行，真实首帧后加载壳隐藏并进入标题。1280-injected-failure / 1280-retry-title原图已查看；两条console错误是本次受控网络故障预期记录，不算自然生产故障。原先一次PCK abort未获得失败按钮（可能自重试），该未成功测试假设不算产品门禁失败；没有冒PCK错误路径已覆盖。failure-retry-browser.py.txt为本次独立失败/重试执行，前三尺寸冷结果来自此前独立运行，脚本读取该cold-results而不冒同一进程。

原生不重复；实现PR329严格daily中的loading_shell、HiDPI102及三视口已过，不能代此公开步骤。GAME-QA独立完整体验/物理设备/低动效全路径仍未覆盖；父#167实现已发布但完整验收不因本有限检查自动关闭。图中假期日数的布局发现另由GROK/Leader划范围，不擅自改共享Main。
