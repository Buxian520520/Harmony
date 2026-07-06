import router from '@ohos.router';
import { LeaveApi } from '../services/api/leaveApi';

interface LeaveApplyResponse {
  code: number;
  msg?: string;
}

@Entry
@Component
struct LeaveApply {
  @State startDate: string = '';
  @State endDate: string = '';
  @State leaveType: string = '事假';
  @State reason: string = '';
  @State isSubmitting: boolean = false;
  @State submitResult: string = '';
  @State submitSuccess: boolean = false;

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
          // Leave type selector
          Column() {
            Text('请假类型')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')

            Row() {
              Button('事假')
                .type(ButtonType.Capsule)
                .height(40)
                .fontSize(14)
                .fontColor(this.leaveType === '事假' ? Color.White : '#8E8E93')
                .backgroundColor(this.leaveType === '事假' ? '#007AFF' : '#F2F2F7')
                .onClick(() => { this.leaveType = '事假' })
              Button('病假')
                .type(ButtonType.Capsule)
                .height(40)
                .fontSize(14)
                .fontColor(this.leaveType === '病假' ? Color.White : '#8E8E93')
                .backgroundColor(this.leaveType === '病假' ? '#007AFF' : '#F2F2F7')
                .margin({ left: 8 })
                .onClick(() => { this.leaveType = '病假' })
              Button('其他')
                .type(ButtonType.Capsule)
                .height(40)
                .fontSize(14)
                .fontColor(this.leaveType === '其他' ? Color.White : '#8E8E93')
                .backgroundColor(this.leaveType === '其他' ? '#007AFF' : '#F2F2F7')
                .margin({ left: 8 })
                .onClick(() => { this.leaveType = '其他' })
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // Start date
          Column() {
            Text('开始日期')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')
            TextInput({ placeholder: 'YYYY-MM-DD', text: this.startDate })
              .width('100%')
              .height(48)
              .backgroundColor('#F2F2F7')
              .borderRadius(10)
              .padding({ left: 16 })
              .margin({ top: 6 })
              .onChange((v) => { this.startDate = v })
          }
          .width('100%')
          .margin({ bottom: 16 })

          // End date
          Column() {
            Text('结束日期')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('100%')
            TextInput({ placeholder: 'YYYY-MM-DD', text: this.endDate })
              .width('100%')
              .height(48)
              .backgroundColor('#F2F2F7')
              .borderRadius(10)
              .padding({ left: 16 })
              .margin({ top: 6 })
              .onChange((v) => { this.endDate = v })
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
              LoadingProgress().width(24).height(24).color(Color.White)
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
            this.submitResult = '';
            LeaveApi.applyLeave(this.startDate, this.endDate, this.leaveType, this.reason, this.token)
              .then((response) => {
                this.isSubmitting = false;
                const resp = response as LeaveApplyResponse;
                if (resp.code === 1) {
                  this.submitSuccess = true;
                  this.submitResult = resp.msg || '申请已提交，等待教师审批';
                } else {
                  this.submitSuccess = false;
                  this.submitResult = resp.msg || '提交失败';
                }
              })
              .catch(() => {
                this.isSubmitting = false;
                this.submitSuccess = false;
                this.submitResult = '提交失败，请检查网络连接';
              });
          })

          if (this.submitResult) {
            Text((this.submitSuccess ? '✅ ' : '❌ ') + this.submitResult)
              .fontSize(15)
              .fontColor(this.submitSuccess ? '#34C759' : '#FF3B30')
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
