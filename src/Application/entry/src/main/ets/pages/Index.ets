// entry/src/main/ets/pages/Index.ets
import auth, { AuthUser } from '@hw-agconnect/auth';
import { WorkoutPage } from './WorkoutPage';
import { RecordListPage } from './RecordListPage';
import { ProfilePage } from './ProfilePage';
import { UserService } from '../services/UserService';
import { promptAction, router } from '@kit.ArkUI';
import cloud from '@hw-agconnect/cloud'

interface TabItem {
  title: string
  icon: Resource
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isTabPressed: boolean = false
  @State indicatorPosition: number = 0
  private readonly INDICATOR_WIDTH: number = 48
  private readonly TAB_BAR_HEIGHT: number = 72
  private readonly TAB_ANIMATION_DURATION: number = 150
  private readonly TAB_WIDTH: number = 120 // 每个tab的宽度

  private tabsController: TabsController = new TabsController()
  private userService: UserService = UserService.getInstance()
  private tabItems: TabItem[] = [
    {
      title: '运动',
      icon: $r('app.media.ic_sport')
    },
    {
      title: '记录',
      icon: $r('app.media.ic_record')
    },
    {
      title: '我的',
      icon: $r('app.media.ic_profile')
    }
  ]

  aboutToAppear() {
    this.checkLoginStatus()
  }

  async checkLoginStatus() {
    try {
      const user: AuthUser | null = await cloud.auth().getCurrentUser()
      if (!user) {
        router.pushUrl({ url: 'pages/LoginPage' })
      }
      this.userService.getCurrentUserInfo()
    } catch (error) {
      console.error('Check login status failed:', error instanceof Error ? error.message : String(error))
      router.pushUrl({ url: 'pages/LoginPage' })
    }
  }

  @Builder
  TabBuilder(item: TabItem, index: number) {
    Column() {
      Stack() {
        // 图标
        Image(item.icon)
          .width(24)
          .height(24)
          .fillColor(this.currentIndex === index ? '#007DFF' : '#666666')
          .objectFit(ImageFit.Contain)
          .animation({
            duration: this.TAB_ANIMATION_DURATION,
            curve: Curve.EaseInOut
          })
      }
      .width(48)
      .height(48)
      .margin({ bottom: 4 })
      .backgroundColor(this.currentIndex === index ? '#E6F0FF' : 'transparent')
      .borderRadius(24)
      .animation({
        duration: 0,
        curve: Curve.EaseInOut
      })

      Text(item.title)
        .fontSize(12)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#666666')
        .animation({
          duration: this.TAB_ANIMATION_DURATION,
          curve: Curve.EaseInOut
        })

      // 为每个标签添加底部指示器
      if (this.currentIndex === index) {
        Column()
          .width(4)
          .height(4)
          .backgroundColor('#007DFF')
          .borderRadius(2)
          .margin({ top: 4 })
          .animation({
            duration: this.TAB_ANIMATION_DURATION,
            curve: Curve.EaseInOut
          })
      }
    }
    .width('100%')
    .height(72)
    .justifyContent(FlexAlign.Center)
    .scale({
      x: this.currentIndex === index && this.isTabPressed ? 0.92 : 1,
      y: this.currentIndex === index && this.isTabPressed ? 0.92 : 1
    })
    .animation({
      duration: this.TAB_ANIMATION_DURATION,
      curve: Curve.EaseInOut
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isTabPressed = true
      } else if (event.type === TouchType.Up) {
        this.isTabPressed = false
      }
    })
  }

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          WorkoutPage()
        }
        .tabBar(this.TabBuilder(this.tabItems[0], 0))

        TabContent() {
          RecordListPage()
        }
        .tabBar(this.TabBuilder(this.tabItems[1], 1))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBuilder(this.tabItems[2], 2))
      }
      .onChange((index: number) => {
        animateTo({
          duration: this.TAB_ANIMATION_DURATION,
          curve: Curve.EaseInOut,
        }, () => {
          this.currentIndex = index
          this.isTabPressed = false
          this.indicatorPosition = index * this.TAB_WIDTH
        })
      })
      .scrollable(false)
      .barMode(BarMode.Fixed)
      .barHeight(this.TAB_BAR_HEIGHT)
      .animationDuration(this.TAB_ANIMATION_DURATION)
      .width('100%')
      .height('100%')
      .vertical(false)
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 16,
        color: '#1A000000',
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}