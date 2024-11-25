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
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景装饰
      Column() {
        Circle()
          .width(200)
          .height(200)
          .fill('#007DFF20')
          .position({ x: -100, y: -100 })
        Circle()
          .width(150)
          .height(150)
          .fill('#007DFF10')
          .position({ x: 300, y: -50 })
      }

      // 主要内容
      Column() {
        // Logo区域
        Image($r('app.media.ic_app'))
          .width(80)
          .height(80)
          .margin({ top: 80, bottom: 40 })

        Text('欢迎登录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })
          .fontColor('#333333')

        Text('请使用手机号登录账号')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 48 })

        // 输入区域
        Column({ space: 24 }) {
          // 手机号输入框
          TextInput({ placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .onChange((value: string) => {
              this.phoneNumber = value;
            })
            .width('100%')
            .height(56)
            .borderRadius(28)
            .backgroundColor('#F5F7FA')
            .fontSize(16)
            .padding({ left: 24, right: 24 })
            .placeholderColor('#999999')

          // 验证码输入区域
          Row({ space: 12 }) {
            TextInput({ placeholder: '请输入验证码' })
              .type(InputType.Number)
              .maxLength(6)
              .onChange((value: string) => {
                this.verifyCode = value;
              })
              .layoutWeight(1)
              .height(56)
              .borderRadius(28)
              .backgroundColor('#F5F7FA')
              .fontSize(16)
              .padding({ left: 24, right: 24 })
              .placeholderColor('#999999')

            Button(this.countdown > 0 ? `${this.countdown}s` : '获取验证码')
              .onClick(() => {
                if (this.countdown <= 0) {
                  this.sendVerifyCode();
                }
              })
              .enabled(this.countdown <= 0 && !this.isLoading)
              .width(120)
              .height(56)
              .fontSize(14)
              .borderRadius(28)
              .backgroundColor(this.countdown > 0 ? '#E5E6EB' : '#007DFF')
              .fontColor(this.countdown > 0 ? '#999999' : '#FFFFFF')
          }

          // 登录按钮
          Button({ type: ButtonType.Capsule }) {
            Row() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color(Color.White)
                  .margin({ right: 8 })
              }
              Text('登录')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
          }
          .width('100%')
          .height(56)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.login();
          })
          .enabled(!this.isLoading)
        }
        .width('100%')
        .padding({ left: 24, right: 24 })

        // 底部协议
        Row() {
          Text('登录即代表您已同意')
            .fontSize(12)
            .fontColor('#999999')
          Text('用户协议')
            .fontSize(12)
            .fontColor('#007DFF')
            .onClick(() => {
              // 跳转到用户协议页面
            })
          Text('和')
            .fontSize(12)
            .fontColor('#999999')
          Text('隐私政策')
            .fontSize(12)
            .fontColor('#007DFF')
            .onClick(() => {
              // 跳转到隐私政策页面
            })
        }
        .margin({ top: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }
}