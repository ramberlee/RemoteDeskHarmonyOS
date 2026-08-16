# Shared Current State

## Active Task

- Task: `rustdesk-mobile-actions` — 移动端客户端远程移动端交互 (复刻 RustDesk 官方移动端操作)
- Base: `main@aeb0cda` (origin/main, clean before task)
- Branch: `codex/rustdesk-mobile-actions`
- Phase: implementation complete; build verification pending on DevEco machine.

## Context

- 本机 (HarmonyOS 客户端) 远程控制 Android 被控端时，之前只能发送桌面键盘码，
  不能发送 Android 导航键 (返回/主页/最近任务)。目标: 至少复刻 RustDesk 官方
  移动端客户端的 Back/Home/Apps/Volume/Power 操作。
- 线格式依据官方实现核实:
  - Android 被控端 `KeyEventConverter` (flutter/android/.../KeyboardKeyEventMapper.kt)
    在 `KeyboardMode::Map/Translate` 下把 `KeyEvent.chr` 当作 Android KeyEvent
    key code 注入; `control_key` 仅覆盖 VolumeMute/VolumeUp/VolumeDown/Power 等。
  - 官方移动端 `_getMobileActionMenus` 仅对 `pi.platform == "Android"` 且
    被控端版本 >= 1.2.7 显示 Back/Home/Apps/Volume/Power。
- 因此 FFI 新增 `rustdesk_send_mobile_key(handle, key_code, pressed)`，以
  Map-mode `chr` 发送 Android key code (3=HOME, 4=BACK, 187=APP_SWITCH,
  24/25=音量, 26=电源)，复用现有 `build_map_key_message`。
- FFI 新增 `rustdesk_get_peer_snapshot(handle, out)` 暴露对端
  platform/version (由 streaming 线程在 LoginResponse/PeerInfo 到达时发布)。
- NAPI 新增 `sendRustDeskMobileKey` / `getRustDeskPeerPlatform` /
  `getRustDeskPeerVersion`; ArkTS 侧新增 `RustDeskMobileActionsPolicy`、
  RemoteDesktop 对端身份轮询、RemoteSessionTopBar "移动设备操作" 区
  (2×3 网格: 返回/主页/最近任务/音量+/音量-/电源)。
- 可达性覆盖: Pad/PC 及手机键鼠模式经顶栏控制菜单; 手机触摸/触控板模式
  顶栏隐藏, 移动设备操作同时接入三指控制面板 (始终可达)。

## Scope

- rustdesk_ffi (lib.rs / connector.rs): ControlMsg::MobileKey、peer snapshot、
  线格式与测试。
- rustdesk_bridge.cpp/h、rustdesk_ipc.h (IPC 帧 0x14)、protocol_adapter.h
  (默认 no-op 虚函数)、extension_loader_napi.cpp (3 个 NAPI + 导出)。
- rdpnapi.d.ts / librdpnapi index.d.ts / ExtensionLoader.ets 声明与封装。
- RemoteDesktop.ets (对端身份轮询 + 顶栏接线)、RemoteSessionTopBar.ets
  (移动设备操作区)、RustDeskMobileActionsPolicy.ets (策略)。

## Verification

- 本环境无 Rust toolchain / DevEco / hvigorw，无法本地编译验证。
  已在代码层面完成静态自检 (Rust match 穷尽性、C++ ABI/签名、ArkTS 语法与
  既有模式一致性)。
- 待办 (必须在 DevEco 环境执行):
  1. `cargo test` (rustdesk_ffi, host target) — 新增 2 个单元测试。
  2. Hvigor `default@OhosTestCompileArkTS` + `assembleHap` (module=entry,
     product=default)。
  3. 真机验证: 连接 Android 被控端后顶栏"移动设备操作"出现并可发送
     返回/主页/最近任务/音量/电源; 非 Android 对端不显示。

## Next

1. 在 DevEco 环境完成 Rust 单测与两项 Hvigor 门禁并记录准确输出。
2. 真机验证 Android 被控端交互; 必要时按官方行为修正门禁/键码。
3. 独立 review 后 push/PR/合规门/merge，回到同步 main。

## Blockers

- 本地无 cargo/DevEco，构建与设备验证必须在项目 Windows 检出
  (`C:\Users\14288\DevEcoStudioProjects\RemoteDesktop`) 或 DevEco 环境执行。
