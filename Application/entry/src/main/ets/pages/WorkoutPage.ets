// entry/src/main/ets/pages/WorkoutPage.ets
import { WorkoutType } from "../common/WorkoutType";
import { common } from "@kit.AbilityKit";
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Entry
@Component
export struct WorkoutPage {
  onStartWorkout?: (workoutType: WorkoutType) => void;

  @State private workoutTypes: WorkoutType[] = [
    { id: 1, name: '跑步', icon: '\ue603' },
    { id: 2, name: '骑车', icon: '\ue612' },
    { id: 3, name: '游泳', icon: '\ue627' },
    { id: 4, name: '健走', icon: '\ue601' }
  ]

  async checkAndStartWorkout(workoutType: WorkoutType) {
    if (this.onStartWorkout) {
      this.onStartWorkout(workoutType)
    } else {
      // 如果没有onStartWorkout回调，直接路由跳转
      router.pushUrl({
        url: 'pages/WorkoutTrackingPage',
        params: workoutType
      })
    }
  }

  build() {
    Column() {
      Text('选择运动类型')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Grid() {
        ForEach(this.workoutTypes, (item: WorkoutType) => {
          GridItem() {
            Column() {
              Text(item.icon)
                .fontSize(50)
                .fontColor('#666666')
              Text(item.name)
                .fontSize(16)
                .margin({ top: 8 })
            }
            .width('100%')
            .height(120)
            .backgroundColor('#f5f5f5')
            .borderRadius(12)
            .onClick(() => {
              this.checkAndStartWorkout(item)
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(16)
      .columnsGap(16)
      .padding(16)
    }
    .width('100%')
    .height('100%')
  }
}