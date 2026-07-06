import { HttpClient } from './httpClient';

interface LoginRequest {
  username: string;
  password: string;
  role?: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
  role: string;
  student_name?: string;
  gender?: string;
  birthday?: string;
  mobile?: string;
  email?: string;
  address?: string;
  teacher_no?: string;
  teacher_name?: string;
}

interface RefreshRequest {
  refresh_token: string;
}

export class AuthApi {
  static async login(username: string, password: string, role?: string): Promise<object> {
    const data: LoginRequest = { username, password, role: role || 'student' };
    return HttpClient.post('/login/', data);
  }

  static async register(data: RegisterRequest): Promise<object> {
    return HttpClient.post('/register/', data);
  }

  static async refresh(refreshToken: string): Promise<object> {
    const data: RefreshRequest = { refresh_token: refreshToken };
    return HttpClient.post('/refresh/', data);
  }
}
