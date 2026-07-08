import { HttpClient } from './httpClient';

interface SignInQrRequest {
  task_id: number;
  type: string;
  code: string;
}

interface SignInLocationRequest {
  task_id: number;
  type: string;
  lat: number;
  lng: number;
  device_id: string;
}

interface CreateTaskRequest {
  title: string;
  type: string;
  code: string;
  range: number;
  lat: number;
  lng: number;
}

interface EndTaskRequest {
  task_id: number;
}

interface AddRecordRequest {
  task_id: number;
  sno: string;
  name: string;
}

export class CheckinApi {
  /** Get active (ongoing) checkin tasks */
  static async getTasks(token: string): Promise<object> {
    return HttpClient.get('/checkin/tasks/', token);
  }

  /** Student: sign in via QR code */
  static async signInByQr(taskId: number, code: string, token: string): Promise<object> {
    const data: SignInQrRequest = { task_id: taskId, type: 'qrcode', code };
    return HttpClient.post('/checkin/sign/', data, token);
  }

  /** Student: sign in via location */
  static async signInByLocation(taskId: number, latitude: number, longitude: number, deviceId: string, token: string): Promise<object> {
    const data: SignInLocationRequest = { task_id: taskId, type: 'location', lat: latitude, lng: longitude, device_id: deviceId };
    return HttpClient.post('/checkin/sign/', data, token);
  }

  /** Student: view own checkin history */
  static async getMyRecords(token: string): Promise<object> {
    return HttpClient.get('/checkin/myrecords/', token);
  }

  /** Get past (ended) checkin tasks (teacher) */
  static async getHistory(token: string): Promise<object> {
    return HttpClient.get('/checkin/history/', token);
  }

  /** Get attendance detail for a task (teacher) */
  static async getAttendance(taskId: number, token: string): Promise<object> {
    return HttpClient.get(`/checkin/attendance/?task_id=${taskId}`, token);
  }

  /** Teacher: create a new checkin task */
  static async createTask(title: string, type: string, code: string, range: number, lat: number, lng: number, token: string): Promise<object> {
    const data: CreateTaskRequest = { title, type, code, range, lat, lng };
    return HttpClient.post('/checkin/create/', data, token);
  }

  /** Teacher: end a checkin task */
  static async endTask(taskId: number, token: string): Promise<object> {
    const data: EndTaskRequest = { task_id: taskId };
    return HttpClient.post('/checkin/end/', data, token);
  }

  /** Teacher: manually add a sign-in record (补签) */
  static async addRecord(taskId: number, sno: string, name: string, token: string): Promise<object> {
    const data: AddRecordRequest = { task_id: taskId, sno, name };
    return HttpClient.post('/checkin/record/add/', data, token);
  }
}
