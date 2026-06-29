import router from '@ohos.router';

interface LeaveItem {
  id: number;
  student_name: string;
  course_name: string;
  leave_date: string;
  start_time: string;
  end_time: string;
  reason: string;
  status: string;
  created_at: string;
}

@Entry
@Component
struct Approval {
  @State pendingList: LeaveItem[] = [];
  @State isLoading: boolean = true;
  @State selectedTab: number = 0;

  private token: string = '';

  aboutToAppear() {
    this.loadData();
  }

  loadData() {
    this.isLoading = true;
    // Mock data
    this.pendingList = [
      {
        id: 1, student_name: '张三', course_name: '高等数学',
        leave_date: '2024-06-20', start_time: '08:00', end_time: '09:40',
        reason: '身体不适，需要休息', status: 'pending',
        created_at: '2024-06-19 14:30'
      },
      {
        id: 2, student_name: '李四', course_name: '数据结构',
        leave_date: '2024-06-21', start_time: '14:00', end_time: '15:40',
        reason: '参加学术讲座', status: 'pending',
        created_at: '2024-06-19 10:15'
      }
    ];
    this.isLoading = false;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('审批管理')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
        Text('待批(' + this.pendingList.length + ')')
          .fontSize(14)
          .fontColor('#FF9500')
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 100 })
      } else if (this.pendingList.length === 0) {
        Column() {
          Text('🎉').fontSize(48)
          Text('暂无待审批申请').fontSize(16).fontColor('#C7C7CC').margin({ top: 12 })
        }
        .margin({ top: 100 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.pendingList, (item: LeaveItem) => {
            ListItem() {
              Column() {
                // Header
                Row() {
                  Circle().width(36).height(36).fill('#007AFF')
                  Text(item.student_name.charAt(0))
                    .fontSize(16).fontColor(Color.White)
                    .position({ x: 11, y: 5 })
                  Text(item.student_name)
                    .fontSize(17).fontWeight(FontWeight.Medium)
                    .margin({ left: 10 })
                  Blank()
                  Text('待审批')
                    .fontSize(12).fontColor(Color.White)
                    .backgroundColor('#FF9500')
                    .borderRadius(10)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                .width('100%')

                // Details
                Column() {
                  Text(item.course_name + ' | ' + item.leave_date)
                    .fontSize(15).fontColor('#3A3A3C').margin({ top: 8 })
                  Text(item.start_time + ' - ' + item.end_time)
                    .fontSize(14).fontColor('#8E8E93').margin({ top: 4 })
                  Text('原因：' + item.reason)
                    .fontSize(14).fontColor('#8E8E93').margin({ top: 8 })
                    .lineHeight(20)
                }
                .width('100%')
                .padding({ left: 46 })

                // Action buttons
                Row() {
                  Button('驳回')
                    .type(ButtonType.Capsule)
                    .height(36)
                    .fontSize(14)
                    .fontColor('#FF3B30')
                    .backgroundColor(Color.White)
                    .border({ width: 1, color: '#FF3B30' })
                    .onClick(() => {
                      // TODO: Call review API with action='reject'
                    })

                  Blank()

                  Button('通过')
                    .type(ButtonType.Capsule)
                    .height(36)
                    .fontSize(14)
                    .fontColor(Color.White)
                    .backgroundColor('#34C759')
                    .onClick(() => {
                      // TODO: Call review API with action='approve'
                    })
                }
                .width('100%')
                .margin({ top: 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ bottom: 10 })
              .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
            }
          }, (item: LeaveItem) => item.id.toString())
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
