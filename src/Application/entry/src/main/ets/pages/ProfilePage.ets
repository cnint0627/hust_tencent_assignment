// entry/src/main/ets/pages/ProfilePage.ets
import auth from '@hw-agconnect/auth';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserInfo } from '../common/UserInfo';
import { UserService } from '../services/UserService';
import { Settings } from '../common/Settings';
import { SettingsService } from '../services/SettingsService';

@CustomDialog
struct SettingsDialog {
  @State settings: Settings = {
    notification: true,
    sound: true,
    vibration: true
  }
  private settingsService: SettingsService = SettingsService.getInstance()
  controller: CustomDialogController

  aboutToAppear() {
    this.loadSettings()
  }

  async loadSettings(): Promise<void> {
    this.settings = await this.settingsService.getSettings()
  }

  async saveSettings(): Promise<void> {
    const success: boolean = await this.settingsService.saveSettings(this.settings)
    if (success) {
      promptAction.showToast({
        message: '设置已保存',
        duration: 2000
      })
      this.controller.close()
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      })
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Image($r('app.media.ic_settings'))
            .width(40)
            .height(40)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#007DFF')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 40, bottom: 16 })

        Text('系统设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 32 })
      }
      .alignItems(HorizontalAlign.Center)

      Column() {
        List() {
          ListItem() {
            Row() {
              Column() {
                Text('推送通知')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('接收运动提醒和成就提醒')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.notification })
                .onChange((isOn: boolean) => {
                  this.settings.notification = isOn
                })
                .selectedColor('#007DFF')
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }

          ListItem() {
            Row() {
              Column() {
                Text('声音提示')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('运动过程中的语音播报')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.sound })
                .onChange((isOn: boolean) => {
                  this.settings.sound = isOn
                })
                .selectedColor('#007DFF')
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }

          ListItem() {
            Row() {
              Column() {
                Text('震动提示')
                  .fontSize(16)
                  .fontColor('#333333')
                Text('运动目标达成时震动提醒')
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.vibration })
                .onChange((isOn: boolean) => {
                  this.settings.vibration = isOn
                })
                .selectedColor('#007DFF')
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
          }
        }
        .divider({ strokeWidth: 1, color: '#F5F5F5' })
        .backgroundColor('#F8F8F8')
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
      }
      .padding({ left: 24, right: 24 })

      Button('保存', { type: ButtonType.Normal })
        .width('90%')
        .height(50)
        .borderRadius(25)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ top: 32, bottom: 24 })
        .onClick(() => {
          this.saveSettings()
        })
    }
    .width('90%')
    .backgroundColor(Color.White)
    .borderRadius(24)
  }
}

@CustomDialog
struct AboutDialog {
  controller: CustomDialogController

  build() {
    Column() {
      Column() {
        Row() {
          Image($r("app.media.ic_about"))
            .width(40)
            .height(40)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#007DFF')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 40, bottom: 16 })

        Text('运动记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        Text('版本 1.0.0')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 32 })
      }
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Column() {
            Text('4+')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('运动类型')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 8 })
          }

          Column() {
            Text('专业')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('数据分析')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 8 })
          }

          Column() {
            Text('精准')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
            Text('轨迹记录')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: 24, bottom: 24 })
        .backgroundColor('#F8F8F8')
        .borderRadius(16)
        .margin({ bottom: 24 })

        Text('关于我们')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })

        Text('运动记录是一款专注于帮助用户科学运动的应用。我们提供专业的运动数据记录和分析，让每一次运动都更有意义。\n\n始终以用户体验为核心，持续优化产品功能，致力于成为您的专属运动助手。')
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(24)
      }
      .padding({ left: 24, right: 24 })

      Button('了解更多', { type: ButtonType.Normal })
        .width('90%')
        .height(50)
        .borderRadius(25)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .margin({ top: 32 })
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('90%')
    .backgroundColor(Color.White)
    .borderRadius(24)
    .padding({ bottom: 24 })
  }
}

@CustomDialog
struct FeedbackDialog {
  @State feedback: string = ''
  @State feedbackType: string = '功能建议'
  controller: CustomDialogController
  private readonly feedbackTypes: string[] = ['功能建议', '体验问题', '其他']

