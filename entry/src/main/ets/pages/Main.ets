import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { formBindingData, formProvider } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { CheckinApi } from '../services/api/checkinApi';
import { LeaveApi } from '../services/api/leaveApi';
import { NotificationService } from '../services/NotificationService';
import { Nav } from '../utils/NavigationUtil';
import { CheckinComponent } from './Checkin';
import { LeaveApplyComponent } from './LeaveApply';
import { ProfileComponent } from './Profile';
import { StatisticsComponent } from './Statistics';
import { ApprovalComponent } from './Approval';
import { AttendanceDetailComponent } from './AttendanceDetail';
import { HomeComponent } from './Home';

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

interface CheckinRecord {
  id: number;
  task?: number;       // Django FK field name (may be number or nested object)
  taskId?: number;     // camelCase alias
  task_id?: number;    // snake_case DB column name
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

interface TaskListResponse { code: number; msg?: string; data?: CheckinTask[] }
interface SignInResponse { code: number; msg?: string }
interface CheckinRecordsResponse { code: number; msg?: string; data?: CheckinRecord[] }
interface LeaveRecordsResponse { code: number; msg?: string; data?: LeaveRecord[] }
interface LeaveApplyResponse { code: number; msg?: string }

interface AttRecord {
  sno: string;
  name: string;
  status: string;
  signTime: string;
  type: string;
}

interface AttendanceData {
  list?: AttRecord[];
  total?: number;
  signedCount?: number;
  unsignedCount?: number;
}

interface AttendanceResponse { code: number; msg?: string; data?: AttendanceData }

// --- Helper to get token from AppStorage ---
function getToken(): string {
  return AppStorage.get<string>('access_token') || '';
}

interface SignInParams {
  taskId: number;
  taskTitle: string;
  type: string;
  code: string;
  range: number;
  teacherLat?: number;
  teacherLng?: number;
}

// ==================== Main Page ====================

@Entry
@Component
struct Main {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @State currentTab: number = 0;
  // Tab 0: 签到 task list
  @State tasks: CheckinTask[] = [];
  @State tasksLoading: boolean = true;
  @State tasksError: string = '';
  @State signedTaskIds: number[] = [];
  // Tab 1: 请假
  @State leaveStartDate: string = '';
  @State leaveEndDate: string = '';
  @State leaveType: string = '事假';
  @State leaveReason: string = '';
  @State leaveSubmitting: boolean = false;
  @State leaveResult: string = '';
  @State leaveSuccess: boolean = false;
  @State showStartPicker: boolean = false;
  @State showEndPicker: boolean = false;
  private startPickerDate: Date = new Date();
  private endPickerDate: Date = new Date();
  // Tab 2: 统计
  @State records: CheckinRecord[] = [];
  @State leaves: LeaveRecord[] = [];
  @State statsLoading: boolean = true;
  @State totalCheckins: number = 0;
  @State qrCount: number = 0;
  @State locationCount: number = 0;
  @State statSubTab: number = 0;
  @State selectedRecordId: number = -1;
  @State leaveFilter: string = 'all'; // 'all' | 'pending' | 'approved' | 'rejected'
  // Tab 3: 我的
  @State userName: string = '学生';
  @State studentNo: string = '';
  // Notification tracking
  private knownTaskIds: Set<number> = new Set();
  private leaveStatusMap: Map<number, string> = new Map();
  private warnedTaskIds: Set<number> = new Set(); // track abnormal warnings per session
  private notifPermRequested: boolean = false;
  // Polling observer — EntryAbility bumps this every 10s
  @StorageLink('pollTick') @Watch('onPollTickChange') pollTick: number = 0;
  // React to newly-signed taskId from Checkin page (bypasses onPageShow reliance)
  @StorageLink('signed_task_id') @Watch('onPendingSignInChange') pendingSignId: number = 0;

  aboutToAppear() {
    Nav.stack = this.navPathStack;
    // Redirect teachers to the teacher interface
    const userRole = AppStorage.get<string>('user_role') || 'student';
    if (userRole === 'teacher') {
      router.replaceUrl({ url: 'pages/TeacherMain' });
      return;
    }
    this.requestNotifPermission();
    this.applyPendingSignIn();
    // Load user display name
    const savedName = AppStorage.get<string>('username') || '';
    if (savedName) {
      this.userName = savedName;
      this.studentNo = savedName;
    }
    this.loadTasks();
    this.loadStats();
  }

