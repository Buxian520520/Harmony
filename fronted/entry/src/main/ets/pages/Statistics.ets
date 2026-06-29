import router from '@ohos.router';

@Entry
@Component
struct Statistics {
  @State attendanceRate: number = 87.5;
  @State totalCourses: number = 3;
  @State presentCount: number = 28;
  @State lateCount: number = 5;
  @State absentCount: number = 3;
  @State leaveCount: number = 4;

  private token: string = '';

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('考勤统计')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          // Attendance rate circle (simulated gauge)
          Column() {
            Text(this.attendanceRate + '%')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')
            Text('总出勤率')
              .fontSize(16)
              .fontColor('#8E8E93')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(30)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)

          // Stats cards row
          Row() {
            StatCard('✅', '已签到', this.presentCount.toString(), '#34C759')
            StatCard('⏰', '迟到', this.lateCount.toString(), '#FF9500')
            StatCard('❌', '缺勤', this.absentCount.toString(), '#FF3B30')
            StatCard('📝', '请假', this.leaveCount.toString(), '#007AFF')
          }
          .width('100%')
          .margin({ top: 12 })

          // Course list
          Text('各课程出勤率')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 20, bottom: 12 })

          // Course stats
          Column() {
            CourseStatRow('高等数学', '92.3%', '#34C759')
            CourseStatRow('大学英语', '85.7%', '#FF9500')
            CourseStatRow('数据结构', '78.6%', '#FF3B30')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)

          // Weekly trend placeholder
          Text('本周趋势')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 20, bottom: 12 })

          Column() {
            Text('📊 考勤趋势图表（待集成图表组件）')
              .fontSize(14)
              .fontColor('#C7C7CC')
              .padding(30)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)
        }
        .width('90%')
        .padding({ bottom: 30 })
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

@Component
struct StatCard {
  private icon: string = '';
  private label: string = '';
  private value: string = '';
  private color: string = '#007AFF';

  build() {
    Column() {
      Text(this.icon).fontSize(24)
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
        .margin({ top: 4 })
      Text(this.label)
        .fontSize(12)
        .fontColor('#8E8E93')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 6 })
  }
}

@Component
struct CourseStatRow {
  private name: string = '';
  private rate: string = '';
  private color: string = '#34C759';

  build() {
    Row() {
      Text(this.name).fontSize(15).layoutWeight(1)
      Text(this.rate)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.color)
      // Simple progress bar
      Circle()
        .width(8).height(8)
        .fill(this.color)
        .margin({ left: 8 })
    }
    .width('100%')
    .height(44)
    .border({ width: { bottom: 1 }, color: '#F2F2F7' })
  }
}
