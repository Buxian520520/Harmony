import router from '@ohos.router';
import { AttendanceApi } from '../services/api/attendanceApi';

@Entry
@Component
struct LeaveApply {
  @State selectedCourse: string = '请选择课程';
  @State selectedCourseId: number = 0;
  @State leaveDate: string = '';
  @State startTime: string = '';
  @State endTime: string = '';
  @State reason: string = '';
  @State isSubmitting: boolean = false;
  @State submitResult: string = '';

  private token: string = '';

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('请假申请')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          // Course selector
          Column() {
            Text('选择课程')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')
            Text(this.selectedCourse)
              .fontSize(17)
              .width('100%')
              .height(48)
              .backgroundColor('#F2F2F7')
              .borderRadius(10)
              .padding({ left: 16 })
              .margin({ top: 6 })
              .onClick(() => {
                // TODO: Show course picker dialog
              })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // Date
          Column() {
            Text('请假日期')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')
            TextInput({ placeholder: 'YYYY-MM-DD', text: this.leaveDate })
              .width('100%')
              .height(48)
              .backgroundColor('#F2F2F7')
              .borderRadius(10)
              .padding({ left: 16 })
              .margin({ top: 6 })
              .onChange((v) => { this.leaveDate = v })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // Time range
          Row() {
            Column() {
              Text('开始时间').fontSize(15).fontColor('#8E8E93').width('100%')
              TextInput({ placeholder: 'HH:MM', text: this.startTime })
                .width('100%').height(48).backgroundColor('#F2F2F7')
                .borderRadius(10).padding({ left: 16 }).margin({ top: 6 })
                .onChange((v) => { this.startTime = v })
            }
            .layoutWeight(1)

            Text(' 至 ').margin({ top: 30 }).fontColor('#8E8E93')

            Column() {
              Text('结束时间').fontSize(15).fontColor('#8E8E93').width('100%')
              TextInput({ placeholder: 'HH:MM', text: this.endTime })
                .width('100%').height(48).backgroundColor('#F2F2F7')
                .borderRadius(10).padding({ left: 16 }).margin({ top: 6 })
                .onChange((v) => { this.endTime = v })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // Reason
          Column() {
            Text('请假原因')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')
            TextArea({ placeholder: '请详细描述请假原因...', text: this.reason })
              .width('100%')
              .height(120)
              .backgroundColor('#F2F2F7')
              .borderRadius(10)
              .padding(16)
              .margin({ top: 6 })
              .onChange((v) => { this.reason = v })
          }
          .width('100%')
          .margin({ bottom: 24 })

          // Submit button
          Button() {
            if (this.isSubmitting) {
              LoadingProgress().width(24).height(24).fontColor(Color.White)
            } else {
              Text('提交申请').fontSize(18).fontColor(Color.White)
            }
          }
          .type(ButtonType.Capsule)
          .width('100%')
          .height(50)
          .backgroundColor('#007AFF')
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.isSubmitting = true;
            // TODO: Call API
            // AttendanceApi.submitLeave({...}, this.token)
            setTimeout(() => {
              this.isSubmitting = false;
              this.submitResult = '申请已提交，等待教师审批';
            }, 1500);
          })

          if (this.submitResult) {
            Text('✅ ' + this.submitResult)
              .fontSize(15)
              .fontColor('#34C759')
              .margin({ top: 16 })
          }
        }
        .width('90%')
        .padding({ top: 20 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}
