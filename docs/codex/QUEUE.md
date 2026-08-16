# RustDesk Mobile Actions Queue

Updated: 2026-08-11 Asia/Shanghai

## Now

- 移动端远程移动端交互 (RustDesk mobile actions): FFI/NAPI/ArkTS 实现完成于
  `codex/rustdesk-mobile-actions` 分支; 待 DevEco 环境运行 cargo 单测与
  `default@OhosTestCompileArkTS` + `assembleHap` 门禁。

## Next

- 真机验证 Android 被控端: 返回/主页/最近任务/音量/电源 可用; 非 Android
  对端不显示"移动设备操作"; 版本 < 1.2.7 对端不显示。
- 独立 review → push/PR/required check/merge → 回到同步 main。

## Later

- 若官方新增更多移动端操作 (如锁屏、截图), 按同一 Map-mode key code 通道扩展。
- 评估把移动设备操作区升级为可拖拽悬浮胶囊 (对齐官方 DraggableMobileActions)。
