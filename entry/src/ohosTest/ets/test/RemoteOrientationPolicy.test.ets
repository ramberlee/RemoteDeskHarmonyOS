import { describe, it, expect } from '@ohos/hypium';
import {
  isRustDeskMobilePlatform,
  normalizeRustDeskTargetDevice,
  rustDeskOrientationPolicy
} from '../../../main/ets/services/RemoteOrientationPolicy';

export default function remoteOrientationPolicyTest(): void {
  describe('RemoteOrientationPolicy', (): void => {
    it('normalizes_rustdesk_target_devices', 0, (): void => {
      expect(normalizeRustDeskTargetDevice('phone')).assertEqual('phone');
      expect(normalizeRustDeskTargetDevice('computer')).assertEqual('computer');
      expect(normalizeRustDeskTargetDevice('')).assertEqual('computer');
      expect(normalizeRustDeskTargetDevice('PHONE')).assertEqual('computer');
      expect(normalizeRustDeskTargetDevice('tablet')).assertEqual('computer');
    });

    it('recognizes_mobile_peer_platforms', 0, (): void => {
      expect(isRustDeskMobilePlatform('Android')).assertTrue();
      expect(isRustDeskMobilePlatform('android')).assertTrue();
      expect(isRustDeskMobilePlatform('iOS')).assertTrue();
      expect(isRustDeskMobilePlatform('HarmonyOS')).assertTrue();
      expect(isRustDeskMobilePlatform('Windows')).assertFalse();
      expect(isRustDeskMobilePlatform('Linux')).assertFalse();
      expect(isRustDeskMobilePlatform('')).assertFalse();
    });

    it('defaults_phone_peers_to_portrait_and_desktop_peers_to_landscape', 0, (): void => {
      // 手机对端: 默认竖屏。
      expect(rustDeskOrientationPolicy('rustdesk', false, true, false, false, false, true))
        .assertEqual('portrait');
      // 电脑对端: 默认横屏 (既有行为)。
      expect(rustDeskOrientationPolicy('rustdesk', false, true, false, false, false, false))
        .assertEqual('landscape');
    });

    it('session_pending_applies_the_same_default', 0, (): void => {
      expect(rustDeskOrientationPolicy('rustdesk', false, false, false, false, true, true))
        .assertEqual('portrait');
      expect(rustDeskOrientationPolicy('rustdesk', false, false, false, false, true, false))
        .assertEqual('landscape');
    });

    it('adaptive_orientation_opt_in_overrides_both_defaults', 0, (): void => {
      expect(rustDeskOrientationPolicy('rustdesk', false, true, false, true, false, true))
        .assertEqual('auto-rotate');
      expect(rustDeskOrientationPolicy('rustdesk', false, true, false, true, false, false))
        .assertEqual('auto-rotate');
    });

    it('desktop_controllers_and_other_protocols_preserve_window', 0, (): void => {
      expect(rustDeskOrientationPolicy('rustdesk', true, true, false, false, false, true))
        .assertEqual('preserve-window');
      expect(rustDeskOrientationPolicy('rdp', false, true, false, false, false, true))
        .assertEqual('preserve-window');
      expect(rustDeskOrientationPolicy('vnc', false, true, false, false, false, true))
        .assertEqual('preserve-window');
      expect(rustDeskOrientationPolicy('rustdesk', false, true, false, false, false, true))
        .assertEqual('portrait');
    });

    it('pip_sessions_never_change_orientation', 0, (): void => {
      expect(rustDeskOrientationPolicy('rustdesk', false, true, true, false, false, true))
        .assertEqual('preserve-window');
      expect(rustDeskOrientationPolicy('rustdesk', false, true, true, true, false, true))
        .assertEqual('preserve-window');
    });
  });
}
