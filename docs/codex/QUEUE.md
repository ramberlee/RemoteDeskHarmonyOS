# RustDesk Mobile Actions Queue

Updated: 2026-08-16 Asia/Shanghai

## Now

- 移动端远程移动端交互 (RustDesk mobile actions): FFI/NAPI/ArkTS 实现 + 三层
  独立 review + cargo 全量验证 + C++ 语法验证 + Hvigor 双门禁
  (`default@OhosTestCompileArkTS` + `assembleHap`) 全部通过 (2026-08-16);
  PR #1 已推送 (https://github.com/ramberlee/RemoteDeskHarmonyOS/pull/1, open)。
- 待真机验证: HarmonyOS 设备安装签名 HAP + Android RustDesk 被控端 (≥1.2.7)
  验证 返回/主页/最近任务/音量/电源; 非 Android 对端不显示"移动设备操作";
  版本 < 1.2.7 对端不显示。

## Next

- 真机验证通过后: 确认 open-source-compliance (仓库 Actions 未启用, 人工跑
  Light 或启用 Actions) → merge PR #1 → main `pull --ff-only` → 删除已合并分支。

## Later

- 若官方新增更多移动端操作 (如锁屏、截图), 按同一 Map-mode key code 通道扩展。
- 评估把移动设备操作区升级为可拖拽悬浮胶囊 (对齐官方 DraggableMobileActions)。
