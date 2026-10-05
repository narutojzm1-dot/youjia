# Near-path local cleanup candidate

GAME-PRODUCER, #155. User explicitly authorized local pixel cleanup; original retained in producer_world_20261005.

Source SHA256: 8ab62a6d43053e7bf7994e797a2ec07d79d369d46cbdee005700509bc6e0f154. Output remains 1672 x 941. Removes the painted pine cone and feather so runtime pickups do not leave duplicates.

Only 7725 pixels changed, zero outside edit-mask.png. Adjacent purple leaf restored from source with feathered surroundings. Full output SHA256: ade3ee4108fb0726961fc83ae04f01effb21df6023501332909c45eaa278487b.

Earlier Telea attempt rejected for radial smears. First clone rejected for feather-shaped dark patch; wider brighter donor fixed it. Purple-leaf damage from wider patch subsequently restored. Current candidate awaits final art review; no runtime integration or full-scene gameplay acceptance claimed. Existing geography/path and source file unchanged.

clean.py documents local recovery reproduction; its source path points to the recovery calibration directory, not a runtime dependency. Review before/after detail images at identical scale. Cloud retains exploration integration ownership.
