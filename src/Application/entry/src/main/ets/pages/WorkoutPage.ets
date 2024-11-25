// entry/src/main/ets/pages/WorkoutPage.ets
import { WorkoutType } from "../common/WorkoutType";
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Entry
@Component
export struct WorkoutPage {
  @State private workoutTypes: WorkoutType[] = [
    { id: 1, name: '跑步', icon: $r('app.media.ic_run') },
    { id: 2, name: '骑车', icon: $r('app.media.ic_bike') },
    { id: 3, name: '游泳', icon: $r('app.media.ic_swim') },
    { id: 4, name: '健走', icon: $r('app.media.ic_walk') }
  ]

  @State currentIndex: number = 0
  @State pressedIndex: number = -1
  private swiperController: SwiperController = new SwiperController()
  private bannerImages: Resource[] = [
    $r('app.media.banner1'),
    $r('app.media.banner2'),
    $r('app.media.banner3')
  ]
  private autoPlayInterval: number = -1

  aboutToAppear() {
    this.startAutoPlay()
  }

  aboutToDisappear() {
    if (this.autoPlayInterval !== -1) {
      clearInterval(this.autoPlayInterval)
      this.autoPlayInterval = -1
    }
  }

  startAutoPlay() {
    if (this.autoPlayInterval !== -1) {
      clearInterval(this.autoPlayInterval)
    }
    this.autoPlayInterval = setInterval(() => {
      this.currentIndex = (this.currentIndex + 1) % this.bannerImages.length
      this.swiperController.showNext()
    }, 2000)
  }

  startWorkout(workoutType: WorkoutType) {
    router.pushUrl({
      url: 'pages/WorkoutTrackingPage',
      params: workoutType
    })
  }

  @Builder Header() {
    Row() {
      Column() {
        Text('运动记录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Text('选择您想要开始的运动类型')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Image($r('app.media.ic_profile2'))
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#f5f5f5')
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder WorkoutItem(item: WorkoutType, index: number) {
    Column() {
      // 图标容器
      Stack() {
        Image(item.icon)
          .width(60)
          .height(60)
          .objectFit(ImageFit.Contain)
          .fillColor('#2972FF')
      }
      .margin({ bottom: 16 })

      Text(item.name)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')

      Text('开始运动')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 4 })
        .opacity(0.85)
    }
    .width('100%')
    .height(180)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({
      radius: 15,
      color: '#1A000000',
      offsetX: 2,
      offsetY: 4
    })
    .animation({
      duration: 250,
      curve: Curve.EaseInOut
    })
    .scale({
      x: this.pressedIndex === index ? 0.95 : 1,
      y: this.pressedIndex === index ? 0.95 : 1
    })
    .backgroundColor(this.pressedIndex === index ? '#F8F9FA' : Color.White)
    .justifyContent(FlexAlign.Center)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedIndex = index
      } else if (event.type === TouchType.Up) {
        this.pressedIndex = -1
        this.startWorkout(item)
      }
    })
  }

  build() {
    Column() {
      // 标题部分
      Column() {
        this.Header()
      }
      .margin({ top: 20, bottom: 16 })

      // 轮播图容器
      Stack() {
        Swiper(this.swiperController) {
          ForEach(this.bannerImages, (image: Resource) => {
            Stack() {
              Image(image)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .borderRadius(16)
            }
            .width('100%')
            .height('100%')
            .clip(true)
            .borderRadius(16)
          })
        }
        .width('100%')
        .height('100%')
        .autoPlay(true)
        .interval(2000)
        .indicator(false)
        .onChange((index: number) => {
          this.currentIndex = index
        })
        .clip(true)
        .borderRadius(16)

        // 指示器
        Row() {
          ForEach(this.bannerImages, (_: null, index) => {
            Circle()
              .size({ width: 6, height: 6 })
              .fill(this.currentIndex === index ? '#007DFF' : '#FFFFFF')
              .margin({ right: index !== this.bannerImages.length - 1 ? 6 : 0 })
              .opacity(this.currentIndex === index ? 1 : 0.4)
          })
        }
        .position({ x: '50%', y: '90%' })
        .translate({ x: '-50%' })
      }
      .width('90%')
      .height(180)
      .margin({ bottom: 24 })
      .clip(true)
      .borderRadius(16)

      // 运动类型网格
      Grid() {
        ForEach(this.workoutTypes, (item: WorkoutType, index: number) => {
          GridItem() {
            this.WorkoutItem(item, index)
          }
        })
      }
      .width('90%')
      .columnsTemplate('1fr 1fr')
      .rowsGap(20)
      .columnsGap(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}