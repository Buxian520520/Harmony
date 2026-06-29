import http from '@ohos.net.http';

export class HttpClient {
  static BASE_URL = 'http://10.0.2.2:8000/api/v1';  // Dev: emulator -> host

  static async request(
    method: http.RequestMethod,
    path: string,
    data?: object,
    token?: string
  ): Promise<object> {
    const httpRequest = http.createHttp();
    const url = HttpClient.BASE_URL + path;

    const headers: object = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = 'Bearer ' + token;
    }

    try {
      const response = await httpRequest.request(url, {
        method: method,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        connectTimeout: 30000,
        readTimeout: 30000,
      });

      if (response.responseCode === 200 || response.responseCode === 201) {
        return JSON.parse(response.result.toString());
      } else {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  static async get(path: string, token?: string): Promise<object> {
    return HttpClient.request(http.RequestMethod.GET, path, undefined, token);
  }

  static async post(path: string, data?: object, token?: string): Promise<object> {
    return HttpClient.request(http.RequestMethod.POST, path, data, token);
  }

  static async patch(path: string, data?: object, token?: string): Promise<object> {
    return HttpClient.request(http.RequestMethod.PATCH, path, data, token);
  }

  static async delete(path: string, token?: string): Promise<object> {
    return HttpClient.request(http.RequestMethod.DELETE, path, undefined, token);
  }
}
