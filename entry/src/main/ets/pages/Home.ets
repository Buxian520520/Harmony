import { Nav } from '../utils/NavigationUtil';
import { CheckinApi } from '../services/api/checkinApi';
import { LeaveApi } from '../services/api/leaveApi';

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

@Component
struct TaskCard {
  @Prop task: CheckinTask;
  @Prop signed: boolean = false;
  onSignIn: () => void = () => {};

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.task.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text(this.task.type === 'qrcode' ? '📱 二维码签到' : '📍 位置签到')
            .fontSize(14)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(this.signed ? '已签' : '待签')
            .fontSize(13)
            .fontColor(this.signed ? '#34C759' : '#FF9500')
            .backgroundColor(this.signed ? '#E8F8EE' : '#FFF3E0')
            .borderRadius(10)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
      }
      .width('100%')

      Row() {
        Text('🕐 ' + this.task.createTime)
          .fontSize(13)
          .fontColor('#8E8E93')
        Blank()
        Text('👥 ' + this.task.signCount + '人已签')
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .margin({ top: 8 })

      if (!this.signed) {
        Button(this.task.type === 'qrcode' ? '扫码签到' : '定位签到')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(40)
          .fontSize(15)
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .margin({ top: 12 })
          .onClick(() => {
            this.onSignIn();
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
  }
}

interface TaskListResponse {
  code: number;
  msg?: string;
  data?: CheckinTask[];
}

interface SignInParams {
  taskId: number;
  taskTitle: string;
  type: string;
  code: string;
  range: number;
  teacherLat: number;
  teacherLng: number;
}

@Component
export struct HomeComponent {
  @State tasks: CheckinTask[] = [];
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State signedTaskIds: number[] = [];

  private token: string = '';

  aboutToAppear() {
    // Get token from the login flow
    // In a full implementation, token would come from AppStorage
    this.loadTasks();
  }

  async loadTasks() {
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const response = await CheckinApi.getTasks(this.token) as TaskListResponse;
      if (response.code === 1) {
        this.tasks = response.data || [];
      } else {
        this.errorMsg = response.msg || '获取签到任务失败';
      }
    } catch (e) {
      this.errorMsg = '获取签到任务失败，请检查网络连接';
    } finally {
      this.isLoading = false;
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

  build() {
    NavDestination() {
      Column() {
      // Header
      Row() {
        Column() {
          Text('签到任务')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text('共 ' + this.tasks.length + ' 个进行中')
            .fontSize(14)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Circle()
            .width(44)
            .height(44)
            .fill('#007AFF')
          Text('我')
            .fontSize(20)
            .fontColor(Color.White)
            .position({ x: 14, y: 6 })
        }
        .onClick(() => {
          Nav.stack.pushPathByName('Profile', undefined);
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      // Task list
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else if (this.errorMsg) {
        Column() {
          Text(this.errorMsg)
            .fontSize(16)
            .fontColor('#C7C7CC')
          Text('下拉刷新')
            .fontSize(14)
            .fontColor('#C7C7CC')
            .margin({ top: 8 })
        }
        .margin({ top: 100 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else if (this.tasks.length === 0) {
        Column() {
          Text('暂无进行中的签到')
            .fontSize(16)
            .fontColor('#C7C7CC')
          Text('等待教师发起签到')
            .fontSize(14)
            .fontColor('#C7C7CC')
            .margin({ top: 8 })
        }
        .margin({ top: 100 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.tasks, (task: CheckinTask) => {
            ListItem() {
              TaskCard({
                task: task,
                signed: this.isTaskSigned(task.id),
                onSignIn: () => { this.handleSignIn(task) }
              })
            }
          }, (item: CheckinTask) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .margin({ top: 12 })
      }

      // Bottom Tab Bar
      Row() {
        Column() {
          Text('📋').fontSize(22)
          Text('签到').fontSize(12).fontColor('#007AFF')
        }
        .onClick(() => {})

        Column() {
          Text('📝').fontSize(22)
          Text('请假').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { Nav.stack.pushPathByName('LeaveApply', undefined) })

        Column() {
          Text('📊').fontSize(22)
          Text('统计').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { Nav.stack.pushPathByName('Statistics', undefined) })

        Column() {
          Text('👤').fontSize(22)
          Text('我的').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { Nav.stack.pushPathByName('Profile', undefined) })
      }
      .width('100%')
      .height(64)
      .justifyContent(FlexAlign.SpaceAround)
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#E5E5E5' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    }
    .title('签到任务')
    .hideTitleBar(true)
  }
}
