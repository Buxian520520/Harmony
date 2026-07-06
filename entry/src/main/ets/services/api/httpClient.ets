import http from '@ohos.net.http';

interface RequestHeaders {
  'Content-Type': string;
  'Authorization'?: string;
}

interface ApiResponse {
  code: number;
  msg?: string;
  data?: Object;
  access_token?: string;
  refresh_token?: string;
}

export class HttpClient {
  // HarmonyOS emulator: 10.0.2.2 maps to host machine's localhost
  // The new backend runs at root level (no /api/v1/ prefix)
  static BASE_URL = 'http://10.0.2.2:8000';

  static async request(
    method: http.RequestMethod,
    path: string,
    data?: object,
    token?: string
  ): Promise<ApiResponse> {
    const httpRequest = http.createHttp();
    const url = HttpClient.BASE_URL + path;

    const headers: RequestHeaders = token
      ? { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }
      : { 'Content-Type': 'application/json' };

    try {
      const response = await httpRequest.request(url, {
        method: method,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 30000,
        readTimeout: 30000,
      });

      if (response.responseCode === 200 || response.responseCode === 201) {
        return JSON.parse(response.result.toString()) as ApiResponse;
      } else {
        // Try to parse error body
        let errorBody: ApiResponse = { code: response.responseCode };
        try {
          errorBody = JSON.parse(response.result.toString()) as ApiResponse;
        } catch (_) {
          // ignore parse error
        }
        throw new Error(errorBody.msg || `HTTP ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  static async get(path: string, token?: string): Promise<ApiResponse> {
    return HttpClient.request(http.RequestMethod.GET, path, undefined, token);
  }

  static async post(path: string, data?: object, token?: string): Promise<ApiResponse> {
    return HttpClient.request(http.RequestMethod.POST, path, data, token);
  }
}
