/**
 * RustDeskMobileActionsPolicy.ets — 移动端远程移动端交互策略
 *
 * 复刻 RustDesk 官方移动端客户端对 Android 被控端的操作:
 * Back / Home / Apps(最近任务) / Volume up / Volume down / Power。
 *
 * 线格式依据官方实现核实 (rustdesk master):
 * - flutter/lib/models/input_model.dart 的 onMobileBack/onMobileHome/onMobileApps:
 *   返回 = 鼠标 BACK 键 tap (对端 >= 1.3.8; 更旧对端用右键);
 *   主页 = 鼠标中键单击; 最近任务 = 鼠标中键按住 >= 200ms 再抬起。
 * - flutter/android/.../InputService.kt 的掩码常量: BACK=64, WHEEL=32,
 *   DOWN=1, UP=2; BACK_UP(66) -> GLOBAL_ACTION_BACK,
 *   中键快速抬起 -> GLOBAL_ACTION_HOME, 中键按住 -> GLOBAL_ACTION_RECENTS。
 * - 音量/电源 = KeyEvent{ mode: Map, chr: Android key code } (24/25/26),
 *   被控端 InputService 的 tryHandleVolumeKeyEvent / tryHandlePowerKeyEvent
 *   拦截执行 (与官方 HID->keycode 转换后的线格式一致)。
 *
 * 官方客户端还要求被控端版本 >= 1.2.7 才提供移动端操作。
 */

/** Android KeyEvent key codes used by the official RustDesk mobile actions. */
export const RUSTDESK_ANDROID_KEYCODE_BACK = 4;
export const RUSTDESK_ANDROID_KEYCODE_HOME = 3;
export const RUSTDESK_ANDROID_KEYCODE_APP_SWITCH = 187;
export const RUSTDESK_ANDROID_KEYCODE_VOLUME_UP = 24;
export const RUSTDESK_ANDROID_KEYCODE_VOLUME_DOWN = 25;
export const RUSTDESK_ANDROID_KEYCODE_POWER = 26;

/** 官方客户端要求被控端版本 >= 1.2.7 才提供移动端操作。 */
export const RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION = '1.2.7';

/** 官方 onMobileBack 从该版本起使用鼠标 BACK 键; 更旧对端退化为右键。 */
export const RUSTDESK_MOBILE_BACK_MIN_MOUSE_BUTTON_VERSION = '1.3.8';

/** 官方 InputService LONG_TAP_DELAY=200ms: 中键按住超过该时长触发最近任务。 */
export const RUSTDESK_MOBILE_RECENTS_HOLD_MS = 300;

/** 鼠标按钮编号 (与 C++ MouseButton 枚举一致)。 */
export const RUSTDESK_MOUSE_BUTTON_MIDDLE = 1;
export const RUSTDESK_MOUSE_BUTTON_RIGHT = 2;
export const RUSTDESK_MOUSE_BUTTON_BACK = 3;

export type RustDeskMobileActionId =
  'back' | 'home' | 'apps' | 'volume_up' | 'volume_down' | 'power';

export interface RustDeskMobileAction {
  id: RustDeskMobileActionId;
  label: string;
  keyCode: number;
}

/** 按官方移动端菜单顺序排列。 */
export const RUSTDESK_MOBILE_ACTIONS: RustDeskMobileAction[] = [
  { id: 'back', label: '返回', keyCode: RUSTDESK_ANDROID_KEYCODE_BACK },
  { id: 'home', label: '主页', keyCode: RUSTDESK_ANDROID_KEYCODE_HOME },
  { id: 'apps', label: '最近任务', keyCode: RUSTDESK_ANDROID_KEYCODE_APP_SWITCH },
  { id: 'volume_up', label: '音量 +', keyCode: RUSTDESK_ANDROID_KEYCODE_VOLUME_UP },
  { id: 'volume_down', label: '音量 -', keyCode: RUSTDESK_ANDROID_KEYCODE_VOLUME_DOWN },
  { id: 'power', label: '电源', keyCode: RUSTDESK_ANDROID_KEYCODE_POWER },
];

/**
 * 单个移动操作的具体发送计划:
 * - key-tap: KeyEvent Map 模式 chr=Android key code, down+up (音量/电源)。
 * - mouse-button-tap: 鼠标按钮 down+up (返回/主页)。
 * - mouse-button-hold: 鼠标按钮 down, 保持 holdMs 后 up (最近任务)。
 */
