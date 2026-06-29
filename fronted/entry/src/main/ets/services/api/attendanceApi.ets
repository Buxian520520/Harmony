import { HttpClient } from './httpClient';

export class AttendanceApi {
  static async getMyCourses(token: string): Promise<object> {
    return HttpClient.get('/attendance/courses/my_courses/', token);
  }

  static async checkin(courseId: number, latitude: number, longitude: number, deviceId: string, token: string): Promise<object> {
    return HttpClient.post('/attendance/checkin/checkin/', {
      course_id: courseId,
      latitude: latitude,
      longitude: longitude,
      device_id: deviceId,
    }, token);
  }

  static async getMyRecords(token: string, courseId?: number): Promise<object> {
    let path = '/attendance/checkin/my_records/';
    if (courseId) {
      path += `?course_id=${courseId}`;
    }
    return HttpClient.get(path, token);
  }

  static async getCourseRecords(courseId: number, token: string): Promise<object> {
    return HttpClient.get(`/attendance/checkin/course_records/?course_id=${courseId}`, token);
  }

  static async submitLeave(data: object, token: string): Promise<object> {
    return HttpClient.post('/attendance/leave/', data, token);
  }

  static async getMyLeaves(token: string): Promise<object> {
    return HttpClient.get('/attendance/leave/my_requests/', token);
  }

  static async getPendingReviews(token: string): Promise<object> {
    return HttpClient.get('/attendance/leave/pending_reviews/', token);
  }

  static async reviewLeave(leaveId: number, action: string, comment: string, token: string): Promise<object> {
    return HttpClient.post(`/attendance/leave/${leaveId}/review/`, { action, comment }, token);
  }

  static async getCourseSummary(courseId: number, token: string): Promise<object> {
    return HttpClient.get(`/attendance/statistics/course_summary/?course_id=${courseId}`, token);
  }

  static async getMyTrend(token: string, days: number = 30): Promise<object> {
    return HttpClient.get(`/attendance/statistics/my_trend/?days=${days}`, token);
  }
}
