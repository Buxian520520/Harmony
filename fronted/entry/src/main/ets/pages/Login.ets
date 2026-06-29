import router from '@ohos.router';
import { LoginViewModel } from '../viewmodel/LoginViewModel';

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State faceLoginAvailable: boolean = false;

  private viewModel: LoginViewModel = new LoginViewModel();

  aboutToAppear() {
    this.viewModel.checkFaceService();
  }

  build() {
    Column() {
      // Logo & Title
      Column() {
        Text('智能考勤')
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
        TextInput({ placeholder: '请输入用户名', text: this.username })
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
              .fontColor(Color.White)
          } else {
            Text('登录')
              .fontSize(18)
              .fontColor(Color.White)
          }
        }
        .type(ButtonType.Capsule)
        .width('100%')
        .height(50)
        .backgroundColor('#007AFF')
        .margin({ top: 20 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.isLoading = true;
          this.errorMessage = '';
          this.viewModel.username = this.username;
          this.viewModel.password = this.password;
          this.viewModel.login().then((success) => {
            this.isLoading = false;
            if (success) {
              router.replaceUrl({ url: 'pages/Home' });
            } else {
              this.errorMessage = this.viewModel.errorMessage || '登录失败';
            }
          });
        })
      }
      .width('85%')

      // Face login button
      Button('人脸登录')
        .type(ButtonType.Capsule)
        .width('85%')
        .height(48)
        .margin({ top: 16 })
        .backgroundColor(this.faceLoginAvailable ? '#34C759' : '#C7C7CC')
        .fontColor(Color.White)
        .enabled(this.faceLoginAvailable)
        .onClick(() => {
          if (this.faceLoginAvailable) {
            // TODO: Open camera for face recognition login
            // 1. Capture face image using camera
            // 2. Upload to faceApi.identifyFace()
            // 3. Get matched user info, set token, navigate to Home
          }
        })

      if (!this.faceLoginAvailable) {
        Text('扫脸登录功能待接入')
          .fontSize(12)
          .fontColor('#C7C7CC')
          .margin({ top: 4 })
      }

      // Register link
      Text('还没有账号？立即注册')
        .fontSize(15)
        .fontColor('#007AFF')
        .margin({ top: 30 })
        .onClick(() => {
          // TODO: Navigate to register page
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}
