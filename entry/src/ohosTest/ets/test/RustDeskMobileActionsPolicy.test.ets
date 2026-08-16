import { describe, it, expect } from '@ohos/hypium';
import {
  canShowRustDeskMobileActions,
  isRustDeskAndroidPeer,
  rustDeskVersionAtLeast,
  RUSTDESK_ANDROID_KEYCODE_APP_SWITCH,
  RUSTDESK_ANDROID_KEYCODE_BACK,
  RUSTDESK_ANDROID_KEYCODE_HOME,
  RUSTDESK_MOBILE_ACTIONS,
  RUSTDESK_MOBILE_ACTIONS_MIN_PEER_VERSION
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
  });
}
