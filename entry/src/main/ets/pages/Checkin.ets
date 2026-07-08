import router from '@ohos.router';
import geolocation from '@ohos.geolocation';
import dataPreferences from '@ohos.data.preferences';
import { CheckinApi } from '../services/api/checkinApi';
import { MapKitView, MapMarker } from '../widget/MapKitView';
import { requestLocationPermissions } from '../services/utils/permissionUtil';

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
  teacherLat?: number;
  teacherLng?: number;
}

@Entry
@Component
struct Checkin {
  @State taskId: number = 0;
  @State taskTitle: string = '签到';
  @State taskType: string = 'qrcode';
  @State taskCode: string = '';
  @State taskRange: number = 100;
  @State deviceId: string = '';
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State locationStatus: string = '正在获取位置...';
  @State teacherLat: number = 0;
  @State teacherLng: number = 0;
  @State mapMarkers: Array<MapMarker> = [];
  @State mapCenterLat: number = 39.9;
  @State mapCenterLng: number = 116.4;
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
      this.teacherLat = params.teacherLat || 0;
      this.teacherLng = params.teacherLng || 0;
      this.getDeviceId();
      this.requestPermAndGetLocation();
    }
  }

  async getDeviceId() {
    try {
      const prefs = await dataPreferences.getPreferences(getContext(this), 'device_binding');
      let id = await prefs.get('device_id', '') as string;
      if (!id) {
        id = this.generateUUID();
        await prefs.put('device_id', id);
        await prefs.flush();
      }
      this.deviceId = id;
    } catch (_e) {
      this.deviceId = '';
    }
  }

  generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  async requestPermAndGetLocation() {
    const granted = await requestLocationPermissions();
    if (granted) {
      await this.getLocation();
    } else {
      this.locationStatus = '请授予定位权限后重试';
      this.updateMapMarkers();
    }
  }

  async getLocation() {
    try {
      const request: geolocation.CurrentLocationRequest = {
        priority: geolocation.LocationRequestPriority.FIRST_FIX,
        scenario: geolocation.LocationRequestScenario.UNSET,
        timeoutMs: 15000,
      };
      const location = await geolocation.getCurrentLocation(request);
      this.latitude = location.latitude;
      this.longitude = location.longitude;
      this.locationStatus = '位置已获取';
      this.updateMapMarkers();
      return;
    } catch (_e1) { }

    try {
      const lastLoc = await geolocation.getLastLocation();
      this.latitude = lastLoc.latitude;
      this.longitude = lastLoc.longitude;
      this.locationStatus = '使用最近位置';
      this.updateMapMarkers();
      return;
    } catch (_e2) {
      this.locationStatus = '获取位置失败';
      this.updateMapMarkers();
    }
  }

  updateMapMarkers() {
    const markers: Array<MapMarker> = [];
    let sumLat = 0;
    let sumLng = 0;
    let count = 0;

    if (this.latitude !== 0 || this.longitude !== 0) {
      markers.push({ latitude: this.latitude, longitude: this.longitude, label: '我', color: '#007AFF' });
      sumLat += this.latitude;
      sumLng += this.longitude;
      count++;
    }
    if (this.teacherLat !== 0 || this.teacherLng !== 0) {
      markers.push({ latitude: this.teacherLat, longitude: this.teacherLng, label: '教师', color: '#FF9500' });
      sumLat += this.teacherLat;
      sumLng += this.teacherLng;
      count++;
    }

    if (count > 0) {
      this.mapCenterLat = sumLat / count;
      this.mapCenterLng = sumLng / count;
    }
    this.mapMarkers = markers;
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
        response = await CheckinApi.signInByLocation(this.taskId, this.latitude, this.longitude, this.deviceId, this.token) as SignInResponse;
      }

      if (response.code === 1 || response.code === 200) {
        this.resultMessage = response.msg || '签到成功！';
        this.resultSuccess = true;
        // Store signed taskId so Main.ets can pick it up
        AppStorage.setOrCreate('signed_task_id', this.taskId);
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
    Stack() {
      // === Full-screen map (location mode) ===
      if (this.taskType === 'location') {
        MapKitView({
          centerLat: this.mapCenterLat,
          centerLng: this.mapCenterLng,
          zoom: 16,
          markers: this.mapMarkers
        })
          .width('100%')
          .height('100%')

        // Top bar: back button + title + status
        Row() {
          Button() {
            Text('←').fontSize(22).fontColor('#333')
          }
          .width(40).height(40).borderRadius(20).backgroundColor('#FFFFFFDD')
          .onClick(() => { router.back() })

          Column() {
            Text(this.taskTitle)
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Circle().width(8).height(8)
                .fill(this.latitude !== 0 ? '#34C759' : '#FF9500')
              Text(this.latitude !== 0 ? '已定位' : this.locationStatus)
                .fontSize(11)
                .fontColor(this.latitude !== 0 ? '#34C759' : '#FF9500')
                .margin({ left: 4 })
              Text(' · 范围' + this.taskRange + 'm')
                .fontSize(11).fontColor('#8E8E93')
            }
            .margin({ top: 2 })
          }
          .margin({ left: 8 }).layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 44, bottom: 6 })
        .backgroundColor('#FFFFFFEE')
        .position({ x: 0, y: 0 })

        // Bottom: sign-in button
        Button() {
          if (this.isSigningIn) {
            LoadingProgress().width(22).height(22).color(Color.White)
          } else {
            Text('确认签到').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
          }
        }
        .type(ButtonType.Capsule).width('90%').height(50)
        .backgroundColor('#007AFF').enabled(!this.isSigningIn)
        .shadow({ radius: 8, color: '#40000000', offsetY: 2 })
        .position({ x: '5%', y: '88%' })
        .onClick(() => { this.doSignIn() })

        // Result modal
        if (this.resultMessage) {
          Column() {
            Text(this.resultSuccess ? '✅' : '❌').fontSize(48)
            Text(this.resultMessage).fontSize(16).fontColor('#333').margin({ top: 8 })
            if (this.resultSuccess) {
              Button('返回首页')
                .type(ButtonType.Capsule).width('60%').height(44).fontSize(15)
                .backgroundColor('#34C759').fontColor(Color.White).margin({ top: 16 })
                .onClick(() => { router.back() })
            } else {
              Button('重试')
                .type(ButtonType.Capsule).width('60%').height(44).fontSize(15)
                .backgroundColor('#FF9500').fontColor(Color.White).margin({ top: 16 })
                .onClick(() => { this.resultMessage = '' })
            }
          }
          .width('80%').padding(24).backgroundColor('#FFFFFFF8')
          .borderRadius(16).shadow({ radius: 20, color: '#20000000' })
          .position({ x: '10%', y: '30%' })
        }
      }

      // === QR code mode (non-map) ===
      if (this.taskType === 'qrcode') {
        Column() {
          Row() {
            Text('←').fontSize(22)
              .onClick(() => { router.back() })
            Text(this.taskTitle).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
            Blank()
          }
          .width('100%').padding(16)

          Column() {
            Column() {
              Text('📱 二维码签到').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
              Text('请输入教师展示的签到码').fontSize(14).fontColor('#8E8E93').margin({ top: 12, bottom: 8 })
              TextInput({ placeholder: '请输入签到码', text: this.taskCode })
                .width('80%').height(48).backgroundColor('#F2F2F7').borderRadius(8)
                .fontSize(20).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
                .onChange((v: string) => { this.taskCode = v })
            }
            .width('100%').padding(20).backgroundColor(Color.White)
            .borderRadius(12).alignItems(HorizontalAlign.Center)

            Button() {
              if (this.isSigningIn) {
                LoadingProgress().width(24).height(24).color(Color.White)
              } else {
                Text('确认签到').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
              }
            }
            .type(ButtonType.Capsule).width('80%').height(56)
            .backgroundColor('#007AFF').margin({ top: 30 })
            .enabled(!this.isSigningIn)
            .onClick(() => { this.doSignIn() })
          }
          .width('90%').margin({ top: 24 })
        }
        .width('100%').height('100%').backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
