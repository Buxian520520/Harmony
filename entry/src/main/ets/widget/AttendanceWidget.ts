/**
 * Attendance Service Card
 * Shows today's check-in status on the home screen.
 * 
 * TODO: Register widget in module.json5 and implement data binding.
 * Reference: https://developer.harmonyos.com/en/docs/documentation/doc-guides/arkts-ui-widget-creation-0000001820880665
 */
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';

export default class AttendanceWidget extends FormExtensionAbility {
  onAddForm(want) {
    // Called when the user adds the widget.
    const dataObj = {
      'courseName': '高等数学',
      'status': '未签到',
      'pendingLeaves': '2',
    };
    return formBindingData.createFormBindingData(dataObj);
  }

  onUpdateForm(formId) {
    // Called when the widget is updated (e.g., time-based update).
    // TODO: Fetch real data from API
    const dataObj = {
      'courseName': '今日课程已加载',
      'status': '点击签到',
      'pendingLeaves': '待审批',
    };
    return formBindingData.createFormBindingData(dataObj);
  }

  onRemoveForm(formId) {
    // Called when the widget is removed.
    console.log('Widget removed: ' + formId);
  }
}
