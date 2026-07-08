/**
 * Shared NavPathStack reference for Navigation-based routing.
 * Set by Main.ets / TeacherMain.ets in aboutToAppear.
 * Sub-page components use this to pop back.
 */
export class Nav {
  static stack: NavPathStack = new NavPathStack();
}