  build() {
    Stack() {
      // 透明背景层，用于处理点击事件
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('transparent')
        .onClick(() => {
          this.controller.close()
        })

      // 弹窗内容
      Column() {
        Column() {
          Row() {
            Image($r('app.media.ic_feedback'))
              .width(40)
              .height(40)
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#007DFF')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 40, bottom: 16 })

          Text('意见反馈')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 32 })
        }
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text('反馈类型')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          Row() {
            ForEach(this.feedbackTypes, (type: string) => {
              Text(type)
                .fontSize(14)
                .fontColor(this.feedbackType === type ? '#007DFF' : '#666666')
                .backgroundColor(this.feedbackType === type ? '#007DFF10' : '#F5F5F5')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(16)
                .margin({ right: 12 })
                .onClick((event: ClickEvent) => {
                  this.feedbackType = type
                  event.preventDefault
                })
            })
          }
          .width('100%')
          .margin({ bottom: 24 })

          Text('反馈内容')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })

          TextArea({ placeholder: '请详细描述您的问题或建议...', text: this.feedback })
            .width('100%')
            .height(120)
            .backgroundColor('#F8F8F8')
            .borderRadius(16)
            .fontSize(16)
            .padding(16)
            .onChange((value: string) => {
              this.feedback = value
            })
        }
        .padding({ left: 24, right: 24 })

        Button('提交反馈', { type: ButtonType.Normal })
          .width('90%')
          .height(50)
          .borderRadius(25)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .margin({ top: 32, bottom: 24 })
          .onClick((event: ClickEvent) => {
            if (!this.feedback.trim()) {
              promptAction.showToast({
                message: '请输入反馈内容',
                duration: 2000
              })
              return
            }
            this.controller.close()
            promptAction.showToast({
              message: '感谢您的反馈！',
              duration: 2000
            })
          })
      }
      .width('90%')
      .backgroundColor(Color.White)
      .borderRadius(24)
      .position({ x: '5%', y: '20%' })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct ProfilePage {
  @State user: UserInfo | null = null
  private userService: UserService = UserService.getInstance()
  private settingsService: SettingsService = SettingsService.getInstance()

  private settingsDialog: CustomDialogController = new CustomDialogController({
    builder: SettingsDialog(),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  private aboutDialog: CustomDialogController = new CustomDialogController({
    builder: AboutDialog(),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  private feedbackDialog: CustomDialogController = new CustomDialogController({
    builder: FeedbackDialog(),
    customStyle: true,
    alignment: DialogAlignment.Center,
  })

  aboutToAppear() {
    this.userService.getCurrentUserInfo().then((userInfo: UserInfo | null) => {
      this.user = userInfo
    }).catch((err: Error) => {
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
        Image($r('app.media.ic_enter'))
          .width(16)
          .height(16)
          .opacity(0.6)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .height(56)
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(onClick)
    .borderRadius(15)
  }

  async logout(): Promise<void> {
    try {
      await auth.signOut()
      promptAction.showToast({
        message: '退出登录成功',
        duration: 2000
      })
      router.replaceUrl({ url: 'pages/LoginPage' })
    } catch (err) {
      console.error('退出登录失败:', err)
      promptAction.showToast({
        message: '退出登录失败，请重试',
        duration: 2000
      })
    }
  }

  build() {
    Column() {
      Row() {
        Text('个人中心')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Column() {
        Row() {
          Row() {
            Text(this.user?.nickname?.substring(0, 1) || 'U')
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
            Text(this.user?.nickname || '未登录')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 4 })

            Text(this.user?.phoneNumber || '')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })

            Text(`uid: ${this.user?.uid || ''}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Text('编辑')
            .fontSize(14)
            .fontColor('#007DFF')
            .onClick(() => {
              promptAction.showToast({
                message: '功能开发中',
                duration: 2000
              })
            })
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .margin({ bottom: 12 })
      .borderRadius(16)

      Column() {
        this.MenuButton('设置', () => {
          this.settingsDialog = new CustomDialogController({
            builder: SettingsDialog(),
            customStyle: true,
            alignment: DialogAlignment.Center
          })
          this.settingsDialog.open()
        })

        Divider().color('#F5F5F5').height(1)

        this.MenuButton('关于', () => {
          this.aboutDialog.open()
        })

        Divider().color('#F5F5F5').height(1)

        this.MenuButton('意见反馈', () => {
          this.feedbackDialog.open()
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)

      Button('退出登录', { type: ButtonType.Normal })
        .width('90%')
        .height(50)
        .borderRadius(25)
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
                this.logout()
              }
            }
          })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 12, right: 12 })
  }
}