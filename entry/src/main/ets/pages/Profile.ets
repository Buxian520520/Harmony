import router from '@ohos.router';

@Entry
@Component
struct Profile {
  @State userName: string = '学生';
  @State studentNo: string = '';

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

        if (this.studentNo) {
          Text('学号: ' + this.studentNo)
            .fontSize(15)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Color.White)
      .alignItems(HorizontalAlign.Center)

      // Menu list
      Column() {
        ProfileMenuItem({ icon: '📋', title: '签到任务', onClickAction: () => { router.pushUrl({ url: 'pages/Home' }) } })
        ProfileMenuItem({ icon: '📊', title: '签到记录', onClickAction: () => { router.pushUrl({ url: 'pages/Statistics' }) } })
        ProfileMenuItem({ icon: '📝', title: '请假申请', onClickAction: () => { router.pushUrl({ url: 'pages/LeaveApply' }) } })
        ProfileMenuItem({ icon: 'ℹ️', title: '关于', onClickAction: () => {} })
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
          // Clear token, navigate to login
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
  @Prop icon: string = '';
  @Prop title: string = '';
  onClickAction: () => void = () => {};

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
