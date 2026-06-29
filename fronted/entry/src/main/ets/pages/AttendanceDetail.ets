import router from '@ohos.router';

interface Record {
  id: number;
  date: string;
  status: string;
  status_display: string;
  checkin_time: string;
  is_abnormal: boolean;
}

@Entry
@Component
struct AttendanceDetail {
  @State courseName: string = '';
  @State records: Record[] = [];
  @State isLoading: boolean = true;

  private courseId: number = 0;
  private token: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.courseId = params['courseId'] as number || 0;
    this.courseName = params['courseName'] as string || '课程详情';
    this.loadRecords();
  }

  loadRecords() {
    this.isLoading = true;
    // Mock data
    this.records = [
      { id: 1, date: '2024-06-17', status: 'present', status_display: '已签到', checkin_time: '07:55', is_abnormal: false },
      { id: 2, date: '2024-06-14', status: 'late', status_display: '迟到', checkin_time: '08:12', is_abnormal: false },
      { id: 3, date: '2024-06-12', status: 'present', status_display: '已签到', checkin_time: '07:50', is_abnormal: false },
      { id: 4, date: '2024-06-10', status: 'absent', status_display: '缺勤', checkin_time: '', is_abnormal: true },
      { id: 5, date: '2024-06-07', status: 'leave', status_display: '请假', checkin_time: '', is_abnormal: false },
    ];
    this.isLoading = false;
  }

  getStatusColor(status: string): string {
    const map: Record<string, string> = {
      'present': '#34C759',
      'late': '#FF9500',
      'absent': '#FF3B30',
      'leave': '#007AFF',
      'early_leave': '#FF9500',
    };
    return map[status] || '#C7C7CC';
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text(this.courseName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 100 })
      } else {
        List() {
          ForEach(this.records, (record: Record) => {
            ListItem() {
              Row() {
                // Date column
                Column() {
                  Text(record.date.substring(8))
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                  Text(record.date.substring(0, 7))
                    .fontSize(12)
                    .fontColor('#8E8E93')
                }
                .width(50)
                .alignItems(HorizontalAlign.Center)

                // Status indicator
                Circle()
                  .width(12)
                  .height(12)
                  .fill(this.getStatusColor(record.status))
                  .margin({ left: 12, right: 12 })

                // Detail column
                Column() {
                  Text(record.status_display)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.getStatusColor(record.status))

                  if (record.checkin_time) {
                    Text('签到时间: ' + record.checkin_time)
                      .fontSize(13)
                      .fontColor('#8E8E93')
                      .margin({ top: 2 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // Abnormal flag
                if (record.is_abnormal) {
                  Text('异常')
                    .fontSize(11)
                    .fontColor(Color.White)
                    .backgroundColor('#FF3B30')
                    .borderRadius(8)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .margin({ bottom: 8 })
              .shadow({ radius: 2, color: '#08000000', offsetY: 1 })
            }
          }, (item: Record) => item.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
