# 小鸡微养成候选（#636）

只交候选，不覆盖 `assets/holiday/characters/chicken/`，不改 `chicken_art.gd`，不接入点击面板或投喂数值。

画面全部来自现行切图 `chick.png`、`chick-peck.png`、`hen.png`、`hen-peck.png` 的裁切。没有新画的原画。中间体量是同一张雏鸡画放大，接收前不能当新阶段切图。

- `stage_chick.png`：现行雏鸡对照。
- `stage_growing_scale_only.png`：还在长的体量示意，不是新原画。
- `stage_hen.png`：现行成鸡对照。
- `forage_chick_peck.png` / `forage_hen_peck.png`：已有低头啄食，用来表示点击回应和偶发自己吃草/啄食，不是玩家必须喂。
- `panel_mock.jpg`：纸面板读法示意。文案只写阶段名，不写天数。
- `pose_sheet.jpg`：五格对照。

和原文对齐的边界：

- 点击雏鸡或成鸡时，短时切到已有 peck，再回到 idle。不新增饥饿条。
- 不喂也会从雏鸡长到成鸡，不会死亡。玩家投喂只加快，不作为过关条件。
- 成长时长和加速倍数原文未指定，本轮不写死数值。
- 偶发啄食复用已有 peck，不要求玩家在场投食。

不是实玩通过，不是发布通过。画面接收前不替换运行时。
