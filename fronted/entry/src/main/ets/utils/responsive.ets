/**
 * Responsive layout helpers for phone/tablet adaptation.
 * Usage:
 *   if (isPhone) { /* phone layout *\/ }
 *   if (isTablet) { /* tablet layout *\/ }
 */
import mediaQuery from '@ohos.mediaquery';

export class ResponsiveLayout {
  static isPhone: boolean = true;
  static isTablet: boolean = false;
  static isLandscape: boolean = false;

  static init() {
    // Phone: width < 600vp
    const phoneListener = mediaQuery.matchMediaSync('(max-width: 599vp)');
    phoneListener.on('change', (result) => {
      ResponsiveLayout.isPhone = result.matches;
      ResponsiveLayout.isTablet = !result.matches;
    });
    ResponsiveLayout.isPhone = phoneListener.matches;
    ResponsiveLayout.isTablet = !phoneListener.matches;

    // Landscape
    const landscapeListener = mediaQuery.matchMediaSync('(orientation: landscape)');
    landscapeListener.on('change', (result) => {
      ResponsiveLayout.isLandscape = result.matches;
    });
  }
}
