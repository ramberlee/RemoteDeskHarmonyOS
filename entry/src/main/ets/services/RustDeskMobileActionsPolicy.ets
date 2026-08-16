/**
 * RustDeskMobileActionsPolicy.ets — 移动端远程移动端交互策略
 *
 * 复刻 RustDesk 官方移动端客户端对 Android 被控端的操作:
 * Back / Home / Apps(最近任务) / Volume up / Volume down / Power。
 *
 * 线格式依据官方实现 (flutter/lib/models/input_model.dart 的 onMobile* 与
 * flutter/android/.../KeyboardKeyEventMapper.kt): Android 被控端在
 * Map/Translate 模式下把 KeyEvent.chr 当作 Android KeyEvent key code 注入,
 * 因此这里直接发送 Android key code
 * (3=HOME, 4=BACK, 187=APP_SWITCH, 24/25=音量, 26=电源)。
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

/** PeerInfo.platform 与官方 kPeerPlatformAndroid 一致 (大小写不敏感)。 */
export function isRustDeskAndroidPeer(platform: string): boolean {
  return platform.trim().toLowerCase() === 'android';
}

/** 逐段数值比较版本号: "1.2.7" >= "1.2.7"; 解析失败返回 false。 */
export function rustDeskVersionAtLeast(version: string, minimum: string): boolean {
  const normalize = (value: string): string => value.trim().replace(/^[vV]/, '');
  const a: string[] = normalize(version).split('.');
  const b: string[] = normalize(minimum).split('.');
  const len: number = Math.max(a.length, b.length);
  for (let i = 0; i < len; i++) {
    const av: number = i < a.length ? parseInt(a[i], 10) : 0;
    const bv: number = i < b.length ? parseInt(b[i], 10) : 0;
    if (isNaN(av) || isNaN(bv)) {
      return false;
    }
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
