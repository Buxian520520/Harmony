import router from '@ohos.router';
import { CheckinApi } from '../services/api/checkinApi';
import { LeaveApi } from '../services/api/leaveApi';

// --- Data Interfaces ---

interface CheckinTask {
  id: number;
  title: string;
  type: string;
  code: string;
  range: number;
  lat?: number;
  lng?: number;
  createTime: string;
  signCount: number;
}

interface AttendanceRecord {
  sno: string;
  name: string;
  status: string;
  signTime: string;
  type: string;
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

interface TaskListResponse { code: number; msg?: string; data?: CheckinTask[] }
interface CreateTaskResponse { code: number; msg?: string }
interface AttendanceData {
  list?: AttendanceRecord[];
  total?: number;
  signedCount?: number;
  unsignedCount?: number;
}

interface AttendanceResponse { code: number; msg?: string; data?: AttendanceData }
interface LeaveListResponse { code: number; msg?: string; data?: LeaveRecord[] }
interface LeaveActionResponse { code: number; msg?: string }

// --- Helper ---

function getToken(): string {
  return AppStorage.get<string>('access_token') || '';
}

// ==================== TeacherMain Page ====================

@Entry
@Component
struct TeacherMain {
  @State currentTab: number = 0;
  // Tab 0: 发布签到
  @State tasks: CheckinTask[] = [];
  @State historyTasks: CheckinTask[] = [];
  @State tasksLoading: boolean = true;
  @State taskSubTab: number = 0; // 0=进行中, 1=已结束
  @State showCreateForm: boolean = false;
  @State newTaskTitle: string = '';
  @State newTaskType: string = 'qrcode';
  @State newTaskCode: string = '';
  @State newTaskRange: string = '100';
  @State createSubmitting: boolean = false;
  @State createResult: string = '';
  @State createSuccess: boolean = false;
  // Attendance detail
  @State showAttendance: boolean = false;
  @State attendanceTaskId: number = 0;
  @State attendanceTaskTitle: string = '';
  @State attendanceRecords: AttendanceRecord[] = [];
  @State attendanceLoading: boolean = false;
  @State attendanceTotal: number = 0;
  @State attendanceSigned: number = 0;
  @State attendanceUnsigned: number = 0;
  // Tab 1: 请假记录
  @State leaves: LeaveRecord[] = [];
  @State leavesLoading: boolean = true;
  @State approveComment: string = '';
  @State approvingId: number = 0;
  @State leaveActionResult: string = '';
  // Tab 2: 数据统计
  @State statsLoading: boolean = true;
  @State totalTasks: number = 0;
  @State totalSignIns: number = 0;
  @State qrTaskCount: number = 0;
  @State locationTaskCount: number = 0;
  @State pendingLeaveCount: number = 0;
  @State approvedLeaveCount: number = 0;
  @State rejectedLeaveCount: number = 0;

  aboutToAppear() {
    // Redirect students to the student interface
    const userRole = AppStorage.get<string>('user_role') || 'student';
    if (userRole !== 'teacher') {
      router.replaceUrl({ url: 'pages/Main' });
      return;
    }
    this.loadTasks();
    this.loadLeaves();
    this.loadStats();
  }

  onTabChange(index: number) {
    this.currentTab = index;
    if (index === 0) { this.loadTasks(); }
    if (index === 1) { this.loadLeaves(); }
    if (index === 2) { this.loadStats(); }
  }

  // ==================== Tab 0: 发布签到 ====================

  async loadTasks() {
    this.tasksLoading = true;
    const token = getToken();
    try {
      const resp = await CheckinApi.getTasks(token) as TaskListResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.tasks = resp.data || [];
      }
    } catch (_e) {
      // silently fail
    }
    try {
      const hResp = await CheckinApi.getHistory(token) as TaskListResponse;
      if (hResp.code === 1 || hResp.code === 200) {
        this.historyTasks = hResp.data || [];
      }
    } catch (_e) {
      // silently fail
    }
    this.tasksLoading = false;
  }

