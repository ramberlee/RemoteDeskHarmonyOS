import { describe, it, expect } from '@ohos/hypium';
import { shouldMarkTouchMoved } from '../../../main/ets/services/RemoteCanvasTouchPointPolicy';

export default function remoteCanvasTouchPointPolicyTest(): void {
  describe('RemoteCanvasTouchPointPolicy', (): void => {
    it('single_and_two_finger_gestures_keep_legacy_movement_semantics', 0, (): void => {
      // Single finger: movement always counts regardless of current count.
      expect(shouldMarkTouchMoved(1, 1)).assertTrue();
      expect(shouldMarkTouchMoved(1, 0)).assertTrue();
      // Two-finger gesture: movement always counts (max < 3).
      expect(shouldMarkTouchMoved(2, 2)).assertTrue();
      expect(shouldMarkTouchMoved(2, 1)).assertTrue();
      expect(shouldMarkTouchMoved(2, 0)).assertTrue();
    });

    it('three_finger_movement_counts_only_while_all_fingers_are_down', 0, (): void => {
      // All three fingers down: genuine movement counts.
      expect(shouldMarkTouchMoved(3, 3)).assertTrue();
      // Fingers lifting one by one: centroid shift must NOT count as movement,
      // otherwise a clean three-finger tap (control-panel toggle) is swallowed.
      expect(shouldMarkTouchMoved(3, 2)).assertFalse();
      expect(shouldMarkTouchMoved(3, 1)).assertFalse();
      expect(shouldMarkTouchMoved(3, 0)).assertFalse();
    });

    it('higher_multi_touch_counts_follow_the_same_lift_rule', 0, (): void => {
      expect(shouldMarkTouchMoved(4, 4)).assertTrue();
      expect(shouldMarkTouchMoved(4, 3)).assertFalse();
      expect(shouldMarkTouchMoved(5, 2)).assertFalse();
      // A degenerate max < count observation still counts as movement.
      expect(shouldMarkTouchMoved(2, 3)).assertTrue();
    });
  });
}
