# 入屋睡眠门洞候选

CODEX-LEAD，#565；使用内置imagegen生成，未接入、未发布。参考现有yard_sunny.png中的小屋拱门。下一步须按原门洞的实际位置、透视、遮挡与晴阴夜光色配准；不可整张替换小院背景。门开合、入屋行走、关灯、呼噜声和存档安全跳晨仍未实现。

v1生成；v2尝试去除外部光晕，仍须实际合成验证透明边缘，不因工具成功就算正式验收。原始输出不改写。

## v1完整提示

Use case: precise-object-edit. Asset type: transparent 2D painted game sprite for the open entrance of the existing alpine cottage. Input image is a style/architecture reference only: use the cottage's small round-arched oak front door below its balcony, preserve the rustic warm stone arch and narrow tall doorway proportions. Produce ONLY an isolated open version of that doorway, viewed from the same nearly straight-on, slightly elevated camera. The oak leaf is swung inward against the left interior wall. Through the doorway one can glimpse a cozy modest room with a wooden floor, a simple bed and a small bedside table, illuminated by soft amber lamplight. It should feel like the same intricately painted watercolor/gouache miniature, with granular paper-like pigment and restrained brush detail, not photorealistic or 3D. Keep all content inside a single tall narrow doorway and thin stone jamb, its outer width roughly 0.52 of its height, centered with transparent margin. Ground threshold straight, no exterior ground patch, no house facade, no garden, no text, no people, no animals, no extra doors or windows, no glowing border or giant lantern. The aperture contains painted interior, everything outside the thin door frame must have genuine alpha transparency. This is an inset for a precise existing scene; do not redraw the complete background.

## v2完整提示

Edit only the exterior transparency of this game doorway sprite. Preserve exactly the stone arch, inward-open wood door, room interior, furniture, colors, brushwork, framing and pixel dimensions. Remove ALL diffuse brown/amber/black haze or glow outside the solid stone arch and threshold. Everything outside the stone silhouette must be fully transparent alpha zero, including the gap around its outer edge. Keep the solid stone and interior opaque with clean fine antialiasing at the edge. Do not add a glow, background, shadow, floor patch, new object, text or border. Return a genuine transparent-background PNG.
