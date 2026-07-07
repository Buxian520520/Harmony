import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';

/**
 * Request location permissions at runtime.
 * ohos.permission.LOCATION and ohos.permission.APPROXIMATELY_LOCATION
 * are user-granted permissions that must be requested even if declared
 * in module.json5.
 *
 * @returns true if both permissions were granted
 */
export async function requestLocationPermissions(): Promise<boolean> {
  try {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
    const result = await atManager.requestPermissionsFromUser(context, [
      'ohos.permission.LOCATION',
      'ohos.permission.APPROXIMATELY_LOCATION'
    ]);
    // authResults: 0 = granted, -1 = denied
    if (result.authResults.length > 0) {
      return result.authResults.every((status: number) => status === 0);
    }
    return false;
  } catch (e) {
    console.error('requestLocationPermissions failed: ' + JSON.stringify(e));
    return false;
  }
}
