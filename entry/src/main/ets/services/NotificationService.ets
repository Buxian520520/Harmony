import { notificationManager } from '@kit.NotificationKit';
import notification from '@ohos.notification';
import { preferences } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import common from '@ohos.app.ability.common';

const TAG = 'NotificationService';
const DOMAIN = 0x0001;
const PREF_NAME = 'notification_store';

// ── Notification IDs ──
const NOTIF_ID_ATTENDANCE_START = 1001;
const NOTIF_ID_LEAVE_RESULT = 1002;
const NOTIF_ID_ABNORMAL_WARNING = 1003;

/**
 * NotificationService — 通知服务推送
 */
export class NotificationService {

  /**
   * 请求通知权限
   */
  static async requestPermission(): Promise<boolean> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        await notificationManager.requestEnableNotification();
      }
      const after = await notificationManager.isNotificationEnabled();
      return after;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `requestPermission error: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 1. 考勤开始提醒
   */
  static async showAttendanceReminder(taskTitle: string, taskId: number): Promise<void> {
    const key: string = `attn_${taskId}`;
    if (await NotificationService.wasShown(key)) {
      hilog.info(DOMAIN, TAG, `Attendance reminder already shown for task ${taskId}`);
      return;
    }

    const request: notificationManager.NotificationRequest = {
      id: NOTIF_ID_ATTENDANCE_START,
      slotType: notification.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '考勤开始提醒',
          text: `课程「${taskTitle}」已开始签到，请尽快完成签到。`,
          additionalText: `任务编号: ${taskId}`
        }
      }
    };

    NotificationService.doPublish(request, key, 'AttendanceReminder');
  }

  /**
   * 2. 请假审批结果通知
   */
  static async showLeaveApprovalResult(
    leaveId: number, status: string, comment: string
  ): Promise<void> {
    const key: string = `leave_${leaveId}_${status}`;
    if (await NotificationService.wasShown(key)) {
      hilog.info(DOMAIN, TAG, `Leave result already shown for leave ${leaveId} (${status})`);
      return;
    }

    const isApproved: boolean = status === 'approved';
    const title: string = isApproved ? '请假已批准' : '请假已拒绝';
    const text: string = isApproved
      ? (comment ? `审批意见: ${comment}` : '你的请假申请已通过审批。')
      : (comment ? `审批意见: ${comment}` : '你的请假申请被驳回。');

    const request: notificationManager.NotificationRequest = {
      id: NOTIF_ID_LEAVE_RESULT,
      slotType: notification.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
          additionalText: `请假编号: ${leaveId}`
        }
      }
    };

    NotificationService.doPublish(request, key, 'LeaveApprovalResult');
  }

  /**
   * 3. 异常考勤预警
   */
  static async showAbnormalWarning(taskTitle: string, taskId: number): Promise<void> {
    const key: string = `abn_${taskId}`;
    if (await NotificationService.wasShown(key)) {
      hilog.info(DOMAIN, TAG, `Abnormal warning already shown for task ${taskId}`);
      return;
    }

    const request: notificationManager.NotificationRequest = {
      id: NOTIF_ID_ABNORMAL_WARNING,
      slotType: notification.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '异常考勤预警',
          text: `课程「${taskTitle}」签到即将结束，你尚未完成签到。`,
          additionalText: `任务编号: ${taskId}`
        }
      }
    };

    NotificationService.doPublish(request, key, 'AbnormalWarning');
  }

  /**
   * Publish notification and log result
   */
  private static doPublish(
    request: notificationManager.NotificationRequest,
    key: string,
    label: string
  ): void {
    notificationManager.publish(request).then(() => {
      hilog.info(DOMAIN, TAG, `${label} published successfully`);
      NotificationService.markShown(key);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, `${label} publish failed: ${err.message}`);
    });
  }

  // ── duplicate prevention via preferences ──

  private static async wasShown(key: string): Promise<boolean> {
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(ctx, PREF_NAME);
      const val: boolean = await prefs.get(key, false) as boolean;
      return val === true;
    } catch (_e) {
      return false;
    }
  }

  private static async markShown(key: string): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(ctx, PREF_NAME);
      await prefs.put(key, true);
      await prefs.flush();
    } catch (_e) {
      // silently fail
    }
  }

  /**
   * Clear notification history.
   */
  static async clearHistory(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(ctx, PREF_NAME);
      await prefs.clear();
      await prefs.flush();
    } catch (_e) {
      // silently fail
    }
  }
}
