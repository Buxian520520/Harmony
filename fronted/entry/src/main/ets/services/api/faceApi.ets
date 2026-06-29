import { HttpClient } from './httpClient';

export class FaceApi {
  /**
   * Face Recognition API interface.
   * Currently a placeholder - will be enabled when face-service is deployed.
   */
  static async registerFace(imageData: ArrayBuffer, token: string): Promise<object> {
    // TODO: Upload face image to registration endpoint
    // const response = await HttpClient.upload('/recognition/register/', imageData, token);
    // return response;
    return { success: false, message: '功能待接入' };
  }

  static async verifyFace(imageData: ArrayBuffer, token: string): Promise<object> {
    // TODO: 1:1 face verification
    return { is_match: false, message: '功能待接入' };
  }

  static async identifyFace(imageData: ArrayBuffer, token: string): Promise<object> {
    // TODO: 1:N face identification for login
    return { matches: [], message: '功能待接入' };
  }

  static async checkServiceHealth(token: string): Promise<object> {
    return HttpClient.get('/recognition/health/', token);
  }
}
