import { describe, it, expect } from '@ohos/hypium';
import {
  canShowRustDeskMobileActions,
  isRustDeskAndroidPeer,
  rustDeskVersionAtLeast,
  rustDeskMobileActionPlan,
  RUSTDESK_ANDROID_KEYCODE_APP_SWITCH,
  RUSTDESK_ANDROID_KEYCODE_BACK,
  RUSTDESK_ANDROID_KEYCODE_HOME,
  RUSTDESK_MOBILE_ACTIONS,
  RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION,
  RUSTDESK_MOBILE_RECENTS_HOLD_MS,
  RUSTDESK_MOUSE_BUTTON_BACK,
  RUSTDESK_MOUSE_BUTTON_MIDDLE,
  RUSTDESK_MOUSE_BUTTON_RIGHT
} from '../../../main/ets/services/RustDeskMobileActionsPolicy';

export default function rustDeskMobileActionsPolicyTest(): void {
  describe('RustDeskMobileActionsPolicy', (): void => {
    it('recognizes_only_android_peers_case_insensitively', 0, (): void => {
      expect(isRustDeskAndroidPeer('Android')).assertTrue();
      expect(isRustDeskAndroidPeer('android')).assertTrue();
      expect(isRustDeskAndroidPeer(' ANDROID ')).assertTrue();
      expect(isRustDeskAndroidPeer('Windows')).assertFalse();
      expect(isRustDeskAndroidPeer('Linux')).assertFalse();
      expect(isRustDeskAndroidPeer('')).assertFalse();
    });

    it('compares_versions_numerically_by_segment', 0, (): void => {
      expect(rustDeskVersionAtLeast('1.2.7', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertTrue();
      expect(rustDeskVersionAtLeast('1.2.8', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertTrue();
      expect(rustDeskVersionAtLeast('1.3.0', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertTrue();
      expect(rustDeskVersionAtLeast('2.0.0', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertTrue();
      expect(rustDeskVersionAtLeast('1.2.6', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('1.1.9', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('1.2.7', '1.2.7')).assertTrue();
      expect(rustDeskVersionAtLeast('1.2', '1.2.0')).assertTrue();
      expect(rustDeskVersionAtLeast('1.2.7', '1.2.7.1')).assertFalse();
    });

    it('rejects_unparseable_versions', 0, (): void => {
      expect(rustDeskVersionAtLeast('abc', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('1.2.x', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      // Pre-release / suffixed segments must not pass the numeric gate.
      expect(rustDeskVersionAtLeast('1.2.7-rc1', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('1.2.7beta', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertFalse();
      expect(rustDeskVersionAtLeast('v1.2.7', RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION)).assertTrue();
    });

    it('shows_mobile_actions_only_for_android_peers_at_or_above_1_2_7', 0, (): void => {
      expect(canShowRustDeskMobileActions('Android', '1.2.7')).assertTrue();
      expect(canShowRustDeskMobileActions('Android', '1.3.2')).assertTrue();
      expect(canShowRustDeskMobileActions('Android', '1.2.6')).assertFalse();
      expect(canShowRustDeskMobileActions('Android', '')).assertFalse();
      expect(canShowRustDeskMobileActions('Windows', '1.3.2')).assertFalse();
      expect(canShowRustDeskMobileActions('', '')).assertFalse();
    });

    it('carries_the_official_mobile_action_key_codes_in_order', 0, (): void => {
      expect(RUSTDESK_MOBILE_ACTIONS.length).assertEqual(6);
      expect(RUSTDESK_MOBILE_ACTIONS[0].id).assertEqual('back');
      expect(RUSTDESK_MOBILE_ACTIONS[0].keyCode).assertEqual(RUSTDESK_ANDROID_KEYCODE_BACK);
      expect(RUSTDESK_MOBILE_ACTIONS[1].id).assertEqual('home');
      expect(RUSTDESK_MOBILE_ACTIONS[1].keyCode).assertEqual(RUSTDESK_ANDROID_KEYCODE_HOME);
      expect(RUSTDESK_MOBILE_ACTIONS[2].id).assertEqual('apps');
      expect(RUSTDESK_MOBILE_ACTIONS[2].keyCode).assertEqual(RUSTDESK_ANDROID_KEYCODE_APP_SWITCH);
    });

    it('back_uses_mouse_back_button_on_1_3_8_and_newer_peers', 0, (): void => {
      const back = RUSTDESK_MOBILE_ACTIONS[0];
      const plan = rustDeskMobileActionPlan(back, '1.3.8');
      expect(plan.kind).assertEqual('mouse-button-tap');
      if (plan.kind === 'mouse-button-tap') {
        expect(plan.button).assertEqual(RUSTDESK_MOUSE_BUTTON_BACK);
      }
      const newer = rustDeskMobileActionPlan(back, '1.4.0');
      expect(newer.kind).assertEqual('mouse-button-tap');
      if (newer.kind === 'mouse-button-tap') {
        expect(newer.button).assertEqual(RUSTDESK_MOUSE_BUTTON_BACK);
      }
    });

    it('back_falls_back_to_right_click_before_1_3_8', 0, (): void => {
      const back = RUSTDESK_MOBILE_ACTIONS[0];
      const plan = rustDeskMobileActionPlan(back, '1.3.7');
      expect(plan.kind).assertEqual('mouse-button-tap');
      if (plan.kind === 'mouse-button-tap') {
        expect(plan.button).assertEqual(RUSTDESK_MOUSE_BUTTON_RIGHT);
      }
      const gate = rustDeskMobileActionPlan(back, '1.2.7');
      expect(gate.kind).assertEqual('mouse-button-tap');
      if (gate.kind === 'mouse-button-tap') {
        expect(gate.button).assertEqual(RUSTDESK_MOUSE_BUTTON_RIGHT);
      }
    });

    it('home_uses_middle_button_tap', 0, (): void => {
      const home = RUSTDESK_MOBILE_ACTIONS[1];
      const plan = rustDeskMobileActionPlan(home, '1.3.2');
      expect(plan.kind).assertEqual('mouse-button-tap');
      if (plan.kind === 'mouse-button-tap') {
        expect(plan.button).assertEqual(RUSTDESK_MOUSE_BUTTON_MIDDLE);
      }
    });

    it('apps_holds_middle_button_beyond_peer_long_tap_delay', 0, (): void => {
      const apps = RUSTDESK_MOBILE_ACTIONS[2];
      const plan = rustDeskMobileActionPlan(apps, '1.3.2');
      expect(plan.kind).assertEqual('mouse-button-hold');
      if (plan.kind === 'mouse-button-hold') {
        expect(plan.button).assertEqual(RUSTDESK_MOUSE_BUTTON_MIDDLE);
        // 官方 InputService LONG_TAP_DELAY=200ms, 必须保持超过该时长。
        expect(plan.holdMs).assertLarger(200);
        expect(plan.holdMs).assertEqual(RUSTDESK_MOBILE_RECENTS_HOLD_MS);
      }
    });

    it('volume_and_power_use_map_mode_key_taps', 0, (): void => {
      const volumeUp = rustDeskMobileActionPlan(RUSTDESK_MOBILE_ACTIONS[3], '1.3.2');
      expect(volumeUp.kind).assertEqual('key-tap');
      if (volumeUp.kind === 'key-tap') {
        expect(volumeUp.keyCode).assertEqual(24);
      }
      const volumeDown = rustDeskMobileActionPlan(RUSTDESK_MOBILE_ACTIONS[4], '1.3.2');
      expect(volumeDown.kind).assertEqual('key-tap');
      if (volumeDown.kind === 'key-tap') {
        expect(volumeDown.keyCode).assertEqual(25);
      }
      const power = rustDeskMobileActionPlan(RUSTDESK_MOBILE_ACTIONS[5], '1.3.2');
      expect(power.kind).assertEqual('key-tap');
      if (power.kind === 'key-tap') {
        expect(power.keyCode).assertEqual(26);
      }
    });
  });
}
