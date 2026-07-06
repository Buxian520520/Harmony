import router from '@ohos.router';
import geolocation from '@ohos.geolocation';
import { CheckinApi } from '../services/api/checkinApi';

interface SignInResponse {
  code: number;
  msg?: string;
}

interface SignInParams {
  taskId: number;
  taskTitle: string;
  type: string;
  code: string;
  range: number;
}

@Entry
@Component
struct Checkin {
  @State taskId: number = 0;
  @State taskTitle: string = '签到';
  @State taskType: string = 'qrcode';
  @State taskCode: string = '';
  @State taskRange: number = 100;
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State locationStatus: string = '正在获取位置...';
  @State isSigningIn: boolean = false;
  @State resultMessage: string = '';
  @State resultSuccess: boolean = false;

  private token: string = AppStorage.get<string>('access_token') || '';

  aboutToAppear() {
    const params = router.getParams() as SignInParams;
    this.taskId = params.taskId || 0;
    this.taskTitle = params.taskTitle || '签到';
    this.taskType = params.type || 'qrcode';

    if (this.taskType === 'qrcode') {
      this.taskCode = params.code || '';
    } else {
      this.taskRange = params.range || 100;
      this.getLocation();
    }
  }

  getLocation() {
    try {
      const request: geolocation.CurrentLocationRequest = {
        priority: geolocation.LocationRequestPriority.ACCURACY,
        scenario: geolocation.LocationRequestScenario.NAVIGATION,
        timeoutMs: 10000,
      };
      geolocation.getCurrentLocation(request).then((location) => {
        this.latitude = location.latitude;
        this.longitude = location.longitude;
        this.locationStatus = '位置已获取 (距教师参考点 ' + this.taskRange + 'm 内有效)';
      }).catch(() => {
        this.locationStatus = '获取位置失败，请检查定位权限';
      });
    } catch (e) {
      this.locationStatus = '定位服务不可用';
    }
  }

  async doSignIn() {
    this.isSigningIn = true;
    this.resultMessage = '';

    try {
      let response: SignInResponse;
      if (this.taskType === 'qrcode') {
        response = await CheckinApi.signInByQr(this.taskId, this.taskCode, this.token) as SignInResponse;
      } else {
        if (this.latitude === 0 && this.longitude === 0) {
          this.resultMessage = '请先获取位置信息';
          this.resultSuccess = false;
          this.isSigningIn = false;
          return;
        }
        response = await CheckinApi.signInByLocation(this.taskId, this.latitude, this.longitude, this.token) as SignInResponse;
      }

      if (response.code === 1 || response.code === 200) {
        this.resultMessage = response.msg || '签到成功！';
        this.resultSuccess = true;
      } else {
        this.resultMessage = response.msg || '签到失败';
        this.resultSuccess = false;
      }
    } catch (e) {
      this.resultMessage = '签到失败，请检查网络连接';
      this.resultSuccess = false;
    } finally {
      this.isSigningIn = false;
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text(this.taskTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Column() {
        // Task info
        Column() {
          Text(this.taskType === 'qrcode' ? '📱 二维码签到' : '📍 位置签到')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })

          if (this.taskType === 'qrcode') {
            Text('请输入教师展示的签到码')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ top: 12, bottom: 8 })

            TextInput({ placeholder: '请输入签到码', text: this.taskCode })
              .width('80%').height(48).backgroundColor('#F2F2F7').borderRadius(8)
              .fontSize(20).fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .onChange((v: string) => { this.taskCode = v })
          } else {
            Text('有效范围: ' + this.taskRange + ' 米')
              .fontSize(16)
              .fontColor('#8E8E93')
              .margin({ bottom: 8 })

            // Location status
            Row() {
              Circle()
                .width(12)
                .height(12)
                .fill(this.latitude !== 0 ? '#34C759' : '#FF9500')
              Text(this.locationStatus)
                .fontSize(14)
                .fontColor(this.latitude !== 0 ? '#34C759' : '#FF9500')
                .margin({ left: 8 })
            }

            if (this.latitude !== 0) {
              Text('经度: ' + this.longitude.toFixed(6))
                .fontSize(12)
                .fontColor('#8E8E93')
                .margin({ top: 4 })
              Text('纬度: ' + this.latitude.toFixed(6))
                .fontSize(12)
                .fontColor('#8E8E93')
            }
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)

        // Sign in button
        Button() {
          if (this.isSigningIn) {
            LoadingProgress().width(24).height(24).color(Color.White)
          } else {
            Text('确认签到')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
        }
        .type(ButtonType.Capsule)
        .width('80%')
        .height(56)
        .backgroundColor('#007AFF')
        .margin({ top: 30 })
        .enabled(!this.isSigningIn)
        .onClick(() => { this.doSignIn() })

        // Result
        if (this.resultMessage) {
          Column() {
            Text(this.resultSuccess ? '✅' : '❌')
              .fontSize(40)
            Text(this.resultMessage)
              .fontSize(16)
              .fontColor(this.resultSuccess ? '#34C759' : '#FF3B30')
              .margin({ top: 8 })
          }
          .margin({ top: 24 })
        }

        if (this.resultSuccess) {
          Button('返回首页')
            .type(ButtonType.Capsule)
            .width('60%')
            .height(44)
            .fontSize(15)
            .backgroundColor('#34C759')
            .fontColor(Color.White)
            .margin({ top: 20 })
            .onClick(() => {
              router.replaceUrl({ url: 'pages/Home' });
            })
        }
      }
      .width('90%')
      .margin({ top: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
