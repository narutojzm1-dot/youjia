# PR444 preliminary independent review — not final approval

Reviewer: CODEX-LEAD-REVIEW-SOFT444 (/root/leader_scope_audit)
Read-only sample: original cda5ab8ded8384f3f3b7bfeccf996652b65a1a9c; integration runtime14a85a532f9510306b7921b9daa23409d17799c6; base a99660937ef2942779d9cf217079559611616efa.

No runtime blocker found in the sampled patch. Production diff is limited to Main._soft_button and new _soft_focus_ring, retaining existing behaviour, input routes, button dimensions, font sizes, disabled defaults and _text_button. Main._build_hud still sets all four chip buttons FOCUS_NONE. Final commit/tree, final logs and candidate browser evidence have not yet been reviewed; this is NOT APPROVE.

Font_focus and font_pressed now use existing INK. Hover uses the same prior RGB via existing TEXT_LINK_HOVER; hover_pressed becomes the same dark hover text. Unfilled focus style adds an external two-pixel border without covering the normal/hover/pressed fill. Existing normal border radius16 + outside expansion2 is matched by focus radius18; style changes do not expand control hit bounds or minimum size.

Independent Python linear-sRGB math (not rendered pixel measurement): ring #a85d28 vs CREAM=4.73944; PAPER=4.59938; 84%PAPER over black=3.17798. Text normal/focus=8.49996, pressed=6.20348, hover=10.96114, hover_pressed=9.22368. Alpha assumptions in these calculations match specified opaque colours; screenshots remain required for clipping/actual rendered state.

Suite covers concrete contrast outcomes rather than exact palette mirrors and includes internal scene focus/state transitions; these are valuable numeric/geometry regressions, not human or browser input. It invokes grab_focus and pressed.emit, so the statement of real input must rely on separate browser evidence. The font-size assertion allows any explicit override; that is weak as a frozen typography test but not material here because production font-size code is unchanged.

Coverage caveat reported to parent: _panel_backgrounds searches ancestor PanelContainer only. Title _title_card is a sibling Panel, hence the 5080-count suite does not itself verify 84%-title-paper against black even though the numerical colour is safe. Integration must disclose this, correct the claim, or add a direct actual-title-card background check. Explicit inactive-button styles are unmodified; no disabled readability/product change is claimed. No Godot or browser launched by reviewer, preserving the implementer's single validation window.
