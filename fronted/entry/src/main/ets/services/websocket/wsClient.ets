import webSocket from '@ohos.net.webSocket';

export class WsClient {
  private ws: webSocket.WebSocket;
  private url: string;
  private onMessage: (data: string) => void;

  constructor(path: string, token: string, onMessage: (data: string) => void) {
    this.url = `ws://10.0.2.2:8000${path}?token=${token}`;
    this.onMessage = onMessage;
    this.ws = webSocket.createWebSocket();
  }

  connect() {
    this.ws.connect(this.url, (err, value) => {
      if (!err) {
        console.log('WebSocket connected');
        this.ws.on('message', (err, data) => {
          if (!err && this.onMessage) {
            this.onMessage(data.toString());
          }
        });
      }
    });
  }

  send(data: string) {
    this.ws.send(data, (err) => {
      if (err) {
        console.error('WebSocket send error: ' + JSON.stringify(err));
      }
    });
  }

  close() {
    this.ws.close((err) => {
      console.log('WebSocket closed');
    });
  }
}
