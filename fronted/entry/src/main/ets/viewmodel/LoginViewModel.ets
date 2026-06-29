import { AuthApi } from '../services/api/authApi';

export interface UserInfo {
  id: number;
  username: string;
  role: string;
  role_display: string;
  face_registered: boolean;
}

export class LoginViewModel {
  username: string = '';
  password: string = '';
  isLoading: boolean = false;
  errorMessage: string = '';
  faceLoginAvailable: boolean = false;

  token: string = '';
  refreshToken: string = '';
  userInfo: UserInfo | null = null;

  async login(): Promise<boolean> {
    if (!this.username || !this.password) {
      this.errorMessage = '请输入用户名和密码';
      return false;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const response: any = await AuthApi.login(this.username, this.password);
      this.token = response.access;
      this.refreshToken = response.refresh;
      this.userInfo = response.user;
      return true;
    } catch (e) {
      this.errorMessage = '登录失败，请检查用户名和密码';
      return false;
    } finally {
      this.isLoading = false;
    }
  }

  async checkFaceService(): Promise<void> {
    // Check if face recognition service is available
    try {
      const response: any = await AuthApi.checkFaceService();
      this.faceLoginAvailable = response.service_available === true;
    } catch (e) {
      this.faceLoginAvailable = false;
    }
  }
}
