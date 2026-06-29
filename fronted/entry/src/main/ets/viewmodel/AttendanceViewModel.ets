/**
 * Attendance ViewModel - shared state for attendance flow.
 */
import { AttendanceApi } from '../services/api/attendanceApi';

export class AttendanceViewModel {
  token: string = '';
  currentCourseId: number = 0;
  currentCourseName: string = '';
  latitude: number = 0;
  longitude: number = 0;
  deviceId: string = '';
  isCheckingIn: boolean = false;
  lastResult: string = '';
  lastSuccess: boolean = false;

  async checkin(): Promise<boolean> {
    if (!this.currentCourseId || !this.latitude || !this.longitude) {
      this.lastResult = '缺少签到信息（课程/位置）';
      this.lastSuccess = false;
      return false;
    }

    this.isCheckingIn = true;
    this.lastResult = '';

    try {
      // await AttendanceApi.checkin(
      //   this.currentCourseId, this.latitude, this.longitude,
      //   this.deviceId, this.token
      // );
      this.lastResult = '签到成功';
      this.lastSuccess = true;
      return true;
    } catch (e) {
      this.lastResult = '签到失败: ' + JSON.stringify(e);
      this.lastSuccess = false;
      return false;
    } finally {
      this.isCheckingIn = false;
    }
  }

  reset() {
    this.currentCourseId = 0;
    this.currentCourseName = '';
    this.latitude = 0;
    this.longitude = 0;
    this.isCheckingIn = false;
    this.lastResult = '';
    this.lastSuccess = false;
  }
}
