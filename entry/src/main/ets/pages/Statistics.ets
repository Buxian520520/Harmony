import router from '@ohos.router';
import { CheckinApi } from '../services/api/checkinApi';
import { LeaveApi } from '../services/api/leaveApi';

interface CheckinRecord {
  id: number;
  taskTitle: string;
  type: string;
  signTime: string;
}

interface LeaveRecord {
  id: number;
  studentName: string;
  studentNo: string;
  leaveType: string;
  startDate: string;
  endDate: string;
  days: number;
  reason: string;
  status: string;
  applyTime: string;
  approvalComment: string;
  approvalTime: string;
}

interface CheckinRecordsResponse {
  code: number;
  msg?: string;
  data?: CheckinRecord[];
}

interface LeaveRecordsResponse {
  code: number;
  msg?: string;
  data?: LeaveRecord[];
}

@Entry
@Component
struct Statistics {
  @State records: CheckinRecord[] = [];
  @State leaves: LeaveRecord[] = [];
  @State isLoading: boolean = true;
  @State selectedTab: number = 0;
  @State totalCheckins: number = 0;
  @State qrCount: number = 0;
  @State locationCount: number = 0;

  private token: string = '';

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      // Load checkin records
      const checkinResp = await CheckinApi.getMyRecords(this.token) as CheckinRecordsResponse;
      if (checkinResp.code === 1) {
        const data = checkinResp.data || [];
        this.records = data;
        this.totalCheckins = this.records.length;
        this.qrCount = 0;
        this.locationCount = 0;
        for (const r of this.records) {
          if (r.type === 'qrcode') {
            this.qrCount++;
          } else {
            this.locationCount++;
          }
        }
      }

      // Load leave records
      const leaveResp = await LeaveApi.getMyLeaves(this.token) as LeaveRecordsResponse;
      if (leaveResp.code === 1) {
        this.leaves = leaveResp.data || [];
      }
    } catch (e) {
      // Use empty data on failure
    } finally {
      this.isLoading = false;
    }
  }

  getStatusText(status: string): string {
    if (status === 'pending') {
      return '待审批';
    } else if (status === 'approved') {
      return '已批准';
    } else {
      return '已拒绝';
    }
  }

  getStatusColor(status: string): string {
    if (status === 'pending') {
      return '#FF9500';
    } else if (status === 'approved') {
      return '#34C759';
    } else {
      return '#FF3B30';
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('我的记录')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      // Tab bar
      Row() {
        Text('签到记录')
          .fontSize(15)
          .fontColor(this.selectedTab === 0 ? '#007AFF' : '#8E8E93')
          .padding({ bottom: 8 })
          .border({ width: { bottom: this.selectedTab === 0 ? 2 : 0 }, color: '#007AFF' })
          .onClick(() => { this.selectedTab = 0 })
        Text('请假记录')
          .fontSize(15)
          .fontColor(this.selectedTab === 1 ? '#007AFF' : '#8E8E93')
          .margin({ left: 24 })
          .padding({ bottom: 8 })
          .border({ width: { bottom: this.selectedTab === 1 ? 2 : 0 }, color: '#007AFF' })
          .onClick(() => { this.selectedTab = 1 })
        Blank()
      }
      .width('100%')
      .padding({ left: 16 })

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 100 })
      } else if (this.selectedTab === 0) {
        // Checkin records tab
        Scroll() {
          Column() {
            // Summary cards
            Row() {
              StatCard({ icon: '📋', label: '总签到', value: this.totalCheckins.toString(), color: '#007AFF' })
              StatCard({ icon: '📱', label: '二维码', value: this.qrCount.toString(), color: '#34C759' })
              StatCard({ icon: '📍', label: '位置', value: this.locationCount.toString(), color: '#FF9500' })
            }
            .width('100%')
            .margin({ top: 12 })

            // Records list
            if (this.records.length === 0) {
              Text('暂无签到记录')
                .fontSize(16)
                .fontColor('#C7C7CC')
                .margin({ top: 60 })
            } else {
              Column() {
                Text('签到历史')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .margin({ top: 20, bottom: 12 })

                ForEach(this.records, (record: CheckinRecord) => {
                  Row() {
                    Column() {
                      Text(record.taskTitle)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                      Text(record.signTime)
                        .fontSize(13)
                        .fontColor('#8E8E93')
                        .margin({ top: 2 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Text(record.type === 'qrcode' ? '📱 二维码' : '📍 位置')
                      .fontSize(13)
                      .fontColor('#8E8E93')
                  }
                  .width('100%')
                  .height(56)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(Color.White)
                  .border({ width: { bottom: 1 }, color: '#F2F2F7' })
                }, (item: CheckinRecord) => item.id.toString())
              }
              .width('100%')
            }
          }
          .width('90%')
          .padding({ bottom: 30 })
        }
        .layoutWeight(1)
        .width('100%')
      } else {
        // Leave records tab
        Scroll() {
          Column() {
            if (this.leaves.length === 0) {
              Text('暂无请假记录')
                .fontSize(16)
                .fontColor('#C7C7CC')
                .margin({ top: 60 })
            } else {
              Column() {
                Text('请假历史')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .margin({ top: 12, bottom: 12 })

                ForEach(this.leaves, (leave: LeaveRecord) => {
                  Row() {
                    Column() {
                      Text(leave.leaveType + ' · ' + leave.startDate + ' ~ ' + leave.endDate)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                      Text('共 ' + leave.days + ' 天 · ' + leave.reason)
                        .fontSize(13)
                        .fontColor('#8E8E93')
                        .margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Text(this.getStatusText(leave.status))
                      .fontSize(12)
                      .fontColor(Color.White)
                      .backgroundColor(this.getStatusColor(leave.status))
                      .borderRadius(10)
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .backgroundColor(Color.White)
                  .border({ width: { bottom: 1 }, color: '#F2F2F7' })
                }, (item: LeaveRecord) => item.id.toString())
              }
              .width('100%')
            }
          }
          .width('90%')
          .padding({ bottom: 30 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

@Component
struct StatCard {
  @Prop icon: string = '';
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop color: string = '#007AFF';

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
