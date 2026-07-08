import router from '@ohos.router';
import { Nav } from '../utils/NavigationUtil';

@Component
export struct ProfileComponent {
  @State userName: string = '学生';
  @State studentNo: string = '';

  aboutToAppear() {
    const savedName = AppStorage.get<string>('username') || '';
    if (savedName) {
      this.userName = savedName;
      this.studentNo = savedName;
    }
  }

  build() {
    NavDestination() {
      Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { Nav.stack.pop() })
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
        ProfileMenuItem({ icon: '📋', title: '签到任务', onClickAction: () => { Nav.stack.pushPathByName('Home', undefined) } })
        ProfileMenuItem({ icon: '📊', title: '签到记录', onClickAction: () => { Nav.stack.pushPathByName('Statistics', undefined) } })
        ProfileMenuItem({ icon: '📝', title: '请假申请', onClickAction: () => { Nav.stack.pushPathByName('LeaveApply', undefined) } })
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
    .title('个人中心')
    .hideTitleBar(true)
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
