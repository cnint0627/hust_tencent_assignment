// entry/src/main/ets/pages/ProfilePage.ets
import auth from '@hw-agconnect/auth';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserInfo } from '../common/UserInfo';
import { UserService } from '../services/UserService';


@Component
export struct ProfilePage {
  @State user: UserInfo | null = null;
  private userService: UserService = UserService.getInstance();

  aboutToAppear() {
    this.userService.getCurrentUserInfo().then((userInfo)=>{
      this.user = userInfo
    }).catch((err: Error)=>{
      console.error("用户信息获取失败")
    })
  }

  @Builder
  MenuButton(title: string, onClick: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row() {
        Text(title)
          .fontSize(16)
          .fontColor('#333')
        Blank()
        // 使用简单的字符代替图标
        Text('>')
          .fontSize(16)
          .fontColor('#999')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .height(56)
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(onClick)
  }

  async logout() {
    try {
      await auth.signOut();
      promptAction.showToast({
        message: '退出登录成功',
        duration: 2000
      });
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      console.error('退出登录失败:', error);
      promptAction.showToast({
        message: '退出登录失败，请重试',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('个人中心')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 用户信息卡片
      Column() {
        Row() {
          // 使用圆形背景代替头像图片
          Row() {
            Text(this.user?.nickname.substring(0, 1))
              .fontSize(32)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#007DFF')
          .justifyContent(FlexAlign.Center)
          .margin({ right: 16 })

          Column() {
            Text(this.user?.nickname)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 4 })

            Text(this.user?.phoneNumber)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4})

            Text(`uid: ${this.user?.uid}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 使用文本代替编辑图标
          Text('编辑')
            .fontSize(14)
            .fontColor('#007DFF')
            .onClick(() => {
              promptAction.showToast({
                message: '功能开发中',
                duration: 2000
              });
            })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ bottom: 12 })

      // 功能菜单
      Column() {
        this.MenuButton('设置', () => {
          promptAction.showToast({
            message: '功能开发中',
            duration: 2000
          });
        })

        Divider().color('#F5F5F5').height(1)

        this.MenuButton('关于', () => {
          promptAction.showToast({
            message: '功能开发中',
            duration: 2000
          });
        })

        Divider().color('#F5F5F5').height(1)

        this.MenuButton('意见反馈', () => {
          promptAction.showToast({
            message: '功能开发中',
            duration: 2000
          });
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 退出登录按钮
      Button('退出登录', { type: ButtonType.Normal })
        .width('90%')
        .height(50)
        .backgroundColor('#FF4444')
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          AlertDialog.show({
            title: '提示',
            message: '确定要退出登录吗？',
            primaryButton: {
              value: '取消',
              action: () => {}
            },
            secondaryButton: {
              value: '确定',
              action: () => {
                this.logout();
              }
            }
          });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}