  /**
   * Called automatically when pollTick changes (every 10s from EntryAbility)
   */
  onPollTickChange(): void {
    if (this.pollTick > 0) {
      this.loadTasks(true);
      this.loadStats(true);
    }
  }

  /**
   * Called when Checkin page sets signed_task_id after a successful sign-in.
   * This bypasses the Navigation onPageShow reliability issue.
   */
  onPendingSignInChange(): void {
    if (this.pendingSignId > 0) {
      this.applyPendingSignIn();
      this.loadTasks(true);
    }
  }

  async requestNotifPermission() {
    if (this.notifPermRequested) { return; }
    this.notifPermRequested = true;
    await NotificationService.requestPermission();
  }

  onPageShow() {
    // Refresh from backend to pick up teacher补签 or other external changes
    this.loadTasks();
    this.loadStats();
  }

  onPageHide() {
  }

  onTabChange(index: number) {
    this.currentTab = index;
    if (index === 0) { this.loadTasks(); }
    if (index === 2) { this.loadStats(); }
  }

  /**
   * Check AppStorage for a newly-signed taskId from Checkin page
   * and update signedTaskIds accordingly.
   */
  applyPendingSignIn() {
    const signedId = AppStorage.get<number>('signed_task_id');
    if (signedId && signedId > 0) {
      if (this.signedTaskIds.indexOf(signedId) === -1) {
        this.signedTaskIds.push(signedId);
      }
      AppStorage.setOrCreate('signed_task_id', 0);
    }
  }

