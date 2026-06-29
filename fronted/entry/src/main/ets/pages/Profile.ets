import router from '@ohos.router';

@Entry
@Component
struct Profile {
  @State userName: string = '用户';
  @State userRole: string = '学生';
  @State studentId: string = '';
  @State faceRegistered: boolean = false;

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('个人中心')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      // Profile card
      Column() {
        Circle()
          .width(72)
          .height(72)
          .fill('#007AFF')
        Text(this.userName.charAt(0))
          .fontSize(32)
          .fontColor(Color.White)
          .position({ x: 22, y: 12 })

        Text(this.userName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 12 })

        Text(this.userRole + (this.studentId ? ' | ' + this.studentId : ''))
          .fontSize(15)
          .fontColor('#8E8E93')
          .margin({ top: 4 })

        if (this.faceRegistered) {
          Text('✅ 已注册人脸')
            .fontSize(14)
            .fontColor('#34C759')
            .margin({ top: 8 })
        } else {
          Text('人脸识别功能待接入')
            .fontSize(14)
            .fontColor('#C7C7CC')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Center)

      // Menu list
      Column() {
        ProfileMenuItem('📋', '我的课程', () => { router.pushUrl({ url: 'pages/Home' }) })
        ProfileMenuItem('📄', '请假记录', () => { router.pushUrl({ url: 'pages/LeaveApply' }) })
        ProfileMenuItem('📊', '考勤统计', () => { router.pushUrl({ url: 'pages/Statistics' }) })
        ProfileMenuItem('👤', '人脸管理', () => {
          // TODO: Navigate to face registration page
        })
        ProfileMenuItem('⚙️', '账号设置', () => {})
        ProfileMenuItem('ℹ️', '关于', () => {})
      }
      .width('100%')
      .margin({ top: 16 })

      // Logout button
      Button('退出登录')
        .type(ButtonType.Capsule)
        .width('90%')
        .height(50)
        .fontColor('#FF3B30')
        .backgroundColor(Color.White)
        .border({ width: 1, color: '#FF3B30' })
        .margin({ top: 30 })
        .onClick(() => {
          // TODO: Clear token, navigate to login
          router.clear()
          router.pushUrl({ url: 'pages/Login' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

@Component
struct ProfileMenuItem {
  private icon: string = '';
  private title: string = '';
  private onClickAction: () => void = () => {};

  build() {
    Row() {
      Text(this.icon).fontSize(20).margin({ right: 12 })
      Text(this.title).fontSize(16)
      Blank()
      Text('>').fontColor('#C7C7CC').fontSize(16)
    }
    .width('100%')
    .height(50)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#F2F2F7' })
    .onClick(() => { this.onClickAction() })
  }
}
