import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(0x0000, 'AttendanceApp', 'Ability onCreate');
  }

  onDestroy() {
    hilog.info(0x0000, 'AttendanceApp', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page
    hilog.info(0x0000, 'AttendanceApp', 'onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'AttendanceApp', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'AttendanceApp', 'Succeeded in loading content. Data: %{public}s', JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    hilog.info(0x0000, 'AttendanceApp', 'onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, 'AttendanceApp', 'Ability onForeground');
  }

  onBackground() {
    hilog.info(0x0000, 'AttendanceApp', 'Ability onBackground');
  }
}
