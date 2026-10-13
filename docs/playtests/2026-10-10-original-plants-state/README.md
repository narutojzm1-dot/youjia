# #642 original-plant state candidate — 2026-10-10

Agent-ID: CODEX-LEAD. Base main `becd1f47b03b43cb3f297da178c245f0fd855446`. Branch `codex/lead-flower-original-state-642`.

**Not a playable or published garden feature.** No production edit entry or rendering changed. This is the confirmation/persistence part of the original-composition removal/restoration slice; it remains Draft until art, UI and photo integration are ready.

## Implemented

- `yard_original_plants` is a bounded, independent root extension for the three original painted compositions (left cluster, door pots, pond cluster), separate from the three old keepsake slots and food inventory.
- Missing extension means untouched legacy painting. The first edit records initialization and removal in the same FIFO transaction; there is no eager migration that can re-grow explicitly removed areas. Removal exposes the already-owned original group in an availability projection; restoration reserves that same original. No count is added to keepsakes, no flower species, discovery weight, refresh period or new-garden capacity is introduced.
- Strict known schema/keys/unique area validation. Present corrupt/future records block related writes and retain their original bytes. All unrelated root fields are copied, including old decor offsets, album/photo data, plant bed, in-flight exploration and future extensions.
- SaveStore API evaluates at shared Coordinator queue head with expected revision. Typed GARDEN rejection codes survive classification. Stale/double clicks do not duplicate ownership.
- Controller view reads only confirmed state; completed signal occurs only for its matching commit receipt. Unknown result freezes editing and resolves the same operation. Proven failure retains retry proposal. Semantic refusal releases the invalid selection.

## Actual validation

Windows native Godot 4.7.2; every state suite uses a fresh isolated APPDATA and YOUJIA_TEST_ISOLATED_DATA directory. Production SaveStore, SaveCoordinator, NativeSaveHost and actual file reopen are used, not a MemoryStore success stub.

- [Original plants](native.log): 86 checks, zero failures. Includes all three areas, absent/explicit-empty, repeated and FIFO stale edits, restore, root-field preservation, future/malformed schema, actual temporary-path write failure in both directions, same-identity resolve, explicit retry and confirmed-only controller notices.
- [Trip capacity](capacity.log): 48/0. [Old decor](decor-fresh.log): 19/0. [Coordinator](coordinator.log): 86/0. [Save feedback](save-feedback.log): 50/0.
- Test development initially compared typed in-memory Dictionaries with parsed JSON number types; corrected expectations to compare canonical decoded JSON. A decor run reused the capacity fixture and failed 8/19 due to pre-existing data; a fresh isolated decor run passed 19/0. The failing reused run is not counted as a passed regression.
- Daily suite entry and exact completion marker registered. No new completion format.

## Remaining integration and art

Previous local seven-asset candidate remains `010c5908bb0bd53856efb4fcaf050060dba9b2ff`. The left crop was too narrow, and the first elliptical mask left iris remnants. A broader 370×440-source crop was edited with built-in imagegen into a separate v2 candidate, preserving original production texture files. GPU full-context compositing still needs edge/registration acceptance and a corresponding overcast variant. Never treat these preview candidates as accepted production resources.

Before Ready: finish removal without remnants or seams in sun/overcast; wire real edit/basket entry without touching Cursor #698 hotbar methods; freeze new-photo layout and patches while keeping old texture paths/bytes; verify normal Web operation and real tab close/reopen; validate new collected-flower definitions with Assistant nearpath integration. No old-photo, physical mobile, browser IndexedDB garden interaction, audio or export acceptance is claimed here. #642 and the overall Goal remain incomplete. This is not the 23:00 daily release and no outgoing email was sent.
