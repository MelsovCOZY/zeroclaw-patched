# zeroclaw-patched

[ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) release images with upstream fixes that are not in a release yet. The image is the official `ghcr.io/zeroclaw-labs/zeroclaw:<tag>-debian` with only the `zeroclaw` binary replaced by one built from the same tag plus `patches/`.

```
FROM ghcr.io/melsovcozy/zeroclaw-patched:v0.9.0-pr12479
```

## Patches

| Patch | Upstream | Fixes |
| --- | --- | --- |
| `0001-anthropic-thinking-drop-block-pr12479.patch` | [PR #12479](https://github.com/zeroclaw-labs/zeroclaw/pull/12479) (head `046482eb`) | [#12401](https://github.com/zeroclaw-labs/zeroclaw/issues/12401): multi-turn chats with Claude 5 models (Haiku/Sonnet/Opus 5.5, Fable 5.1+) fail with 400 "Invalid `signature` in `thinking` block" after the runtime edits history. The patch sends `thinking.block_binding.prefix_mismatch_behavior = "drop_block"` (beta `thinking-binding-controls-2026-08-01`). |

The PR targets master; five hunks that did not apply to v0.9.0 were ported by hand. They are test-only (`#[cfg(test)]` builder fields and test struct literals). Verified with `cargo check -p zeroclaw-providers --tests` and the crate's `binding`/`thinking` unit tests (96 passed) on v0.9.0.

## Build

GitHub Actions builds and pushes on every change to `Dockerfile`, `patches/` or the workflow, or by hand (Actions → build → Run workflow). The release build takes about 30–60 minutes. Tags: `<ZEROCLAW_REF>-<PATCHSET>` and the same with the commit SHA appended.

To move to a new ZeroClaw release: update `ZEROCLAW_REF` in the workflow and the Dockerfile defaults, the Rust base image to the one the new `Dockerfile.debian` pins, and drop any patch that the release already contains. When no patches remain, use the official image directly and archive this repo.
