/**
 * AttendanceCardPage — 学生端考勤服务卡片 UI
 * 显示：今日签到状态 + 待审批请假申请
 *
 * 卡片规格：
 *   - 2×2: 完整信息卡片
 *   - 1×2: 精简信息卡片
 *   通过 $dimension 区分
 */

interface CardData {
  todayCourse: string;
  checkinStatus: string;
  statusColor: string;
  pendingLeaveCount: number;
  hasPendingLeaves: number; // 0 or 1, used as boolean
  lastUpdate: string;
}

// Default values used when data hasn't arrived yet
const DEFAULT: CardData = {
  todayCourse: '正在加载...',
  checkinStatus: '--',
  statusColor: '#8E8E93',
  pendingLeaveCount: 0,
  hasPendingLeaves: 0,
  lastUpdate: ''
};

@Entry
@Component
struct AttendanceCardPage {
  // Read form binding data via LocalStorage
  @LocalStorageProp('todayCourse') todayCourse: string = DEFAULT.todayCourse;
  @LocalStorageProp('checkinStatus') checkinStatus: string = DEFAULT.checkinStatus;
  @LocalStorageProp('statusColor') statusColor: string = DEFAULT.statusColor;
  @LocalStorageProp('pendingLeaveCount') pendingLeaveCount: number = DEFAULT.pendingLeaveCount;
  @LocalStorageProp('hasPendingLeaves') hasPendingLeaves: number = DEFAULT.hasPendingLeaves;
  @LocalStorageProp('lastUpdate') lastUpdate: string = DEFAULT.lastUpdate;

  build() {
    Column() {
      // ---- Header: 今日课程 & 签到状态 ----
      Row() {
        Column() {
          Text('📚 考勤状态')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Text(this.todayCourse)
            .fontSize(14)
            .fontColor('#007AFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // Status badge
        Text(this.checkinStatus)
          .fontSize(11)
          .fontColor(Color.White)
          .backgroundColor(this.statusColor)
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      .width('100%')

      // ---- Divider ----
      Divider()
        .strokeWidth(0.5)
        .color('#E5E5E5')
        .margin({ top: 10, bottom: 10 })

      // ---- Pending leaves section ----
      Row() {
        Text('📋 待审批请假')
          .fontSize(12)
          .fontColor('#8E8E93')

        if (this.hasPendingLeaves === 1) {
          Text(this.pendingLeaveCount.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9500')
            .margin({ left: 6 })

          Text('项')
            .fontSize(11)
            .fontColor('#FF9500')
            .margin({ left: 2 })
        } else {
          Text('无')
            .fontSize(12)
            .fontColor('#C7C7CC')
            .margin({ left: 6 })
        }

        Blank()

        // Action hint
        Text('查看 ›')
          .fontSize(11)
          .fontColor('#007AFF')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetPage: 'pages/Main' }
            });
          })
      }
      .width('100%')

      // ---- Last update timestamp ----
      if (this.lastUpdate) {
        Text('更新于 ' + this.lastUpdate)
          .fontSize(9)
          .fontColor('#C7C7CC')
          .width('100%')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
  }
}
