# Current Handoff

This is the short handoff for resuming the active task. Completed task
handoffs and historical evidence are preserved in
`docs/codex/archive/2026-08/HANDOFF-legacy.md`.

## Resume Card

- Branch: `codex/rustdesk-mobile-actions`
- Head: `63fc37a1` (pushed to origin)
- Base: `main@aeb0cda`
- Working tree: clean.
- Current phase: implementation + three-layer independent review + cargo
  verification + C++ compile verification complete; PR #1 open
  (https://github.com/ramberlee/RemoteDeskHarmonyOS/pull/1).
- Verification (this environment, all PASS):
  - `cargo test` (default features) 194/194, `cargo test --no-default-features`
    184/184, `cargo test --release` 194/194, `cargo build` + `cargo build
    --release` (cdylib+staticlib, LTO) exit 0.
  - gcc 16.2 `-fsyntax-only` on rustdesk_ipc.h / protocol_adapter.h /
    rustdesk_bridge.h / rustdesk_bridge.cpp (ABI static_asserts + override
    matching evaluated).
  - Node 24 executed committed RustDeskMobileActionsPolicy.ets: 37/37.
- Review: three independent static reviews (Rust FFI, C++/NAPI, ArkTS) done;
  all findings fixed and committed. No unresolved findings.
- PR check: GitHub Actions has 0 runs on this repository (Actions not
  enabled); `open-source-compliance` must be confirmed manually or by enabling
  Actions. Pre-push hook (Light compliance) passed locally on every push.

## Remaining Before Merge (requires DevEco environment / maintainer)

1. Run Hvigor gates on a DevEco Studio machine (HarmonyOS commercial SDK
   6.1.0(23), Huawei-account distribution; not obtainable in this
   environment):
   - `default@OhosTestCompileArkTS` (module=entry, product=default)
   - `assembleHap` (module=entry, product=default)
   - Record exact outputs in CURRENT.md / STATE.json.
2. Real-device validation: connect an Android RustDesk peer (>= 1.2.7) and
   verify the 移动设备操作 grid (back/home/recent/volume/power) works via the
   top bar and the three-finger control panel; verify non-Android peers do not
   show it.
3. Confirm open-source-compliance (Actions disabled; run
   `verify_open_source_release.ps1 -Mode Light` manually if needed).
4. Merge PR #1, sync main (`pull --ff-only`), delete the merged branch.

## Source Of Truth

- Machine state: `docs/codex/STATE.json`
- Review receipts: `docs/codex/REVIEW_RECEIPTS.jsonl`
- Action queue: `docs/codex/QUEUE.md`
- Durable decisions: `docs/codex/DECISIONS.md` (D-025 = Map-mode chr wire contract)
- Historical records: `docs/codex/archive/2026-08/`
