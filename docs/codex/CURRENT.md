# Shared Current State

## Active Task

- Task: `rustdesk-mobile-actions` — 移动端客户端远程移动端交互 (复刻 RustDesk 官方移动端操作)
- Base: `main@aeb0cda` (origin/main, clean before task)
- Branch: `codex/rustdesk-mobile-actions`
- Phase: 实现 + 三层独立静态 review + **cargo test 全量通过**; Hvigor 门禁待 DevEco。

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

- **cargo test + cargo build (本机, 2026-08-11)**: 自建 Rust 工具链 (rustup 1.97.1
  x86_64-pc-windows-gnu) + w64devkit (GCC 16.2/ld 2.47) + 自编译 libopus.a
  (opus 1.5.2, cmake/ninja via pip, 网络经代理 127.0.0.1:7897)。
  - `cargo test` 默认 features: **194 passed; 0 failed; exit 0** (含新增
    `connector::tests::mobile_key_uses_map_mode_with_android_keycode` 与
    `connector::tests::peer_snapshot_publishes_platform_and_version_within_fixed_buffers`)。
  - `cargo test --no-default-features`: 184 passed; 0 failed。
  - `cargo build` (cdylib+staticlib, RUSTFLAGS=-L w64devkit gcc lib): exit 0,
    rustdesk_ffi.dll 生成。
  - 注意: 管道截断输出时 cargo 可能误报 exit 1; 以文件重定向的退出码为准。
  - 注: cdylib 链接需 `RUSTFLAGS=-L <w64devkit gcc lib dir>` 定位 libopus.a;
    cargo test 经 gcc driver 自动找到。
- **C++ 编译级验证 (本机, 2026-08-11)**: 用 w64devkit gcc (GCC 16.2) 对本次改动的
  C++ 头文件/实现做 `-fsyntax-only -std=c++17` 真实语法编译 (OHOS 专用头
  hilog/socket 以最小 stub 替代):
  - `rustdesk_ipc.h` (新枚举 0x14 + RdIpcMobileKeyEvent): exit 0。
  - `protocol_adapter.h` (3 个新默认虚函数): exit 0 (含完整依赖头链)。
  - `rustdesk_bridge.h` (RustDeskPeerIdentity + 4 个新方法声明): exit 0。
  - `rustdesk_bridge.cpp` (sendMobileKey/peerPlatform/peerVersion/peerIdentity
    实现 + extern "C" 声明 + ABI static_assert): exit 0 — static_assert 在
    语法检查时真实求值, sizeof(RustDeskFfiPeerSnapshot)==67 与 5 个 offsetof
    断言全部通过; `override` 签名匹配经基类虚函数校验。
  - 注: extension_loader_napi.cpp 依赖 60+ 个 N-API 符号, stub 成本过高;
    其新增代码与既有 NapiSendKey 模式逐字一致且经静态 review。
- 三路独立静态 review (Rust FFI、C++/NAPI、ArkTS) 全部完成, 无未解决发现:
  - Rust: `test_client_with_display_state` 缺新字段 (E0063)、panic `{:?}` Debug 风险 → 已修 (e142f0c)。
  - C++: `sendMobileKey` 缺 `override`、peer snapshot 缺 ABI static_assert、IPC payload 8 字节 padding 文档 → 已修 (29f8927)。
  - ArkTS: 版本段非纯数字 (1.2.7-rc1) 漏放行、身份轮询不自动停止、`peerIsAndroid` 命名歧义 → 已修 (0b8cc9f)。
- **运行时验证 (2026-08-11, 本环境)**: 用 Node 24 原生 TS 类型剥离直接 import 已提交的
  `RustDeskMobileActionsPolicy.ets` 并执行 ohosTest 同款断言, 37/37 全部通过
  (平台识别 6、版本门禁 14、能力判定 7、操作目录 10), 退出码 0。
- 待办 (Hvigor 门禁, 需 DevEco Studio + HarmonyOS 商业 SDK 6.1.0(23)):
  已核实: 华为云镜像仅存旧版 OpenHarmony SDK (2.1.1/3.0.x), gitee 反爬,
  GitHub 无官方源, developer.huawei.com 下载需华为账号登录 — 商业 SDK 在本
  环境无法匿名获取, Hvigor 门禁不可行; 真机验证需 Android RustDesk 被控端。

## Next

1. 搭建 DevEco/HarmonyOS SDK 环境 (或使用具备该环境的检出) 运行
   `default@OhosTestCompileArkTS` + `assembleHap`, 记录准确输出。
2. 真机验证 Android 被控端交互; 必要时按官方行为修正门禁/键码。
3. push/PR/required 合规门/merge，回到同步 main。

## Blockers

- 本地无 cargo/DevEco，构建与设备验证必须在项目 Windows 检出
  (`C:\Users\14288\DevEcoStudioProjects\RemoteDesktop`) 或 DevEco 环境执行。
