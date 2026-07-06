import router from '@ohos.router';
import { AuthApi, RegisterRequest } from '../services/api/authApi';

interface RegisterResponse {
  code: number;
  msg: string;
  access_token: string;
  refresh_token: string;
}

@Component
struct InputRow {
  @Prop label: string;
  @Prop placeholder: string;
  @Prop value: string;
  onChange: (value: string) => void = (_v: string) => {};

  build() {
    Column() {
      Text(this.label)
        .fontSize(15)
        .fontColor('#8E8E93')
        .width('100%')
      TextInput({ placeholder: this.placeholder, text: this.value })
        .width('100%')
        .height(48)
        .backgroundColor('#F2F2F7')
        .borderRadius(10)
        .padding({ left: 16 })
        .margin({ top: 6 })
        .onChange((value: string) => {
          this.onChange(value);
        })
    }
    .width('85%')
    .margin({ bottom: 12 })
  }
}

@Entry
@Component
struct Register {
  @State role: string = 'student';
  // Student fields
  @State username: string = '';
  @State studentName: string = '';
  @State gender: string = '男';
  @State birthday: string = '';
  @State mobile: string = '';
  @State email: string = '';
  @State address: string = '';
  // Teacher fields
  @State teacherNo: string = '';
  @State teacherName: string = '';
  // Common
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State successMessage: string = '';

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => { router.back() })
        Text('用户注册')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        Blank()
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          // Role selector
          Column() {
            Text('注册身份')
              .fontSize(15)
              .fontColor('#8E8E93')
              .width('85%')
            Row() {
              Button('🎓 学生')
                .type(ButtonType.Capsule)
                .height(44)
                .fontSize(15)
                .fontColor(this.role === 'student' ? Color.White : '#8E8E93')
                .backgroundColor(this.role === 'student' ? '#007AFF' : '#F2F2F7')
                .layoutWeight(1)
                .onClick(() => { this.role = 'student' })
              Button('📚 教师')
                .type(ButtonType.Capsule)
                .height(44)
                .fontSize(15)
                .fontColor(this.role === 'teacher' ? Color.White : '#8E8E93')
                .backgroundColor(this.role === 'teacher' ? '#007AFF' : '#F2F2F7')
                .layoutWeight(1)
                .margin({ left: 8 })
                .onClick(() => { this.role = 'teacher' })
            }
            .width('85%')
            .margin({ top: 6 })
          }
          .width('100%')
          .margin({ bottom: 14 })
          .alignItems(HorizontalAlign.Center)

          // Success message
          if (this.successMessage) {
            Column() {
              Text('注册成功')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#34C759')
              Text(this.successMessage)
                .fontSize(14)
                .fontColor('#8E8E93')
                .margin({ top: 8 })
              Button('去登录')
                .type(ButtonType.Capsule)
                .width('60%')
                .height(44)
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor('#007AFF')
                .margin({ top: 20 })
                .onClick(() => {
                  router.replaceUrl({ url: 'pages/Login' });
                })
            }
            .width('100%')
            .padding(30)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)
          }

          // Error message
          if (this.errorMessage && !this.successMessage) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#FF3B30')
              .width('85%')
              .margin({ bottom: 12 })
          }

          if (!this.successMessage) {
            if (this.role === 'student') {
              this.StudentFields()
            } else {
              this.TeacherFields()
            }

            // Common fields: password
            Column() {
              Text('密码')
                .fontSize(15)
                .fontColor('#8E8E93')
                .width('85%')
              TextInput({ placeholder: '请输入密码（至少6位）', text: this.password })
                .width('85%')
                .height(48)
                .backgroundColor('#F2F2F7')
                .borderRadius(10)
                .padding({ left: 16 })
                .type(InputType.Password)
                .showPasswordIcon(true)
                .onChange((v: string) => { this.password = v })
            }
            .width('100%')
            .margin({ bottom: 12 })
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('确认密码')
                .fontSize(15)
                .fontColor('#8E8E93')
                .width('85%')
              TextInput({ placeholder: '再次输入密码', text: this.confirmPassword })
                .width('85%')
                .height(48)
                .backgroundColor('#F2F2F7')
                .borderRadius(10)
                .padding({ left: 16 })
                .type(InputType.Password)
                .showPasswordIcon(true)
                .onChange((v: string) => { this.confirmPassword = v })
            }
            .width('100%')
            .margin({ bottom: 12 })
            .alignItems(HorizontalAlign.Center)

            // Register button
            Button() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color(Color.White)
              } else {
                Text(this.role === 'student' ? '学生注册' : '教师注册')
                  .fontSize(18)
                  .fontColor(Color.White)
              }
            }
            .type(ButtonType.Capsule)
            .width('85%')
            .height(50)
            .backgroundColor(this.role === 'teacher' ? '#FF9500' : '#007AFF')
            .margin({ top: 8, bottom: 20 })
            .enabled(!this.isLoading)
            .onClick(() => { this.doRegister() })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder StudentFields() {
    Column() {
      InputRow({ label: '学号', placeholder: '请输入学号（数字）', value: this.username,
        onChange: (v: string) => { this.username = v } })

      InputRow({ label: '姓名', placeholder: '请输入真实姓名', value: this.studentName,
        onChange: (v: string) => { this.studentName = v } })

      // Gender
      Column() {
        Text('性别')
          .fontSize(15).fontColor('#8E8E93').width('85%')
        Row() {
          Button('男')
            .type(ButtonType.Capsule).height(40).fontSize(14)
            .fontColor(this.gender === '男' ? Color.White : '#8E8E93')
            .backgroundColor(this.gender === '男' ? '#007AFF' : '#F2F2F7')
            .onClick(() => { this.gender = '男' })
          Button('女')
            .type(ButtonType.Capsule).height(40).fontSize(14)
            .fontColor(this.gender === '女' ? Color.White : '#8E8E93')
            .backgroundColor(this.gender === '女' ? '#007AFF' : '#F2F2F7')
            .margin({ left: 8 })
            .onClick(() => { this.gender = '女' })
        }
        .width('85%').margin({ top: 6 })
      }
      .width('100%').margin({ bottom: 12 }).alignItems(HorizontalAlign.Center)

      InputRow({ label: '生日', placeholder: 'YYYY-MM-DD 如 2006-09-01', value: this.birthday,
        onChange: (v: string) => { this.birthday = v } })

      InputRow({ label: '手机号（选填）', placeholder: '请输入手机号', value: this.mobile,
        onChange: (v: string) => { this.mobile = v } })

      InputRow({ label: '邮箱（选填）', placeholder: '请输入邮箱地址', value: this.email,
        onChange: (v: string) => { this.email = v } })

      InputRow({ label: '住址（选填）', placeholder: '请输入家庭住址', value: this.address,
        onChange: (v: string) => { this.address = v } })

      Text('📷 人脸采集功能后续开放')
        .fontSize(12).fontColor('#C7C7CC').margin({ top: 4, bottom: 8 })
    }
    .width('100%').alignItems(HorizontalAlign.Center)
  }

  @Builder TeacherFields() {
    Column() {
      InputRow({ label: '工号', placeholder: '请输入教师工号', value: this.teacherNo,
        onChange: (v: string) => { this.teacherNo = v; this.username = v } })

      InputRow({ label: '姓名（选填）', placeholder: '请输入姓名', value: this.teacherName,
        onChange: (v: string) => { this.teacherName = v } })

      Column() {
        Text('教师注册说明')
          .fontSize(13)
          .fontColor('#8E8E93')
          .width('85%')
        Text('• 工号作为登录账号\n• 姓名选填，可后续完善\n• 注册后由管理员审核')
          .fontSize(12)
          .fontColor('#C7C7CC')
          .width('85%')
          .margin({ top: 4 })
      }
      .width('100%')
      .margin({ top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').alignItems(HorizontalAlign.Center)
  }

  async doRegister() {
    // Common validation
    if (!this.password || !this.confirmPassword) {
      this.errorMessage = '请输入密码';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次密码输入不一致';
      return;
    }
    if (this.password.length < 6) {
      this.errorMessage = '密码至少需要6位';
      return;
    }

    if (this.role === 'student') {
      if (!this.username || !this.studentName || !this.birthday) {
        this.errorMessage = '请填写所有必填项（学号、姓名、生日）';
        return;
      }
    } else {
      if (!this.teacherNo) {
        this.errorMessage = '请输入教师工号';
        return;
      }
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // Build request payload matching backend RegisterRequest
      let reqData: RegisterRequest;
      if (this.role === 'student') {
        reqData = {
          username: this.username,
          password: this.password,
          role: 'student',
          student_name: this.studentName,
          gender: this.gender,
          birthday: this.birthday,
          mobile: this.mobile,
          email: this.email,
          address: this.address,
        };
      } else {
        reqData = {
          username: this.teacherNo,
          password: this.password,
          role: 'teacher',
          teacher_no: this.teacherNo,
          teacher_name: this.teacherName,
        };
      }

      const response = await AuthApi.register(reqData) as RegisterResponse;

      if (response.code === 200) {
        this.successMessage = response.msg || '注册成功';
        this.errorMessage = '';
      } else {
        this.errorMessage = response.msg || '注册失败';
      }
    } catch (_e) {
      this.errorMessage = '注册失败，请检查网络连接';
    } finally {
      this.isLoading = false;
    }
  }
}