  /**
   * Push current attendance status + pending leave count to all widget card instances.
   * Called after loadTasks() and loadStats() finish.
   */
  async updateWidgetCard() {
    try {
      // ── Determine today's course and check-in status ──
      let todayCourse = '暂无课程';
      let checkinStatus = '无任务';
      let statusColor = '#8E8E93';

      if (this.tasks.length > 0) {
        const firstTask = this.tasks[0];
        todayCourse = firstTask.title;
        if (this.isTaskSigned(firstTask.id)) {
          checkinStatus = '已签到';
          statusColor = '#34C759';
        } else {
          checkinStatus = '未签到';
          statusColor = '#FF9500';
        }
      }

      // ── Count pending leaves ──
      let pendingCount = 0;
      for (const l of this.leaves) {
        if (l.status === 'pending') {
          pendingCount++;
        }
      }

      // ── Current time ──
      const now = new Date();
      const lastUpdate =
        `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

      const cardData: Record<string, string | number> = {
        'todayCourse': todayCourse,
        'checkinStatus': checkinStatus,
        'statusColor': statusColor,
        'pendingLeaveCount': pendingCount,
        'hasPendingLeaves': pendingCount > 0 ? 1 : 0,
        'lastUpdate': lastUpdate
      };

      const bindingData = formBindingData.createFormBindingData(cardData);

      // Try reading saved formId from preferences first (set by onAddForm)
      const context = getContext(this) as common.UIAbilityContext;
      let updated = false;
      try {
        const prefs = await preferences.getPreferences(context, 'attendance_card_store');
        const savedFormId = await prefs.get('formId', '') as string;
        if (savedFormId) {
          await formProvider.updateForm(savedFormId, bindingData);
          updated = true;
        }
      } catch (_e) {
        // preferences read failed, fall through to getFormsInfo
      }

      // Fallback: query all form instances and update matching ones
      if (!updated) {
        const formIds = await formProvider.getFormsInfo();
        if (formIds && formIds.length > 0) {
          for (const info of formIds) {
            if (info['formName'] === 'AttendanceCard') {
              await formProvider.updateForm(info['formId'], bindingData);
            }
          }
        }
      }
    } catch (_e) {
      // Silently handle — widget may not be added yet
    }
  }

  // ==================== Tab 0: 签到任务 ====================

  async loadTasks(silent: boolean = false) {
    this.applyPendingSignIn();
    if (!silent) {
      this.tasksLoading = true;
    }
    this.tasksError = '';
    try {
      const token = getToken();
      const response = await CheckinApi.getTasks(token) as TaskListResponse;
      if (response.code === 1) {
        this.tasks = response.data || [];
      } else {
        this.tasksError = response.msg || '获取任务失败';
      }

      // Rebuild signedTaskIds: fetch student's own checkin records (1 API call instead of N)
      try {
        const myRecordsResp = await CheckinApi.getMyRecords(token) as CheckinRecordsResponse;
        const signedIds: number[] = [];
        if (myRecordsResp.code === 1 && myRecordsResp.data) {
          for (const r of myRecordsResp.data) {
            // Match record to task by title (taskTitle is reliably present — used in Statistics tab)
            for (const task of this.tasks) {
              if (r.taskTitle === task.title && signedIds.indexOf(task.id) === -1) {
                signedIds.push(task.id);
                break;
              }
            }
          }
        }
        // Merge with locally-tracked IDs (from applyPendingSignIn)
        for (const id of this.signedTaskIds) {
          if (signedIds.indexOf(id) === -1) {
            signedIds.push(id);
          }
        }
        this.signedTaskIds = signedIds;

          // ── Notification: new tasks & abnormal warnings ──
          for (const task of this.tasks) {
            const taskId = task.id;
            // Attendance start reminder for new tasks
            if (!this.knownTaskIds.has(taskId)) {
              await NotificationService.showAttendanceReminder(task.title, taskId);
            }
            // Abnormal warning for unsigned tasks (once per task per session)
            if (signedIds.indexOf(taskId) === -1 && !this.warnedTaskIds.has(taskId)) {
              await NotificationService.showAbnormalWarning(task.title, taskId);
              this.warnedTaskIds.add(taskId);
            }
            this.knownTaskIds.add(taskId);
          }
      } catch (_e2) {
        // silently skip
      }
    } catch (_e) {
      if (!silent) {
        this.tasksError = '获取任务失败，请检查网络连接';
      }
    } finally {
      if (!silent) {
        this.tasksLoading = false;
      }
      this.updateWidgetCard();
    }
  }

  isTaskSigned(taskId: number): boolean {
    return this.signedTaskIds.indexOf(taskId) !== -1;
  }

  handleSignIn(task: CheckinTask) {
    const params: SignInParams = {
      taskId: task.id,
      taskTitle: task.title,
      type: task.type,
      code: task.code || '',
      range: task.range || 100,
      teacherLat: task.lat || 0,
      teacherLng: task.lng || 0
    };
    AppStorage.setOrCreate('checkin_params', params);
    Nav.stack.pushPathByName('Checkin', undefined);
  }

  async quickSignIn(task: CheckinTask) {
    const token = getToken();
    try {
      let response: SignInResponse;
      if (task.type === 'qrcode') {
        response = await CheckinApi.signInByQr(task.id, task.code, token) as SignInResponse;
      } else {
        response = await CheckinApi.signInByLocation(task.id, 0, 0, '', token) as SignInResponse;
      }
      if (response.code === 1) {
        this.signedTaskIds.push(task.id);
      }
    } catch (_e) {
      // silently fail, user can click card to go to detail
    }
  }

  @Builder TabCheckin() {
    Column() {
      Text('签到任务')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      if (this.tasksLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else if (this.tasksError) {
        Column() {
          Text(this.tasksError).fontSize(14).fontColor('#C7C7CC')
          Text('下拉刷新重试').fontSize(13).fontColor('#C7C7CC').margin({ top: 6 })
        }.margin({ top: 80 }).width('100%').alignItems(HorizontalAlign.Center)
      } else if (this.tasks.length === 0) {
        Column() {
          Text('暂无进行中的签到').fontSize(15).fontColor('#C7C7CC')
          Text('等待教师发起签到').fontSize(13).fontColor('#C7C7CC').margin({ top: 6 })
        }.margin({ top: 80 }).width('100%').alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.tasks, (task: CheckinTask) => {
            ListItem() {
              Column() {
                Row() {
                  Text(task.title).fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1)
                  Text(this.isTaskSigned(task.id) ? '已签' : '待签')
                    .fontSize(12)
                    .fontColor(this.isTaskSigned(task.id) ? '#34C759' : '#FF9500')
                    .backgroundColor(this.isTaskSigned(task.id) ? '#E8F8EE' : '#FFF3E0')
                    .borderRadius(10)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                }.width('100%')

                Row() {
                  Text(task.type === 'qrcode' ? '📱 二维码' : '📍 位置').fontSize(13).fontColor('#8E8E93')
                  Blank()
                  Text('🕐 ' + task.createTime).fontSize(13).fontColor('#8E8E93')
                  Blank()
                  Text('👥 ' + task.signCount + '人').fontSize(13).fontColor('#8E8E93')
                }.width('100%').margin({ top: 8 })

                if (!this.isTaskSigned(task.id)) {
                  Button(task.type === 'qrcode' ? '扫码签到' : '定位签到')
                    .type(ButtonType.Capsule)
                    .width('100%')
                    .height(38)
                    .fontSize(14)
                    .backgroundColor('#007AFF')
                    .fontColor(Color.White)
                    .margin({ top: 10 })
                    .onClick(() => { this.handleSignIn(task) })
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .margin({ bottom: 8 })
            }
          }, (item: CheckinTask) => item.id.toString())
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== Tab 1: 请假 ====================

  async doLeaveSubmit() {
    if (!this.leaveStartDate || !this.leaveEndDate || !this.leaveReason) {
      this.leaveResult = '请填写日期和原因';
      this.leaveSuccess = false;
      return;
    }
    this.leaveSubmitting = true;
    this.leaveResult = '';
    try {
      const token = getToken();
      const response = await LeaveApi.applyLeave(
        this.leaveStartDate, this.leaveEndDate, this.leaveType, this.leaveReason, token
      ) as LeaveApplyResponse;
      if (response.code === 1) {
        this.leaveSuccess = true;
        this.leaveResult = response.msg || '提交成功';
      } else {
        this.leaveSuccess = false;
        this.leaveResult = response.msg || '提交失败';
      }
    } catch (_e) {
      this.leaveSuccess = false;
      this.leaveResult = '网络错误';
    } finally {
      this.leaveSubmitting = false;
    }
  }

  @Builder TabLeave() {
    Column() {
      Text('请假申请')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      Scroll() {
        Column() {
          // Type
          Text('请假类型').fontSize(14).fontColor('#8E8E93').width('90%')
          Row() {
            Button('事假').type(ButtonType.Capsule).height(36).fontSize(13)
              .fontColor(this.leaveType === '事假' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveType === '事假' ? '#007AFF' : '#F2F2F7')
              .onClick(() => { this.leaveType = '事假' })
            Button('病假').type(ButtonType.Capsule).height(36).fontSize(13)
              .fontColor(this.leaveType === '病假' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveType === '病假' ? '#007AFF' : '#F2F2F7')
              .margin({ left: 6 })
              .onClick(() => { this.leaveType = '病假' })
            Button('其他').type(ButtonType.Capsule).height(36).fontSize(13)
              .fontColor(this.leaveType === '其他' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveType === '其他' ? '#007AFF' : '#F2F2F7')
              .margin({ left: 6 })
              .onClick(() => { this.leaveType = '其他' })
          }.width('90%').margin({ top: 4 })

          // Start date
          Text('开始日期').fontSize(14).fontColor('#8E8E93').width('90%').margin({ top: 12 })
          Row() {
            Text(this.leaveStartDate || '点击选择日期')
              .fontSize(14)
              .fontColor(this.leaveStartDate ? '#333' : '#C7C7CC')
              .layoutWeight(1)
            Text(this.showStartPicker ? '▲' : '▼').fontSize(12).fontColor('#8E8E93')
          }
          .width('90%').height(44).backgroundColor('#F2F2F7').borderRadius(8)
          .padding({ left: 14, right: 14 }).margin({ top: 4 })
          .onClick(() => {
            this.showStartPicker = !this.showStartPicker;
            this.showEndPicker = false;
          })

          if (this.showStartPicker) {
            DatePicker({
              start: new Date('2020-1-1'),
              end: new Date('2030-12-31'),
              selected: this.startPickerDate
            })
              .width('90%')
              .onChange((value: DatePickerResult) => {
                const month = (value.month! + 1).toString().padStart(2, '0');
                const day = value.day!.toString().padStart(2, '0');
                this.leaveStartDate = value.year + '-' + month + '-' + day;
                this.showStartPicker = false;
              })
          }

          // End date
          Text('结束日期').fontSize(14).fontColor('#8E8E93').width('90%').margin({ top: 10 })
          Row() {
            Text(this.leaveEndDate || '点击选择日期')
              .fontSize(14)
              .fontColor(this.leaveEndDate ? '#333' : '#C7C7CC')
              .layoutWeight(1)
            Text(this.showEndPicker ? '▲' : '▼').fontSize(12).fontColor('#8E8E93')
          }
          .width('90%').height(44).backgroundColor('#F2F2F7').borderRadius(8)
          .padding({ left: 14, right: 14 }).margin({ top: 4 })
          .onClick(() => {
            this.showEndPicker = !this.showEndPicker;
            this.showStartPicker = false;
          })

          if (this.showEndPicker) {
            DatePicker({
              start: new Date('2020-1-1'),
              end: new Date('2030-12-31'),
              selected: this.endPickerDate
            })
              .width('90%')
              .onChange((value: DatePickerResult) => {
                const month = (value.month! + 1).toString().padStart(2, '0');
                const day = value.day!.toString().padStart(2, '0');
                this.leaveEndDate = value.year + '-' + month + '-' + day;
                this.showEndPicker = false;
              })
          }

          // Reason
          Text('请假原因').fontSize(14).fontColor('#8E8E93').width('90%').margin({ top: 10 })
          TextArea({ placeholder: '请详细描述请假原因...', text: this.leaveReason })
            .width('90%').height(100).backgroundColor('#F2F2F7').borderRadius(8)
            .padding(12).margin({ top: 4 })
            .onChange((v: string) => { this.leaveReason = v })

          // Submit
          Button() {
            if (this.leaveSubmitting) {
              LoadingProgress().width(22).height(22).color(Color.White)
            } else {
              Text('提交申请').fontSize(16).fontColor(Color.White)
            }
          }
          .type(ButtonType.Capsule).width('90%').height(46)
          .backgroundColor('#007AFF').margin({ top: 16 })
          .enabled(!this.leaveSubmitting)
          .onClick(() => { this.doLeaveSubmit() })

          if (this.leaveResult) {
            Text((this.leaveSuccess ? '✅ ' : '❌ ') + this.leaveResult)
              .fontSize(14)
              .fontColor(this.leaveSuccess ? '#34C759' : '#FF3B30')
              .margin({ top: 12 })
          }
        }
        .width('100%').alignItems(HorizontalAlign.Center)
        .padding({ bottom: 24 })
      }
      .layoutWeight(1).width('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 2: 统计 ====================

  async loadStats(silent: boolean = false) {
    if (!silent) {
      this.statsLoading = true;
    }
    const userRole = AppStorage.get<string>('user_role') || 'student';
    try {
      const token = getToken();
      // Only students have checkin records; skip for teachers
      if (userRole === 'student') {
        const cr = await CheckinApi.getMyRecords(token) as CheckinRecordsResponse;
        if (cr && cr.code === 1) {
          this.records = cr.data || [];
          this.totalCheckins = this.records.length;
          this.qrCount = 0; this.locationCount = 0;
          for (const r of this.records) {
            if (r.type === 'qrcode') { this.qrCount++ } else { this.locationCount++ }
          }
        }
      }
      const lr = await LeaveApi.getMyLeaves(token) as LeaveRecordsResponse;
      if (lr && lr.code === 1) {
        this.leaves = lr.data || [];

        // ── Notification: leave approval result ──
        for (const leave of this.leaves) {
          const prevStatus = this.leaveStatusMap.get(leave.id);
          // Show notification when status changes from 'pending' to approved/rejected
          if (prevStatus === 'pending' && leave.status !== 'pending') {
            await NotificationService.showLeaveApprovalResult(
              leave.id, leave.status, leave.approvalComment || ''
            );
          }
          this.leaveStatusMap.set(leave.id, leave.status);
        }
      }
    } catch (_e) {
      // Silently handle - backend may return errors for invalid data
    } finally {
      if (!silent) {
        this.statsLoading = false;
      }
      this.updateWidgetCard();
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

  @Builder TabStats() {
    Column() {
      Text('我的记录')
        .fontSize(20).fontWeight(FontWeight.Bold).width('100%')
        .padding({ left: 20, top: 16, bottom: 8 })

      // Sub tabs
      Row() {
        Text('签到').fontSize(14)
          .fontColor(this.statSubTab === 0 ? '#007AFF' : '#8E8E93')
          .padding({ bottom: 6 })
          .border({ width: { bottom: this.statSubTab === 0 ? 2 : 0 }, color: '#007AFF' })
          .onClick(() => { this.statSubTab = 0 })
        Text('请假').fontSize(14)
          .fontColor(this.statSubTab === 1 ? '#007AFF' : '#8E8E93')
          .margin({ left: 24 })
          .padding({ bottom: 6 })
          .border({ width: { bottom: this.statSubTab === 1 ? 2 : 0 }, color: '#007AFF' })
          .onClick(() => { this.statSubTab = 1 })
        Blank()
      }.width('100%').padding({ left: 20 })

      if (this.statsLoading) {
        LoadingProgress().width(36).height(36).margin({ top: 60 })
      } else if (this.statSubTab === 0) {
        Scroll() {
          Column() {
            Row() {
              StatCard({ icon: '📋', label: '总签到', v: this.totalCheckins.toString(), c: '#007AFF' })
              StatCard({ icon: '📱', label: '二维码', v: this.qrCount.toString(), c: '#34C759' })
              StatCard({ icon: '📍', label: '位置', v: this.locationCount.toString(), c: '#FF9500' })
            }.width('90%').margin({ top: 8 })

            if (this.records.length === 0) {
              Text('暂无签到记录').fontSize(14).fontColor('#C7C7CC').margin({ top: 40 })
            } else {
              ForEach(this.records, (r: CheckinRecord) => {
                Column() {
                  Row() {
                    Column() {
                      Text(r.taskTitle).fontSize(14).fontWeight(FontWeight.Medium)
                      Text(r.signTime).fontSize(12).fontColor('#8E8E93').margin({ top: 2 })
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                    Text(r.type === 'qrcode' ? '📱' : '📍').fontSize(14)
                  }.width('90%').height(52).padding({ left: 14, right: 14 })
                  .backgroundColor(Color.White)
                  .onClick(() => {
                    if (this.selectedRecordId === r.id) {
                      this.selectedRecordId = -1;
                    } else {
                      this.selectedRecordId = r.id;
                    }
                  })

                  if (this.selectedRecordId === r.id) {
                    Column() {
                      Row() {
                        Text('签到方式').fontSize(12).fontColor('#8E8E93').width(70)
                        Text(r.type === 'qrcode' ? '二维码签到' : '位置签到').fontSize(12).fontColor('#333')
                      }.width('90%').margin({ top: 4 })
                      Row() {
                        Text('签到时间').fontSize(12).fontColor('#8E8E93').width(70)
                        Text(r.signTime).fontSize(12).fontColor('#333')
                      }.width('90%').margin({ top: 4 })
                      Row() {
                        Text('任务名称').fontSize(12).fontColor('#8E8E93').width(70)
                        Text(r.taskTitle).fontSize(12).fontColor('#333')
                      }.width('90%').margin({ top: 4 })
                      Row() {
                        Text('记录编号').fontSize(12).fontColor('#8E8E93').width(70)
                        Text(r.id.toString()).fontSize(12).fontColor('#333')
                      }.width('90%').margin({ top: 4 })
                    }
                    .width('100%').padding({ left: 14, right: 14, top: 6, bottom: 10 })
                    .backgroundColor('#FAFAFA')
                    .border({ width: { bottom: 1 }, color: '#F2F2F7' })
                  }
                }.width('100%')
              }, (item: CheckinRecord) => item.id.toString())
            }
          }.width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 20 })
        }.layoutWeight(1).width('100%')
      } else {
        Column() {
          // Status filter
          Row() {
            Text('全部').fontSize(12)
              .fontColor(this.leaveFilter === 'all' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveFilter === 'all' ? '#007AFF' : '#F2F2F7')
              .borderRadius(10).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .onClick(() => { this.leaveFilter = 'all' })
            Text('待批阅').fontSize(12)
              .fontColor(this.leaveFilter === 'pending' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveFilter === 'pending' ? '#FF9500' : '#F2F2F7')
              .borderRadius(10).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 8 })
              .onClick(() => { this.leaveFilter = 'pending' })
            Text('已批准').fontSize(12)
              .fontColor(this.leaveFilter === 'approved' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveFilter === 'approved' ? '#34C759' : '#F2F2F7')
              .borderRadius(10).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 8 })
              .onClick(() => { this.leaveFilter = 'approved' })
            Text('已拒绝').fontSize(12)
              .fontColor(this.leaveFilter === 'rejected' ? Color.White : '#8E8E93')
              .backgroundColor(this.leaveFilter === 'rejected' ? '#FF3B30' : '#F2F2F7')
              .borderRadius(10).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .margin({ left: 8 })
              .onClick(() => { this.leaveFilter = 'rejected' })
            Blank()
          }.width('90%').margin({ top: 8, bottom: 8 })

          Scroll() {
            Column() {
              if (this.leaves.length === 0) {
                Text('暂无请假记录').fontSize(14).fontColor('#C7C7CC').margin({ top: 40 })
              } else {
                ForEach(this.leaves, (l: LeaveRecord) => {
                  if (this.leaveFilter !== 'all' && l.status !== this.leaveFilter) {
                    // skip filtered-out items silently
                  } else {
                    Row() {
                      Column() {
                        Text(l.leaveType + ' · ' + l.startDate + '~' + l.endDate).fontSize(14)
                        Text(l.reason).fontSize(12).fontColor('#8E8E93').margin({ top: 3 })
                      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                      Text(this.getLeaveStatusText(l.status))
                        .fontSize(11).fontColor(Color.White)
                        .backgroundColor(this.getLeaveStatusColor(l.status))
                        .borderRadius(8).padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    }.width('90%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
                    .backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#F2F2F7' })
                  }
                }, (item: LeaveRecord) => item.id.toString())
              }
            }.width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 20 })
          }.layoutWeight(1).width('100%')
        }
        .width('100%').layoutWeight(1)
      }
    }
    .width('100%').height('100%')
  }

  // ==================== Tab 3: 我的 ====================

  @Builder TabProfile() {
    Column() {
      Column() {
        Circle().width(64).height(64).fill('#007AFF')
        Text(this.userName.charAt(0)).fontSize(28).fontColor(Color.White).position({ x: 18, y: 10 })
        Text(this.userName).fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 10 })
        if (this.studentNo) {
          Text('学号: ' + this.studentNo).fontSize(14).fontColor('#8E8E93').margin({ top: 4 })
        }
      }
      .width('100%').padding(20).backgroundColor(Color.White).alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text('📋 签到任务').fontSize(15)
          Blank(); Text('>').fontColor('#C7C7CC')
        }.width('100%').height(48).padding({ left: 16, right: 16 })
        .backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#F2F2F7' })
        .onClick(() => { this.currentTab = 0 })

        Row() {
          Text('📊 我的记录').fontSize(15)
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

  // ==================== Navigation ====================

  @Builder
  NavDestinationMap(name: string) {
    if (name === 'Checkin') {
      CheckinComponent()
    } else if (name === 'LeaveApply') {
      LeaveApplyComponent()
    } else if (name === 'Profile') {
      ProfileComponent()
    } else if (name === 'Statistics') {
      StatisticsComponent()
    } else if (name === 'Approval') {
      ApprovalComponent()
    } else if (name === 'AttendanceDetail') {
      AttendanceDetailComponent()
    } else if (name === 'Home') {
      HomeComponent()
    }
  }

  // ==================== Build ====================

  build() {
    Navigation(this.navPathStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() { this.TabCheckin() }
        .tabBar(this.TabBarBuilder('📋', '签到', 0))

        TabContent() { this.TabLeave() }
        .tabBar(this.TabBarBuilder('📝', '请假', 1))

        TabContent() { this.TabStats() }
        .tabBar(this.TabBarBuilder('📊', '统计', 2))

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
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.NavDestinationMap)
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder TabBarBuilder(icon: string, title: string, idx: number) {
    Column() {
      Text(icon).fontSize(20)
      Text(title).fontSize(11).fontColor(this.currentTab === idx ? '#007AFF' : '#8E8E93')
        .margin({ top: 2 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
struct StatCard {
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