  async viewAttendance(task: CheckinTask) {
    this.attendanceTaskId = task.id;
    this.attendanceTaskTitle = task.title;
    this.attendanceRecords = [];
    this.attendanceTotal = 0;
    this.attendanceSigned = 0;
    this.attendanceUnsigned = 0;
    this.attendanceLoading = true;
    this.showAttendance = true;
    const token = getToken();
    try {
      const resp = await CheckinApi.getAttendance(task.id, token) as AttendanceResponse;
      if (resp.code === 1 || resp.code === 200) {
        const d = resp.data;
        if (d) {
          this.attendanceRecords = d.list || [];
          this.attendanceTotal = d.total || 0;
          this.attendanceSigned = d.signedCount || 0;
          this.attendanceUnsigned = d.unsignedCount || 0;
        }
      }
    } catch (_e) {
      // silently fail
    }
    this.attendanceLoading = false;
  }

  async doEndTask(taskId: number) {
    const token = getToken();
    try {
      const resp = await CheckinApi.endTask(taskId, token) as CreateTaskResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.loadTasks(); // refresh to move task to history
      }
    } catch (_e) {
      // silently fail
    }
  }

  async doAddRecord(sno: string, name: string) {
    const token = getToken();
    try {
      const resp = await CheckinApi.addRecord(this.attendanceTaskId, sno, name, token) as CreateTaskResponse;
      if (resp.code === 1 || resp.code === 200) {
        // Refresh attendance to show updated status
        const tasks = this.tasks;
        for (const t of tasks) {
          if (t.id === this.attendanceTaskId) {
            this.viewAttendance(t);
            break;
          }
        }
      }
    } catch (_e) {
      // silently fail
    }
  }

  async doCreateTask() {
    if (!this.newTaskTitle) {
      this.createResult = '请输入签到标题';
      this.createSuccess = false;
      return;
    }
    if (this.newTaskType === 'qrcode' && !this.newTaskCode) {
      this.createResult = '请输入签到码';
      this.createSuccess = false;
      return;
    }
    this.createSubmitting = true;
    this.createResult = '';
    const token = getToken();
    const rangeNum = parseInt(this.newTaskRange) || 100;
    try {
      const resp = await CheckinApi.createTask(
        this.newTaskTitle, this.newTaskType, this.newTaskCode, rangeNum, 0, 0, token
      ) as CreateTaskResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.createSuccess = true;
        this.createResult = resp.msg || '签到任务创建成功';
        this.newTaskTitle = '';
        this.newTaskCode = '';
        this.newTaskRange = '100';
        this.showCreateForm = false;
        this.loadTasks();
      } else {
        this.createSuccess = false;
        this.createResult = resp.msg || '创建失败';
      }
    } catch (_e) {
      this.createSuccess = false;
      this.createResult = '创建失败，请检查网络连接';
    } finally {
      this.createSubmitting = false;
    }
  }

  @Builder TabPublish() {
    Column() {
      // Header
      Row() {
        Text('发布签到')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button('+ 新建')
          .type(ButtonType.Capsule)
          .height(34)
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor('#FF9500')
          .onClick(() => { this.showCreateForm = !this.showCreateForm })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // Create form
      if (this.showCreateForm) {
        Column() {
          Text('新建签到任务')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 10 })

          TextInput({ placeholder: '签到标题 (如: 2024级计算机科学-第3周)', text: this.newTaskTitle })
            .width('100%').height(42).backgroundColor('#F2F2F7').borderRadius(8)
            .padding({ left: 14 }).margin({ bottom: 8 })
            .onChange((v: string) => { this.newTaskTitle = v })

          Row() {
            Button('📱 二维码').type(ButtonType.Capsule).height(34).fontSize(12)
              .fontColor(this.newTaskType === 'qrcode' ? Color.White : '#8E8E93')
              .backgroundColor(this.newTaskType === 'qrcode' ? '#007AFF' : '#F2F2F7')
              .onClick(() => { this.newTaskType = 'qrcode' })
            Button('📍 位置').type(ButtonType.Capsule).height(34).fontSize(12)
              .fontColor(this.newTaskType === 'location' ? Color.White : '#8E8E93')
              .backgroundColor(this.newTaskType === 'location' ? '#FF9500' : '#F2F2F7')
              .margin({ left: 6 })
              .onClick(() => { this.newTaskType = 'location' })
            Blank()
          }.width('100%').margin({ bottom: 8 })

          if (this.newTaskType === 'qrcode') {
            TextInput({ placeholder: '签到码 (如: 123456)', text: this.newTaskCode })
              .width('100%').height(42).backgroundColor('#F2F2F7').borderRadius(8)
              .padding({ left: 14 }).margin({ bottom: 8 })
              .onChange((v: string) => { this.newTaskCode = v })
          } else {
            TextInput({ placeholder: '有效范围 (米)', text: this.newTaskRange })
              .width('100%').height(42).backgroundColor('#F2F2F7').borderRadius(8)
              .padding({ left: 14 }).margin({ bottom: 8 })
              .type(InputType.Number)
              .onChange((v: string) => { this.newTaskRange = v })
          }

          Row() {
            Button('取消')
              .type(ButtonType.Capsule).height(36).fontSize(13)
              .fontColor('#8E8E93').backgroundColor('#F2F2F7')
              .layoutWeight(1)
              .onClick(() => { this.showCreateForm = false })
            Button() {
              if (this.createSubmitting) {
                LoadingProgress().width(20).height(20).color(Color.White)
              } else {
                Text('发布').fontSize(13).fontColor(Color.White)
              }
            }
            .type(ButtonType.Capsule).height(36)
            .backgroundColor('#FF9500').layoutWeight(1).margin({ left: 8 })
            .enabled(!this.createSubmitting)
            .onClick(() => { this.doCreateTask() })
          }.width('100%')

          if (this.createResult) {
            Text((this.createSuccess ? '✅ ' : '❌ ') + this.createResult)
              .fontSize(13)
              .fontColor(this.createSuccess ? '#34C759' : '#FF3B30')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .margin({ left: 16, right: 16, bottom: 6 })
      }

      // Sub tabs
      Row() {
        Text('进行中').fontSize(14)
          .fontColor(this.taskSubTab === 0 ? '#FF9500' : '#8E8E93')
          .padding({ bottom: 6 })
          .border({ width: { bottom: this.taskSubTab === 0 ? 2 : 0 }, color: '#FF9500' })
          .onClick(() => { this.taskSubTab = 0 })
        Text('已结束').fontSize(14)
          .fontColor(this.taskSubTab === 1 ? '#FF9500' : '#8E8E93')
          .margin({ left: 24 })
          .padding({ bottom: 6 })
          .border({ width: { bottom: this.taskSubTab === 1 ? 2 : 0 }, color: '#FF9500' })
          .onClick(() => { this.taskSubTab = 1 })
        Blank()
      }.width('100%').padding({ left: 20 })

      if (this.tasksLoading) {
        LoadingProgress().width(36).height(36).margin({ top: 60 })
      } else if (this.showAttendance) {
        // Attendance detail view
        Column() {
          Row() {
            Text('← 返回').fontSize(14).fontColor('#007AFF')
              .onClick(() => { this.showAttendance = false })
            Blank()
            Text(this.attendanceTaskTitle).fontSize(15).fontWeight(FontWeight.Medium)
            Blank()
            Text('').width(60)
          }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 4 })

          // Summary
          Row() {
            Text('总人数: ' + this.attendanceTotal).fontSize(12).fontColor('#8E8E93')
              .margin({ right: 12 })
            Text('已签: ' + this.attendanceSigned).fontSize(12).fontColor('#34C759')
              .margin({ right: 12 })
            Text('未签: ' + this.attendanceUnsigned).fontSize(12).fontColor('#FF3B30')
            Blank()
          }.width('90%').margin({ bottom: 4 })

          if (this.attendanceLoading) {
            LoadingProgress().width(30).height(30).margin({ top: 40 })
          } else if (!Array.isArray(this.attendanceRecords) || this.attendanceRecords.length === 0) {
            Text('暂无签到记录').fontSize(14).fontColor('#C7C7CC').margin({ top: 40 })
          } else {
            List() {
              ForEach(this.attendanceRecords, (r: AttendanceRecord) => {
                ListItem() {
                  Row() {
                    Column() {
                      Text(r.name || r.sno).fontSize(15).fontWeight(FontWeight.Medium)
                      Text('学号: ' + (r.sno || '—')).fontSize(12).fontColor('#8E8E93').margin({ top: 2 })
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    Column() {
                      Text((r.status && r.status === 'signed') ? '已签' : '未签')
                        .fontSize(11).fontColor(Color.White)
                        .backgroundColor((r.status && r.status === 'signed') ? '#34C759' : '#FF3B30')
                        .borderRadius(8).padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      if (r.signTime) {
                        Text(r.signTime).fontSize(11).fontColor('#8E8E93').margin({ top: 3 })
                      }
                      if (r.status !== 'signed') {
                        Text('补签')
                          .fontSize(10).fontColor('#FF9500')
                          .margin({ top: 3 })
                          .onClick(() => { this.doAddRecord(r.sno, r.name || r.sno) })
                      }
                    }.alignItems(HorizontalAlign.End)
                  }.width('90%').padding({ top: 10, bottom: 10 })
                  .border({ width: { bottom: 1 }, color: '#F2F2F7' })
                }
              }, (item: AttendanceRecord) => item.sno || '0')
            }.layoutWeight(1).width('100%')
          }
        }.layoutWeight(1).width('100%')
      } else if (this.taskSubTab === 0) {
        // Active tasks
        if (this.tasks.length === 0) {
          Scroll() {
            Column() {
              Text('暂无进行中的签到').fontSize(14).fontColor('#C7C7CC').margin({ top: 60 })
              Text('点击右上角"+ 新建"发布签到').fontSize(13).fontColor('#C7C7CC').margin({ top: 6 })
            }.width('100%').alignItems(HorizontalAlign.Center)
          }.layoutWeight(1).width('100%')
        } else {
          List() {
            ForEach(this.tasks, (task: CheckinTask) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(task.title).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
                    Text(task.type === 'qrcode' ? '📱' : '📍').fontSize(18)
                  }.width('100%')
                  Row() {
                    Text('签到码: ' + (task.code || '—')).fontSize(12).fontColor('#8E8E93')
                    Blank()
                    Text('👥 ' + task.signCount + '人').fontSize(12).fontColor('#8E8E93')
                    Blank()
                    Text('🕐 ' + task.createTime).fontSize(12).fontColor('#8E8E93')
                  }.width('100%').margin({ top: 6 })
                  Row() {
                    Button('查看签到详情')
                      .type(ButtonType.Capsule).height(32).fontSize(12)
                      .fontColor('#FF9500').backgroundColor('#FFF3E0')
                      .onClick(() => { this.viewAttendance(task) })
                    Button('结束签到')
                      .type(ButtonType.Capsule).height(32).fontSize(12)
                      .fontColor('#FF3B30').backgroundColor('#FFEBEB')
                      .margin({ left: 6 })
                      .onClick(() => { this.doEndTask(task.id) })
                  }.width('100%').margin({ top: 8 })
                }
                .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
                .margin({ bottom: 8 })
              }
            }, (item: CheckinTask) => item.id.toString())
          }
          .width('100%').padding({ left: 16, right: 16 }).layoutWeight(1)
        }
      } else {
        // History tasks
        if (this.historyTasks.length === 0) {
          Scroll() {
            Column() {
              Text('暂无已结束的签到').fontSize(14).fontColor('#C7C7CC').margin({ top: 60 })
            }.width('100%').alignItems(HorizontalAlign.Center)
          }.layoutWeight(1).width('100%')
        } else {
          List() {
            ForEach(this.historyTasks, (task: CheckinTask) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(task.title).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
                    Text(task.type === 'qrcode' ? '📱' : '📍').fontSize(18)
                  }.width('100%')
                  Row() {
                    Text('签到码: ' + (task.code || '—')).fontSize(12).fontColor('#8E8E93')
                    Blank()
                    Text('👥 ' + task.signCount + '人').fontSize(12).fontColor('#8E8E93')
                    Blank()
                    Text('🕐 ' + task.createTime).fontSize(12).fontColor('#8E8E93')
                  }.width('100%').margin({ top: 6 })
                  Row() {
                    Button('查看详情')
                      .type(ButtonType.Capsule).height(32).fontSize(12)
                      .fontColor('#8E8E93').backgroundColor('#F2F2F7')
                      .onClick(() => { this.viewAttendance(task) })
                  }.width('100%').margin({ top: 8 })
                }
                .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
                .margin({ bottom: 8 })
              }
            }, (item: CheckinTask) => item.id.toString())
          }
          .width('100%').padding({ left: 16, right: 16 }).layoutWeight(1)
        }
      }
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 1: 请假记录 ====================

  async loadLeaves() {
    this.leavesLoading = true;
    const token = getToken();
    try {
      const resp = await LeaveApi.getMyLeaves(token) as LeaveListResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.leaves = resp.data || [];
      }
    } catch (_e) {
      // silently fail
    }
    this.leavesLoading = false;
  }

  async doApprove(leaveId: number) {
    if (!this.approveComment) {
      this.leaveActionResult = '请输入审批意见';
      return;
    }
    const token = getToken();
    try {
      const resp = await LeaveApi.approveLeave(leaveId, this.approveComment, token) as LeaveActionResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.leaveActionResult = resp.msg || '已批准';
        this.approveComment = '';
        this.approvingId = 0;
        this.loadLeaves();
        this.loadStats();
      } else {
        this.leaveActionResult = resp.msg || '操作失败';
      }
    } catch (_e) {
      this.leaveActionResult = '操作失败，请检查网络';
    }
  }

  async doReject(leaveId: number) {
    if (!this.approveComment) {
      this.leaveActionResult = '请输入审批意见';
      return;
    }
    const token = getToken();
    try {
      const resp = await LeaveApi.rejectLeave(leaveId, this.approveComment, token) as LeaveActionResponse;
      if (resp.code === 1 || resp.code === 200) {
        this.leaveActionResult = resp.msg || '已拒绝';
        this.approveComment = '';
        this.approvingId = 0;
        this.loadLeaves();
        this.loadStats();
      } else {
        this.leaveActionResult = resp.msg || '操作失败';
      }
    } catch (_e) {
      this.leaveActionResult = '操作失败，请检查网络';
    }
  }

  getLeaveStatusText(s: string): string {
    if (s === 'pending') { return '待审批' }
    else if (s === 'approved') { return '已批准' }
    else { return '已拒绝' }
  }
  getLeaveStatusColor(s: string): string {
    if (s === 'pending') { return '#FF9500' }
    else if (s === 'approved') { return '#34C759' }
    else { return '#FF3B30' }
  }

  @Builder TabLeaveRecords() {
    Column() {
      Text('请假记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      if (this.leavesLoading) {
        LoadingProgress().width(36).height(36).margin({ top: 60 })
      } else if (this.leaves.length === 0) {
        Text('暂无请假记录').fontSize(14).fontColor('#C7C7CC').margin({ top: 60 })
      } else {
        List() {
          ForEach(this.leaves, (leave: LeaveRecord) => {
            ListItem() {
              Column() {
                Row() {
                  Text(leave.studentName).fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.getLeaveStatusText(leave.status))
                    .fontSize(11).fontColor(Color.White)
                    .backgroundColor(this.getLeaveStatusColor(leave.status))
                    .borderRadius(8).padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }.width('100%')

                Text('学号: ' + leave.studentNo).fontSize(12).fontColor('#8E8E93').margin({ top: 2 })

                Row() {
                  Text(leave.leaveType).fontSize(13)
                    .fontColor('#007AFF').backgroundColor('#E8F0FE')
                    .borderRadius(4).padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  Text(leave.startDate + ' ~ ' + leave.endDate).fontSize(13).fontColor('#8E8E93').margin({ left: 8 })
                  Text('共' + leave.days + '天').fontSize(12).fontColor('#8E8E93').margin({ left: 4 })
                }.width('100%').margin({ top: 6 })

                Text('原因: ' + leave.reason).fontSize(13).fontColor('#333').margin({ top: 4 })
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

                if (leave.approvalComment) {
                  Text('审批意见: ' + leave.approvalComment).fontSize(12).fontColor('#8E8E93').margin({ top: 2 })
                }

                if (leave.status === 'pending') {
                  if (this.approvingId === leave.id) {
                    Column() {
                      TextArea({ placeholder: '请输入审批意见...', text: this.approveComment })
                        .width('100%').height(60).backgroundColor('#F2F2F7').borderRadius(8)
                        .padding(8).margin({ top: 8 })
                        .onChange((v: string) => { this.approveComment = v })
                      Row() {
                        Button('取消')
                          .type(ButtonType.Capsule).height(30).fontSize(11)
                          .fontColor('#8E8E93').backgroundColor('#F2F2F7')
                          .onClick(() => { this.approvingId = 0; this.approveComment = '' })
                        Button('批准').type(ButtonType.Capsule).height(30).fontSize(11)
                          .fontColor(Color.White).backgroundColor('#34C759')
                          .margin({ left: 6 })
                          .onClick(() => { this.doApprove(leave.id) })
                        Button('拒绝').type(ButtonType.Capsule).height(30).fontSize(11)
                          .fontColor(Color.White).backgroundColor('#FF3B30')
                          .margin({ left: 6 })
                          .onClick(() => { this.doReject(leave.id) })
                      }.width('100%').margin({ top: 6 })
                    }.width('100%')
                  } else {
                    Row() {
                      Button('审批').type(ButtonType.Capsule).height(30).fontSize(12)
                        .fontColor(Color.White).backgroundColor('#FF9500')
                        .onClick(() => { this.approvingId = leave.id; this.approveComment = '' })
                    }.width('100%').margin({ top: 8 })
                  }
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .margin({ bottom: 8 })
            }
          }, (item: LeaveRecord) => item.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
      }

      if (this.leaveActionResult) {
        Text(this.leaveActionResult)
          .fontSize(13).fontColor('#FF9500')
          .padding(10)
          .onClick(() => { this.leaveActionResult = '' })
      }
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 2: 数据统计 ====================

  async loadStats() {
    this.statsLoading = true;
    const token = getToken();
    try {
      // Load active tasks
      const tResp = await CheckinApi.getTasks(token) as TaskListResponse;
      if (tResp.code === 1 || tResp.code === 200) {
        const activeTasks = tResp.data || [];
        this.totalTasks = activeTasks.length;
        this.qrTaskCount = 0;
        this.locationTaskCount = 0;
        this.totalSignIns = 0;
        for (const t of activeTasks) {
          if (t.type === 'qrcode') { this.qrTaskCount++ } else { this.locationTaskCount++ }
          this.totalSignIns += t.signCount || 0;
        }
      }
      // Load history tasks for additional counts
      const hResp = await CheckinApi.getHistory(token) as TaskListResponse;
      if (hResp.code === 1 || hResp.code === 200) {
        const histTasks = hResp.data || [];
        this.totalTasks += histTasks.length;
        for (const t of histTasks) {
          if (t.type === 'qrcode') { this.qrTaskCount++ } else { this.locationTaskCount++ }
          this.totalSignIns += t.signCount || 0;
        }
      }
      // Load leave stats
      const lResp = await LeaveApi.getMyLeaves(token) as LeaveListResponse;
      if (lResp.code === 1 || lResp.code === 200) {
        const allLeaves = lResp.data || [];
        this.pendingLeaveCount = 0;
        this.approvedLeaveCount = 0;
        this.rejectedLeaveCount = 0;
        for (const l of allLeaves) {
          if (l.status === 'pending') { this.pendingLeaveCount++ }
          else if (l.status === 'approved') { this.approvedLeaveCount++ }
          else { this.rejectedLeaveCount++ }
        }
      }
    } catch (_e) {
      // silently fail
    }
    this.statsLoading = false;
  }

  @Builder TabStats() {
    Column() {
      Text('数据统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      if (this.statsLoading) {
        LoadingProgress().width(36).height(36).margin({ top: 60 })
      } else {
        Scroll() {
          Column() {
            // Checkin stats
            Text('📋 签到统计')
              .fontSize(16).fontWeight(FontWeight.Medium).width('90%').margin({ top: 8, bottom: 8 })

            Row() {
              TeacherStatCard({ icon: '📋', label: '总任务数', v: this.totalTasks.toString(), c: '#007AFF' })
              TeacherStatCard({ icon: '✅', label: '总签到人次', v: this.totalSignIns.toString(), c: '#34C759' })
            }.width('90%')

            Row() {
              TeacherStatCard({ icon: '📱', label: '二维码任务', v: this.qrTaskCount.toString(), c: '#5856D6' })
              TeacherStatCard({ icon: '📍', label: '位置任务', v: this.locationTaskCount.toString(), c: '#FF9500' })
            }.width('90%')

            // Leave stats
            Text('📝 请假统计')
              .fontSize(16).fontWeight(FontWeight.Medium).width('90%').margin({ top: 16, bottom: 8 })

            Row() {
              TeacherStatCard({ icon: '⏳', label: '待审批', v: this.pendingLeaveCount.toString(), c: '#FF9500' })
              TeacherStatCard({ icon: '✅', label: '已批准', v: this.approvedLeaveCount.toString(), c: '#34C759' })
            }.width('90%')

            Row() {
              TeacherStatCard({ icon: '❌', label: '已拒绝', v: this.rejectedLeaveCount.toString(), c: '#FF3B30' })
              TeacherStatCard({ icon: '📊', label: '请假总数', v: (this.pendingLeaveCount + this.approvedLeaveCount + this.rejectedLeaveCount).toString(), c: '#007AFF' })
            }.width('90%')

            // Refresh
            Button('刷新数据')
              .type(ButtonType.Capsule).height(38).fontSize(13)
              .fontColor('#007AFF').backgroundColor('#E8F0FE')
              .margin({ top: 20 })
              .onClick(() => { this.loadStats(); this.loadTasks(); this.loadLeaves() })
          }
          .width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 30 })
        }
        .layoutWeight(1).width('100%')
      }
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 3: 我的 ====================

  @Builder TabProfile() {
    Column() {
      Column() {
        Circle().width(64).height(64).fill('#FF9500')
        Text(this.getTeacherName().charAt(0)).fontSize(28).fontColor(Color.White).position({ x: 18, y: 10 })
        Text(this.getTeacherName()).fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })
        Text('工号: ' + this.getTeacherNo()).fontSize(14).fontColor('#8E8E93').margin({ top: 4 })
      }
      .width('100%').padding(20).backgroundColor(Color.White).alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text('📋 发布签到').fontSize(15)
          Blank(); Text('>').fontColor('#C7C7CC')
        }.width('100%').height(48).padding({ left: 16, right: 16 })
        .backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#F2F2F7' })
        .onClick(() => { this.currentTab = 0 })

        Row() {
          Text('📝 请假记录').fontSize(15)
          Blank(); Text('>').fontColor('#C7C7CC')
        }.width('100%').height(48).padding({ left: 16, right: 16 })
        .backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#F2F2F7' })
        .onClick(() => { this.currentTab = 1 })

        Row() {
          Text('📊 数据统计').fontSize(15)
          Blank(); Text('>').fontColor('#C7C7CC')
        }.width('100%').height(48).padding({ left: 16, right: 16 })
        .backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#F2F2F7' })
        .onClick(() => { this.currentTab = 2 })

        Row() {
          Text('ℹ️ 关于').fontSize(15)
          Blank(); Text('>').fontColor('#C7C7CC')
        }.width('100%').height(48).padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)
      }.width('100%').margin({ top: 14 })

      Button('退出登录')
        .type(ButtonType.Capsule).width('90%').height(46)
        .fontColor('#FF3B30').backgroundColor(Color.White)
        .border({ width: 1, color: '#FF3B30' }).margin({ top: 28 })
        .onClick(() => {
          AppStorage.setOrCreate('access_token', '');
          router.clear();
          router.pushUrl({ url: 'pages/Login' });
        })
    }
    .width('100%').height('100%')
  }

  private getTeacherName(): string {
    return AppStorage.get<string>('username') || '教师';
  }
  private getTeacherNo(): string {
    return AppStorage.get<string>('username') || '';
  }

  // ==================== Build ====================

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() { this.TabPublish() }
      .tabBar(this.TabBarBuilder('📋', '发布签到', 0))

      TabContent() { this.TabLeaveRecords() }
      .tabBar(this.TabBarBuilder('📝', '请假记录', 1))

      TabContent() { this.TabStats() }
      .tabBar(this.TabBarBuilder('📊', '数据统计', 2))

      TabContent() { this.TabProfile() }
      .tabBar(this.TabBarBuilder('👤', '我的', 3))
    }
    .barHeight(56)
    .animationDuration(0)
    .onChange((index: number) => { this.onTabChange(index) })
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder TabBarBuilder(icon: string, title: string, idx: number) {
    Column() {
      Text(icon).fontSize(20)
      Text(title).fontSize(11).fontColor(this.currentTab === idx ? '#FF9500' : '#8E8E93')
        .margin({ top: 2 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct TeacherStatCard {
  @Prop icon: string;
  @Prop label: string;
  @Prop v: string;
  @Prop c: string;

  build() {
    Column() {
      Text(this.icon).fontSize(22)
      Text(this.v).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.c).margin({ top: 4 })
      Text(this.label).fontSize(11).fontColor('#8E8E93').margin({ top: 2 })
    }
    .layoutWeight(1).padding(10).backgroundColor(Color.White).borderRadius(8).alignItems(HorizontalAlign.Center).margin({ right: 6 })
  }
}
