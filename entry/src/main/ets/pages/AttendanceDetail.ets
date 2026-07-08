import { Nav } from '../utils/NavigationUtil';

@Component
export struct AttendanceDetailComponent {
  @State message: string = '考勤详情';

  aboutToAppear() {
    // This page serves as a placeholder for teacher-side attendance detail.
    // Students see their records in the Statistics page.
  }

  build() {
    NavDestination() {
      Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { Nav.stack.pop() })
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Column() {
        Text('考勤详情功能请在「统计」页面查看')
          .fontSize(16)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .margin({ top: 100 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    }
    .title('考勤详情')
    .hideTitleBar(true)
  }
}
