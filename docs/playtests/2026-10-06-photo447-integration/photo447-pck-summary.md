# Independent PCK inventory audit for PR447 candidate

Comparison: earlier gate130 package (398 entries,27,088,652 bytes) against photo447 candidate852 (394 entries,27,076,376 bytes). Parsed actual PCK v4 directories and independently validated every member payload against its stored MD5; payload SHA256 comparison retained in `photo447-pck-independent.json`.

Only removed entries are tracked root metadata files omitted by the isolated sparse checkout: `template-provenance.json`10886B, `game-sharing.json`775B, `template.json`433B, `game-verification.json`344B. Their total12,438B accounts for the reduction with +437B compiled PhotoArrival change and pack padding/index differences; total file reduction12,276B. Export preset/filter is unchanged. No reference to these names occurs in the852 runtime scripts/autoload/scenes/web/config/project.godot tree. This does not identify a missing gameplay asset.

390 remaining members have identical payloads, including textures/audio/fonts/config/localization/storage-related runtime code. The other four changed members are `scripts/ui/photo_arrival.gdc` and three equal-sized exported scenes. Each scene differs at only a four-byte `node_ids` packed-int value; all other payload bytes are identical. No scene/resource path disappears.

This is a sparse local candidate, not byte-for-byte proof for a future full-checkout export. Public deployment must still be verified using its own manifest and actual package. Candidate natural-photo screenshots apply to the exact852 package hash812144231f60d96c5b565d0cf735982b356e2efece0eeb0d4ffde865b600e030, not a predicted future release hash. No package/source image was edited during review.
