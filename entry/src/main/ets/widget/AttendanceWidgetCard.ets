@Entry
@Component
struct AttendanceWidgetCard {
  @State courseName: string = '高等数学';
  @State status: string = '未签到';
  @State pendingLeaves: string = '2';

  build() {
    Column() {
      Text('📚 今日课程')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(this.courseName)
        .fontSize(16)
        .fontColor('#007AFF')
        .margin({ top: 8 })
        .width('100%')

      Row() {
        Circle().width(6).height(6).fill('#FF9500')
        Text(' ' + this.status)
          .fontSize(12)
          .fontColor('#FF9500')
      }
      .margin({ top: 4 })
      .width('100%')

      Row() {
        Text('📋 待审批: ' + this.pendingLeaves)
          .fontSize(12)
          .fontColor('#8E8E93')
      }
      .margin({ top: 6 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
