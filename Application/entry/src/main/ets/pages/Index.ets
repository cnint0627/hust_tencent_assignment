// entry/src/main/ets/pages/Index.ets
import auth, { AuthUser } from '@hw-agconnect/auth';
import { WorkoutPage } from './WorkoutPage';
import { WorkoutTrackingPage } from './WorkoutTrackingPage';
import { RecordPage } from './RecordPage';
import { ProfilePage } from './ProfilePage';
import { UserService } from '../services/UserService';
import { WorkoutType } from '../common/WorkoutType';
import { promptAction, router } from '@kit.ArkUI';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isTracking: boolean = false
  @State currentWorkout: WorkoutType = { id: 1, name: '跑步', icon: '\ue603' }
  // 添加动画相关状态
  @State slideOffset: number = 0
  @State slidOpacity: number = 1

  private tabsController: TabsController = new TabsController()
  private userService: UserService = UserService.getInstance()

  aboutToAppear() {
    this.checkLoginStatus()
  }

  async checkLoginStatus() {
    try {
      const user: AuthUser | null = await auth.getCurrentUser()
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
  TabBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#666666')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  startWorkoutWithAnimation(workoutType: WorkoutType) {
    // 首先执行淡出动画
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.slidOpacity = 0
      this.slideOffset = 100
    })

    // 动画结束后切换页面并执行淡入动画
    setTimeout(() => {
      this.currentWorkout = workoutType
      this.isTracking = true

      animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
        this.slidOpacity = 1
        this.slideOffset = 0
      })
    }, 200)
  }

  exitWorkoutWithAnimation() {
    // 首先执行淡出动画
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.slidOpacity = 0
      this.slideOffset = -100
    })

    // 动画结束后切换回运动选择页面并执行淡入动画
    setTimeout(() => {
      this.isTracking = false

      animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
        this.slidOpacity = 1
        this.slideOffset = 0
      })
    }, 200)
  }

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          Column() {
            if (!this.isTracking) {
              WorkoutPage({
                onStartWorkout: (workoutType: WorkoutType) => {
                  this.startWorkoutWithAnimation(workoutType)
                }
              })
                .opacity(this.slidOpacity)
                .translate({ x: this.slideOffset })
            } else {
              WorkoutTrackingPage({
                workoutType: this.currentWorkout,
                onBack: () => {
                  this.exitWorkoutWithAnimation()
                }
              })
                .opacity(this.slidOpacity)
                .translate({ x: this.slideOffset })
            }
          }
        }
        .tabBar(this.TabBuilder('运动', 0))

        TabContent() {
          RecordPage()
        }
        .tabBar(this.TabBuilder('记录', 1))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBuilder('我的', 2))
      }
      .onChange((index: number) => {
        if (this.isTracking && index !== 0) {
          this.tabsController.changeIndex(0)
          return
        }
        this.currentIndex = index
      })
      .barMode(BarMode.Fixed)
      .barHeight(50)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}