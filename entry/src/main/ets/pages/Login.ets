import router from '@ohos.router';
import { LoginViewModel } from '../viewmodel/LoginViewModel';

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State role: string = 'student';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State registerMessage: string = '';

  private viewModel: LoginViewModel = new LoginViewModel();

  build() {
    Column() {
      // Logo & Title
      Column() {
        Text('课堂签到')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Text('校园智能考勤系统')
          .fontSize(16)
          .fontColor('#8E8E93')
          .margin({ top: 8 })
      }
      .margin({ top: 80, bottom: 50 })

      // Login form
      Column() {
        // Role selector
        Row() {
          Button('🎓 学生')
            .type(ButtonType.Capsule)
            .height(40)
            .fontSize(14)
            .fontColor(this.role === 'student' ? Color.White : '#8E8E93')
            .backgroundColor(this.role === 'student' ? '#007AFF' : '#F2F2F7')
            .layoutWeight(1)
            .onClick(() => { this.role = 'student'; this.errorMessage = '' })
          Button('📚 教师')
            .type(ButtonType.Capsule)
            .height(40)
            .fontSize(14)
            .fontColor(this.role === 'teacher' ? Color.White : '#8E8E93')
            .backgroundColor(this.role === 'teacher' ? '#FF9500' : '#F2F2F7')
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.role = 'teacher'; this.errorMessage = '' })
        }
        .width('100%')
        .margin({ bottom: 14 })

        TextInput({ placeholder: this.role === 'student' ? '请输入学号' : '请输入工号', text: this.username })
          .width('100%')
          .height(50)
          .backgroundColor('#F2F2F7')
          .borderRadius(10)
          .padding({ left: 16 })
          .margin({ bottom: 12 })
          .onChange((value) => {
            this.username = value;
            this.errorMessage = '';
          })

        TextInput({ placeholder: '请输入密码', text: this.password })
          .width('100%')
          .height(50)
          .backgroundColor('#F2F2F7')
          .borderRadius(10)
          .padding({ left: 16 })
          .type(InputType.Password)
          .showPasswordIcon(true)
          .onChange((value) => {
            this.password = value;
            this.errorMessage = '';
          })

        // Error message
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF3B30')
            .margin({ top: 8, bottom: 4 })
        }

        // Login button
        Button() {
          if (this.isLoading) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(Color.White)
          } else {
            Text('登录')
              .fontSize(18)
              .fontColor(Color.White)
          }
        }
        .type(ButtonType.Capsule)
        .width('100%')
        .height(50)
        .backgroundColor(this.role === 'teacher' ? '#FF9500' : '#007AFF')
        .margin({ top: 20 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.isLoading = true;
          this.errorMessage = '';
          this.viewModel.username = this.username;
          this.viewModel.password = this.password;
          this.viewModel.role = this.role;
          this.viewModel.login().then((success) => {
            this.isLoading = false;
            if (success) {
              AppStorage.setOrCreate('access_token', this.viewModel.token);
              AppStorage.setOrCreate('refresh_token', this.viewModel.refreshToken);
              AppStorage.setOrCreate('user_role', this.viewModel.role);
              AppStorage.setOrCreate('username', this.viewModel.username);
              if (this.role === 'teacher') {
                router.replaceUrl({ url: 'pages/TeacherMain' });
              } else {
                router.replaceUrl({ url: 'pages/Main' });
              }
            } else {
              this.errorMessage = this.viewModel.errorMessage || '登录失败';
            }
          });
        })
      }
      .width('85%')

      // Register link
      if (this.registerMessage) {
        Text(this.registerMessage)
          .fontSize(14)
          .fontColor('#8E8E93')
          .margin({ top: 16 })
      }

      Text('还没有账号？立即注册')
        .fontSize(15)
        .fontColor('#007AFF')
        .margin({ top: 16 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/Register' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
