import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'attendance_card_store';
const KEY_FORM_ID = 'formId';

/**
 * AttendanceFormAbility — 学生端考勤服务卡片 FormExtensionAbility
 * 接收主应用推送的考勤状态和请假审批数据，更新卡片 UI
 */
export default class AttendanceFormAbility extends FormExtensionAbility {
  /**
   * 卡片添加到桌面时回调：保存 formId 供主应用更新数据使用
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string || '';
    if (formId) {
      this.saveFormId(formId);
    }

    const initialData: Record<string, string | number> = {
      'todayCourse': '正在加载...',
      'checkinStatus': '--',
      'statusColor': '#8E8E93',
      'pendingLeaveCount': 0,
      'hasPendingLeaves': 0,
      'lastUpdate': ''
    };
    return formBindingData.createFormBindingData(initialData);
  }

  /**
   * 兼容旧版：卡片创建时的默认数据
   */
  onCreate(want: Want): formBindingData.FormBindingData {
    const initialData: Record<string, string | number> = {
      'todayCourse': '正在加载...',
      'checkinStatus': '--',
      'statusColor': '#8E8E93',
      'pendingLeaveCount': 0,
      'hasPendingLeaves': 0,
      'lastUpdate': ''
    };
    return formBindingData.createFormBindingData(initialData);
  }

  private async saveFormId(formId: string): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(this.context, PREF_NAME);
      await prefs.put(KEY_FORM_ID, formId);
      await prefs.flush();
      console.info(`[AttendanceFormAbility] Saved formId: ${formId}`);
    } catch (e) {
      console.error(`[AttendanceFormAbility] Failed to save formId: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 卡片更新时回调：主应用调用 formProvider.updateForm 触发
   */
  onUpdate(formId: string): void {
    // Data is pushed from the main app via formProvider.updateForm,
    // so no extra work is needed here. However, we keep the hook open
    // for future use (e.g. periodic self-refresh from persistent storage).
    console.info(`[AttendanceFormAbility] onUpdate called for formId: ${formId}`);
  }

  /**
   * 卡片被销毁时回调
   */
  onDestroy(formId: string): void {
    console.info(`[AttendanceFormAbility] onDestroy called for formId: ${formId}`);
  }

  /**
   * 卡片被点击时跳转到主应用
   */
  onCastToNormal(formId: string): void {
    // The formConfigAbility links to EntryAbility; the system auto-navigates on tap.
    console.info(`[AttendanceFormAbility] onCastToNormal called for formId: ${formId}`);
  }

  /**
   * 卡片可见性变化
   */
  onVisibilityChange(newStatus: Record<string, number>): void {
    console.info(`[AttendanceFormAbility] onVisibilityChange: ${JSON.stringify(newStatus)}`);
  }

  /**
   * 卡片事件消息（如点击卡片上的按钮）
   */
  onFormEvent(formId: string, message: string): void {
    console.info(`[AttendanceFormAbility] onFormEvent formId: ${formId}, message: ${message}`);
  }
}
