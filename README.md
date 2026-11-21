# zeroclaw-patched

[ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) release images with upstream fixes that are not in a release yet. The image is the official `ghcr.io/zeroclaw-labs/zeroclaw:<tag>-debian` with only the `zeroclaw` binary replaced by one built from the same tag plus `patches/`.

```
FROM ghcr.io/melsovcozy/zeroclaw-patched:v0.9.0-pr12479-zt1
```

## Patches

| Patch | Upstream | Fixes |
| --- | --- | --- |
| `0001-anthropic-thinking-drop-block-pr12479.patch` | [PR #12479](https://github.com/zeroclaw-labs/zeroclaw/pull/12479) (head `046482eb`) | [#12401](https://github.com/zeroclaw-labs/zeroclaw/issues/12401): multi-turn chats with Claude 5 models (Haiku/Sonnet/Opus 5.5, Fable 5.1+) fail with 400 "Invalid `signature` in `thinking` block" after the runtime edits history. The patch sends `thinking.block_binding.prefix_mismatch_behavior = "drop_block"` (beta `thinking-binding-controls-2026-08-01`). |

| `0002-telegram-readability-anthropic-extra-body.patch` | none (local) | Telegram and Anthropic changes, listed below. |

`0002` changes:

- **Telegram link previews off.** Every `sendMessage` / `editMessageText` body sets `link_preview_options.is_disabled = true`, so a URL in a reply or a tool notification no longer expands into a large preview card. There is no config knob for this in v0.9.0.
- **Tool notifications.** With `show_tool_calls`, a `path` or `url` argument is shown as a code span (Telegram does not auto-link it) and cut at 200 chars; empty arguments (`{}`) are no longer shown.
- **Telegram command menu.** Tools are no longer registered as slash commands unless `ZEROCLAW_TELEGRAM_TOOL_COMMANDS=1`. With MCP servers attached, the tool list overflows Telegram's limit and `setMyCommands` fails with `BOT_COMMANDS_TOO_MUCH`, leaving a stale menu. Built-in commands and skills are still registered.
- **Telegram Markdown rendering.** `> ` lines become a `<blockquote>` and `- ` / `* ` list markers become `•` (outside code blocks); before, both reached the chat as raw symbols.
- **Telegram system-prompt hint.** Dropped "use emoji naturally" and the `web_fetch` mention (the tool may be disabled), which contradicted bots configured without them.
- **Anthropic `provider_extra`.** The native Anthropic provider now merges `[providers.models.<alias>] provider_extra` into every Messages request body (keys the request already sets win). This reaches API fields the provider does not model yet, e.g. `provider_extra = { output_config = { effort = "high" } }`. Before, `provider_extra` was honored only by OpenAI-compatible providers.

Verified on v0.9.0 with `cargo check` and the unit tests for the touched paths (`telegram_markdown_to_html*`, `channel_notify_observer*`, `register_bot_commands*`, and the `anthropic` provider tests).

The PR #12479 port: the PR targets master; five hunks that did not apply to v0.9.0 were ported by hand. They are test-only (`#[cfg(test)]` builder fields and test struct literals). Verified with `cargo check -p zeroclaw-providers --tests` and the crate's `binding`/`thinking` unit tests (96 passed) on v0.9.0.

## Build

GitHub Actions builds and pushes on every change to `Dockerfile`, `patches/` or the workflow, or by hand (Actions → build → Run workflow). The release build takes about 30–60 minutes. Tags: `<ZEROCLAW_REF>-<PATCHSET>` and the same with the commit SHA appended.

To move to a new ZeroClaw release: update `ZEROCLAW_REF` in the workflow and the Dockerfile defaults, the Rust base image to the one the new `Dockerfile.debian` pins, and drop any patch that the release already contains. When no patches remain, use the official image directly and archive this repo.
