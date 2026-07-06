import router from '@ohos.router';

@Entry
@Component
struct Approval {
  @State message: string = '审批管理';

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Column() {
        Text('请假审批功能请在教师端使用')
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
}
