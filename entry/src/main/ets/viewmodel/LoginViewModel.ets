import { AuthApi } from '../services/api/authApi';

interface LoginResponse {
  code: number;
  msg: string;
  access_token: string;
  refresh_token: string;
}

export class LoginViewModel {
  username: string = '';
  password: string = '';
  role: string = 'student';
  isLoading: boolean = false;
  errorMessage: string = '';

  token: string = '';
  refreshToken: string = '';

  async login(): Promise<boolean> {
    if (!this.username || !this.password) {
      this.errorMessage = '请输入用户名和密码';
      return false;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const response = await AuthApi.login(this.username, this.password, this.role) as LoginResponse;
      if (response.code === 200) {
        this.token = response.access_token;
        this.refreshToken = response.refresh_token;
        return true;
      } else {
        this.errorMessage = response.msg || '登录失败';
        return false;
      }
    } catch (e) {
      this.errorMessage = '登录失败，请检查用户名和密码';
      return false;
    } finally {
      this.isLoading = false;
    }
  }
}
