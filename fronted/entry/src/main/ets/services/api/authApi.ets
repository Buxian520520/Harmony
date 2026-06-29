import { HttpClient } from './httpClient';

export class AuthApi {
  static async login(username: string, password: string): Promise<object> {
    return HttpClient.post('/auth/login/', { username, password });
  }

  static async register(data: object): Promise<object> {
    return HttpClient.post('/auth/register/', data);
  }

  static async refresh(refreshToken: string): Promise<object> {
    return HttpClient.post('/auth/refresh/', { refresh: refreshToken });
  }

  static async logout(refreshToken: string, accessToken: string): Promise<object> {
    return HttpClient.post('/auth/logout/', { refresh: refreshToken }, accessToken);
  }

  static async checkFaceService(): Promise<object> {
    return HttpClient.get('/recognition/health/');
  }
}
