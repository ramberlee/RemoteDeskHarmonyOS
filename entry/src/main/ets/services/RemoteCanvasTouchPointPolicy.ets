/**
 * Normalizes TouchEvent contact counts after the page has synchronized its
 * ID-keyed touch map. Some API 23 Move events expose only changedTouches;
 * their touches.length must not collapse an active two-finger canvas gesture
 * to one finger.
 */
export type CanvasTouchPointEvent = 'down' | 'move' | 'up' | 'cancel';

function nonNegativeCount(value: number): number {
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 0;
}

export function resolveCanvasActiveTouchCount(event: CanvasTouchPointEvent,
  trackedTouchCount: number, reportedTouchCount: number,
  previousTouchCount: number, changedTouchCount: number): number {
  if (event === 'cancel') {
    return 0;
  }
  const tracked: number = nonNegativeCount(trackedTouchCount);
  // syncActiveTouchPoints() has already removed the lifted IDs for Up. An
  // empty map is therefore the authoritative final-lift signal even if the
  // platform still echoes that finger in TouchEvent.touches.
  if (tracked > 0 || event === 'up') {
    return tracked;
  }
  const reported: number = nonNegativeCount(reportedTouchCount);
  const previous: number = nonNegativeCount(previousTouchCount);
  const changed: number = nonNegativeCount(changedTouchCount);
  if (event === 'down') {
    return Math.max(reported, previous + Math.max(1, changed));
  }
  return reported > 0 ? reported : previous;
}

/**
 * Whether a centroid displacement beyond the click slop counts as gesture
 * movement. While every finger of an active three-finger gesture is still
 * down, movement is genuine. When fingers lift one by one, the centroid of
 * the remaining contacts can jump by far more than the slop even though the
 * user never moved — marking that as movement would swallow a clean
 * three-finger tap (the local control-panel toggle). Two-finger and
 * single-finger gestures keep the legacy behavior (always count movement).
 */
export function shouldMarkTouchMoved(touchMaxFingers: number, touchFingerCount: number): boolean {
  return touchMaxFingers < 3 || touchFingerCount >= 3;
}
