// entry/src/main/ets/pages/LoginPage.ets
import router from '@ohos.router';
import auth, { PhoneCredentialInfo, VerifyCodeAction } from '@hw-agconnect/auth';
import cloud from '@hw-agconnect/cloud';
import promptAction from '@ohos.promptAction';
import { UserService } from '../services/UserService';

@Entry
@Component
struct LoginPage {
  @State phoneNumber: string = '';
  @State verifyCode: string = '';
  @State isLoading: boolean = false;
  @State countdown: number = 0;
  private countdownTimer: number = -1;
  private userService: UserService = UserService.getInstance();

  aboutToDisappear() {
    // 清除定时器
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
  }

  startCountdown() {
    this.countdown = 60;
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(this.countdownTimer);
        this.countdownTimer = -1;
      }
    }, 1000);
  }

  validatePhoneNumber(): boolean {
    // 简单的手机号验证
    const phoneRegex = /^1[3-9]\d{9}$/;
    return phoneRegex.test(this.phoneNumber);
  }

  async sendVerifyCode() {
    if (!this.validatePhoneNumber()) {
      promptAction.showToast({
        message: '请输入正确的手机号',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;
    cloud.auth().requestVerifyCode({
      action: VerifyCodeAction.REGISTER_LOGIN,
      lang: 'zh_CN',
      sendInterval: 60,
      verifyCodeType: {
        phoneNumber: this.phoneNumber,
        countryCode: "86",
        kind: "phone",
      }
    }).then(verifyCodeResult => {
      // 验证码申请成功
      promptAction.showToast({
        message: '验证码已发送',
        duration: 2000
      });

      // 开始倒计时
      this.startCountdown();
    }).catch((error: Error) => {
      // 验证码申请失败
      console.error('Send verification code failed:', error);
      promptAction.showToast({
        message: '发送验证码失败，请稍后重试',
        duration: 2000
      });
    }).finally(()=> {
      this.isLoading = false;
    });
  }

  async login() {
    if (!this.validatePhoneNumber()) {
      promptAction.showToast({
        message: '请输入正确的手机号',
        duration: 2000
      });
      return;
    }

    if (!this.verifyCode) {
      promptAction.showToast({
        message: '请输入验证码',
        duration: 2000
      });
      return;
    }

    try {
      this.isLoading = true;
      await cloud.auth().signIn({
        credentialInfo: {
          kind: 'phone',
          phoneNumber: this.phoneNumber,
          countryCode: '86',
          verifyCode: this.verifyCode
        }
      })
      // 获取并保存用户信息
      await this.userService.getCurrentUserInfo();
      // 登录成功
      promptAction.showToast({
        message: '登录成功',
        duration: 2000
      });
      // 跳转到首页
      router.replaceUrl({ url: 'pages/Index' });
    } catch (error) {
      // 登录失败
      console.error('Login failed:', error);
      promptAction.showToast({
        message: '登录失败，请检查验证码是否正确',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text('登录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 40 })

      Column() {
        TextInput({ placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((value: string) => {
            this.phoneNumber = value;
          })
          .height(50)
          .width('100%')
          .margin({ bottom: 20 })
          .backgroundColor('#F5F5F5')
          .borderRadius(8)

        Row() {
          TextInput({ placeholder: '请输入验证码' })
            .type(InputType.Number)
            .maxLength(6)
            .onChange((value: string) => {
              this.verifyCode = value;
            })
            .height(50)
            .layoutWeight(1)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)

          Button(this.countdown > 0 ? `${this.countdown}s` : '发送验证码')
            .onClick(() => {
              if (this.countdown <= 0) {
                this.sendVerifyCode();
              }
            })
            .enabled(this.countdown <= 0 && !this.isLoading)
            .margin({ left: 10 })
            .height(50)
            .backgroundColor(this.countdown > 0 ? '#CCCCCC' : '#007DFF')
        }
        .width('100%')
        .margin({ bottom: 40 })

        Button('登录')
          .width('100%')
          .height(50)
          .backgroundColor('#007DFF')
          .borderRadius(8)
          .onClick(() => {
            this.login();
          })
          .enabled(!this.isLoading)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      if (this.isLoading) {
        LoadingProgress()
          .color('#007DFF')
          .width(30)
          .height(30)
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}