export interface RustDeskMobileKeyTapPlan {
  kind: 'key-tap';
  keyCode: number;
}

export interface RustDeskMobileMouseTapPlan {
  kind: 'mouse-button-tap';
  button: number;
}

export interface RustDeskMobileMouseHoldPlan {
  kind: 'mouse-button-hold';
  button: number;
  holdMs: number;
}

export type RustDeskMobileActionPlan =
  RustDeskMobileKeyTapPlan | RustDeskMobileMouseTapPlan | RustDeskMobileMouseHoldPlan;

/** PeerInfo.platform 与官方 kPeerPlatformAndroid 一致 (大小写不敏感)。 */
export function isRustDeskAndroidPeer(platform: string): boolean {
  return platform.trim().toLowerCase() === 'android';
}

/** 逐段数值比较版本号: "1.2.7" >= "1.2.7"; 非纯数字段 (如 "1.2.7-rc1") 返回 false。 */
export function rustDeskVersionAtLeast(version: string, minimum: string): boolean {
  const normalize = (value: string): string => value.trim().replace(/^[vV]/, '');
  const a: string[] = normalize(version).split('.');
  const b: string[] = normalize(minimum).split('.');
  const len: number = Math.max(a.length, b.length);
  for (let i = 0; i < len; i++) {
    const segmentA: string = i < a.length ? a[i] : '0';
    const segmentB: string = i < b.length ? b[i] : '0';
    // 只接受纯数字段: 预发布/后缀版本 (1.2.7-rc1, 1.2.7beta) 不通过门禁。
    if (!/^\d+$/.test(segmentA) || !/^\d+$/.test(segmentB)) {
      return false;
    }
    const av: number = parseInt(segmentA, 10);
    const bv: number = parseInt(segmentB, 10);
    if (av !== bv) {
      return av > bv;
    }
  }
  return true;
}

/**
 * 是否可显示移动端操作。与官方一致: 仅 Android 对端, 且对端版本 >= 1.2.7。
 * 版本未知 (PeerInfo 尚未到达) 时不盲目启用。
 */
export function canShowRustDeskMobileActions(platform: string, version: string): boolean {
  if (!isRustDeskAndroidPeer(platform)) {
    return false;
  }
  if (version.trim() === '') {
    return false;
  }
  return rustDeskVersionAtLeast(version, RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION);
}

/**
 * 单个操作的发送计划 (与官方 input_model.dart 的 onMobile* 一一对应):
 * - back: >= 1.3.8 鼠标 BACK 键; 更旧对端用右键 (官方兼容策略)。
 * - home: 鼠标中键单击。
 * - apps: 鼠标中键按住 (>= InputService LONG_TAP_DELAY)。
 * - volume/power: Map 模式 Android key code tap。
 */
export function rustDeskMobileActionPlan(action: RustDeskMobileAction,
  peerVersion: string): RustDeskMobileActionPlan {
  switch (action.id) {
    case 'back':
      return rustDeskVersionAtLeast(peerVersion, RUSTDESK_MOBILE_BACK_MIN_MOUSE_BUTTON_VERSION)
        ? { kind: 'mouse-button-tap', button: RUSTDESK_MOUSE_BUTTON_BACK }
        : { kind: 'mouse-button-tap', button: RUSTDESK_MOUSE_BUTTON_RIGHT };
    case 'home':
      return { kind: 'mouse-button-tap', button: RUSTDESK_MOUSE_BUTTON_MIDDLE };
    case 'apps':
      return {
        kind: 'mouse-button-hold',
        button: RUSTDESK_MOUSE_BUTTON_MIDDLE,
        holdMs: RUSTDESK_MOBILE_RECENTS_HOLD_MS
      };
    case 'volume_up':
      return { kind: 'key-tap', keyCode: RUSTDESK_ANDROID_KEYCODE_VOLUME_UP };
    case 'volume_down':
      return { kind: 'key-tap', keyCode: RUSTDESK_ANDROID_KEYCODE_VOLUME_DOWN };
    case 'power':
      return { kind: 'key-tap', keyCode: RUSTDESK_ANDROID_KEYCODE_POWER };
  }
}
