import { HttpClient } from './httpClient';

export class ClassApi {
  /** Get all class list (for teacher to select when creating checkin) */
  static async getList(token: string): Promise<object> {
    return HttpClient.get('/class/list/', token);
  }
}
