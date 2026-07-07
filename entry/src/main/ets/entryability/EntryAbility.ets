import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

const TAG = 'EntryAbility';
const DOMAIN = 0x0001;
const POLL_INTERVAL_MS = 10000; // 10 秒轮询一次

export default class EntryAbility extends UIAbility {
  private pollTimer: number = -1;
  private suspendDelayId: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
    // Initialize pollTick in AppStorage so pages can observe it
    AppStorage.setOrCreate('pollTick', 0);
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
    this.stopPolling();
    this.cancelSuspendDelay();
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content. Data: %{public}s', JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
    this.cancelSuspendDelay();
    this.startPolling();
    // Trigger immediate refresh when returning to foreground
    this.bumpPollTick();
  }

  onBackground() {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
    // Request suspend delay to keep polling briefly in background
    this.requestSuspendDelay();
  }

  // ── Polling ──

  private startPolling(): void {
    if (this.pollTimer !== -1) {
      return;
    }
    hilog.info(DOMAIN, TAG, `Starting poll timer every ${POLL_INTERVAL_MS} ms`);
    this.pollTimer = setInterval(() => {
      this.bumpPollTick();
    }, POLL_INTERVAL_MS);
  }

  private stopPolling(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
      hilog.info(DOMAIN, TAG, 'Poll timer stopped');
    }
  }

  /**
   * Increment pollTick in AppStorage.
   * Pages observing this via @StorageLink('pollTick') will refresh data.
   */
  private bumpPollTick(): void {
    const current: number = AppStorage.get<number>('pollTick') || 0;
    AppStorage.setOrCreate('pollTick', current + 1);
  }

  // ── Suspend Delay (background grace period) ──

  private requestSuspendDelay(): void {
    try {
      const info = backgroundTaskManager.requestSuspendDelay(
        'AttendancePoll',
        () => {
          hilog.warn(DOMAIN, TAG, 'Suspend delay expired — stopping poll');
          this.stopPolling();
        }
      );
      this.suspendDelayId = info.requestId;
      hilog.info(DOMAIN, TAG,
        `Suspend delay granted: id=${info.requestId}, time=${info.actualDelayTime}ms`);
      // Continue polling during the grace period
      this.startPolling();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `requestSuspendDelay failed: ${JSON.stringify(e)}`);
      // Still try polling — the system may allow a short grace period
      this.startPolling();
    }
  }

  private cancelSuspendDelay(): void {
    if (this.suspendDelayId !== -1) {
      try {
        backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, `cancelSuspendDelay failed: ${JSON.stringify(e)}`);
      }
      this.suspendDelayId = -1;
    }
  }
}
