import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State message: string = '校园智能考勤系统';

  build() {
    Column() {
      Text(this.message)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Text('v1.0.0')
        .fontSize(14)
        .fontColor(Color.Gray)

      Button('进入登录')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(48)
        .margin({ top: 40 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/Login' });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}