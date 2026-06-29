import router from '@ohos.router';
import { AttendanceApi } from '../services/api/attendanceApi';
import { AuthApi } from '../services/api/authApi';

interface Course {
  id: number;
  name: string;
  teacher_name: string;
  class_name: string;
  start_time: string;
  end_time: string;
  weekdays: string;
  classroom: string;
  student_count: number;
}

@Entry
@Component
struct Home {
  @State courses: Course[] = [];
  @State isLoading: boolean = true;
  @State userName: string = '用户';
  @State userRole: string = '';

  private token: string = ''; // TODO: Get from AppStorage

  aboutToAppear() {
    this.loadCourses();
  }

  async loadCourses() {
    this.isLoading = true;
    try {
      // TODO: Get token from AppStorage / persistent storage
      // const result = await AttendanceApi.getMyCourses(this.token);
      // this.courses = result as Course[];
      // Simulated data for now:
      this.courses = [
        {
          id: 1, name: '高等数学', teacher_name: '张老师',
          class_name: '计算机2101', start_time: '08:00', end_time: '09:40',
          weekdays: '1,3', classroom: '教学楼A201', student_count: 45
        },
        {
          id: 2, name: '大学英语', teacher_name: '李老师',
          class_name: '计算机2101', start_time: '10:00', end_time: '11:40',
          weekdays: '2,4', classroom: '教学楼B305', student_count: 42
        },
        {
          id: 3, name: '数据结构', teacher_name: '王老师',
          class_name: '计算机2101', start_time: '14:00', end_time: '15:40',
          weekdays: '1,3', classroom: '实验楼C102', student_count: 40
        }
      ];
    } catch (e) {
      console.error('Failed to load courses: ' + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Column() {
          Text('我的课程')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          Text('共 ' + this.courses.length + ' 门课程')
            .fontSize(14)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // Avatar / Profile
        Column() {
          Circle()
            .width(44)
            .height(44)
            .fill('#007AFF')
          Text(this.userName.charAt(0))
            .fontSize(20)
            .fontColor(Color.White)
            .position({ x: 12, y: 6 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/Profile' });
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      // Course list
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .margin({ top: 100 })
      } else if (this.courses.length === 0) {
        Column() {
          Text('暂无课程')
            .fontSize(16)
            .fontColor('#C7C7CC')
          Text('请联系管理员添加课程')
            .fontSize(14)
            .fontColor('#C7C7CC')
            .margin({ top: 8 })
        }
        .margin({ top: 100 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.courses, (course: Course, index?: number) => {
            ListItem() {
              this.CourseCard(course)
            }
          }, (item: Course) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 12 })
      }

      // Bottom Tab Bar
      Row() {
        Column() {
          Text('📚').fontSize(22)
          Text('课程').fontSize(12).fontColor('#007AFF')
        }
        .onClick(() => {})

        Column() {
          Text('📍').fontSize(22)
          Text('签到').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { router.pushUrl({ url: 'pages/Checkin' }) })

        Column() {
          Text('📊').fontSize(22)
          Text('统计').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { router.pushUrl({ url: 'pages/Statistics' }) })

        Column() {
          Text('👤').fontSize(22)
          Text('我的').fontSize(12).fontColor('#8E8E93')
        }
        .onClick(() => { router.pushUrl({ url: 'pages/Profile' }) })
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

  @Builder CourseCard(course: Course) {
    Column() {
      Row() {
        Column() {
          Text(course.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)

          Text(course.teacher_name + ' · ' + course.class_name)
            .fontSize(14)
            .fontColor('#8E8E93')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(course.student_count + '人')
          .fontSize(13)
          .fontColor('#007AFF')
          .backgroundColor('#E8F0FE')
          .borderRadius(12)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      }
      .width('100%')

      Row() {
        Text('⏰ ' + course.start_time + ' - ' + course.end_time)
          .fontSize(13)
          .fontColor('#8E8E93')
        Blank()
        Text('📍 ' + course.classroom)
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .margin({ top: 10 })

      // Checkin status indicator placeholder
      Row() {
        Circle().width(8).height(8).fill('#C7C7CC')
        Text(' 今日未签到')
          .fontSize(13)
          .fontColor('#C7C7CC')
      }
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/AttendanceDetail',
        params: { courseId: course.id, courseName: course.name }
      });
    })
  }
}
