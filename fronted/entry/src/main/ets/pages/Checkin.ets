import router from '@ohos.router';
import geolocation from '@ohos.geolocation';
import deviceInfo from '@ohos.deviceInfo';
import { AttendanceApi } from '../services/api/attendanceApi';

@Entry
@Component
struct Checkin {
  @State courseId: number = 0;
  @State courseName: string = '请选择课程';
  @State locationStatus: string = '正在获取位置...';
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State deviceId: string = '';
  @State isCheckinInProgress: boolean = false;
  @State checkinResult: string = '';
  @State checkinSuccess: boolean = false;

  private token: string = '';

  aboutToAppear() {
    this.getDeviceInfo();
    this.getLocation();
  }

  getDeviceInfo() {
    try {
      this.deviceId = deviceInfo.deviceId;
    } catch (e) {
      this.deviceId = 'unknown-device';
    }
  }

  getLocation() {
    try {
      geolocation.getCurrentLocation({
        priority: geolocation.LocationRequestPriority.ACCURACY,
        scenario: geolocation.LocationRequestScenario.NAVIGATION,
        maxAge: 5000,
        timeout: 10000,
      }).then((location) => {
        this.latitude = location.latitude;
        this.longitude = location.longitude;
        this.locationStatus = '位置已获取';
      }).catch((err) => {
        this.locationStatus = '获取位置失败: ' + err.message;
      });
    } catch (e) {
      this.locationStatus = '定位服务不可用';
    }
  }

  async doCheckin() {
    if (this.courseId === 0) {
      this.checkinResult = '请先选择课程';
      return;
    }

    this.isCheckinInProgress = true;
    this.checkinResult = '';
    this.checkinSuccess = false;

    try {
      // Add the courses API endpoint - need to add getMyCourses
      // const result = await AttendanceApi.checkin(
      //   this.courseId, this.latitude, this.longitude,
      //   this.deviceId, this.token
      // );
      // this.checkinResult = '签到成功！';
      // this.checkinSuccess = true;

      // Mock for now
      this.checkinResult = '签到成功！';
      this.checkinSuccess = true;
    } catch (e) {
      this.checkinResult = '签到失败: ' + JSON.stringify(e);
      this.checkinSuccess = false;
    } finally {
      this.isCheckinInProgress = false;
    }
  }

  build() {
    Column() {
      // Header
      Text('定位签到')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })

      // Course selector (TODO: course picker)
      Column() {
        Text(this.courseName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Text('点击选择课程 >')
          .fontSize(14)
          .fontColor('#007AFF')
          .margin({ top: 8 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 16 })
      .onClick(() => {
        // TODO: Show course picker
      })

      // Location status
      Column() {
        Row() {
          Circle()
            .width(12)
            .height(12)
            .fill(this.latitude !== 0 ? '#34C759' : '#FF9500')
          Text(this.locationStatus)
            .fontSize(15)
            .fontColor(this.latitude !== 0 ? '#34C759' : '#FF9500')
            .margin({ left: 8 })
        }

        if (this.latitude !== 0) {
          Text('经度: ' + this.longitude.toFixed(6))
            .fontSize(13)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
          Text('纬度: ' + this.latitude.toFixed(6))
            .fontSize(13)
            .fontColor('#8E8E93')
        }

        Text('设备: ' + this.deviceId.substring(0, 16) + '...')
          .fontSize(13)
          .fontColor('#8E8E93')
          .margin({ top: 4 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 24 })

      // Checkin button
      Button() {
        if (this.isCheckinInProgress) {
          LoadingProgress().width(24).height(24).fontColor(Color.White)
        } else {
          Text('签 到')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
      }
      .type(ButtonType.Capsule)
      .width('80%')
      .height(56)
      .backgroundColor('#007AFF')
      .enabled(!this.isCheckinInProgress && this.latitude !== 0)
      .onClick(() => { this.doCheckin() })

      if (!this.isCheckinInProgress && this.latitude === 0) {
        Text('请等待定位完成后再签到')
          .fontSize(13)
          .fontColor('#FF9500')
          .margin({ top: 8 })
      }

      // Result
      if (this.checkinResult) {
        Column() {
          Text(this.checkinSuccess ? '✅' : '❌')
            .fontSize(40)
          Text(this.checkinResult)
            .fontSize(16)
            .fontColor(this.checkinSuccess ? '#34C759' : '#FF3B30')
            .margin({ top: 8 })
        }
        .margin({ top: 24 })
      }

      // Face checkin button (placeholder)
      if (false) {  // Toggle when face service is ready
        Button('扫脸签到')
          .type(ButtonType.Capsule)
          .width('80%')
          .height(48)
          .margin({ top: 16 })
          .backgroundColor('#34C759')
          .fontColor(Color.White)
          .onClick(() => {
            // TODO: Open camera, capture face, upload for verification
          })
      }

      Text('扫脸签到功能待接入')
        .fontSize(13)
        .fontColor('#C7C7CC')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}
