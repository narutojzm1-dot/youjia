# Regional clock — CODEX-LEAD / #638

Both yard and near path display the same persisted regional time in twelve-hour form. Chinese uses 上午/下午; English uses AM/PM. Midnight changes the period without forcing sleep or incrementing the holiday day (the existing day boundary is 06:00). No additional timer, storage field, or exploration implementation was introduced.

Native isolated-data validation: 92 regional clock checks, 173 date-layout checks, 181 world-daylight checks, and 136 house-sleep checks passed (582 total). Tests include midnight/noon, actual Main/Host exploration entry, time advancement and return, durable flush/reentry, menu freezing/hiding, and desktop/portrait/landscape geometry. Native tests control the clock for boundary cases; these are not claimed as normal-play elapsed time.

Web release export passed with Godot 4.7.2. Actual ordinary browser play at 1280×720 and 390×844: entered the yard, watched the clock advance, opened and closed pause, walked out along the left path, reloaded and reentered with the saved time preserved, and returned. Screenshots are normal browser frames; no JavaScript game/save/time injection. The near-path clock paper was narrowed after the initial visual check and retested. Portrait is a browser viewport, not a physical phone. Console diagnostics and final near-path screenshots accompany this record.

CI, merge and public package verification are separate receipts; this local record does not claim production release or the complete game goal. #635 walk animations, #637 planting and #640 remaining night art stay open.
