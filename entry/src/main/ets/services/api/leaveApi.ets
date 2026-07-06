import { HttpClient } from './httpClient';

interface ApplyLeaveRequest {
  startDate: string;
  endDate: string;
  leaveType: string;
  reason: string;
}

interface ReviewRequest {
  leaveId: number;
  comment: string;
}

export class LeaveApi {
  /** Student: get own leave records */
  static async getMyLeaves(token: string): Promise<object> {
    return HttpClient.get('/leaves/', token);
  }

  /** Student: apply for leave */
  static async applyLeave(startDate: string, endDate: string, leaveType: string, reason: string, token: string): Promise<object> {
    const data: ApplyLeaveRequest = { startDate, endDate, leaveType, reason };
    return HttpClient.post('/leave/apply/', data, token);
  }

  /** Get leave detail by id */
  static async getLeaveDetail(leaveId: number, token: string): Promise<object> {
    return HttpClient.get(`/leave/detail/${leaveId}/`, token);
  }

  /** Teacher: approve leave */
  static async approveLeave(leaveId: number, comment: string, token: string): Promise<object> {
    const data: ReviewRequest = { leaveId, comment };
    return HttpClient.post('/leave/approve/', data, token);
  }

  /** Teacher: reject leave */
  static async rejectLeave(leaveId: number, comment: string, token: string): Promise<object> {
    const data: ReviewRequest = { leaveId, comment };
    return HttpClient.post('/leave/reject/', data, token);
  }
}
