// entry/src/main/ets/pages/RecordListPage.ets
import promptAction from '@ohos.promptAction';
import { WorkoutRecord } from '../common/WorkoutRecord';
import { WorkoutService } from '../services/WorkoutService';
import { router } from '@kit.ArkUI';

@Component
export struct RecordListPage {
  @State records: WorkoutRecord[] = []
  @State isLoading: boolean = false
  @State refreshing: boolean = false
  private workoutService: WorkoutService = WorkoutService.getInstance();

  aboutToAppear() {
    this.getRecordList()
  }

  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  formatDate(date: Date): string {
    const d = new Date(date)
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 ${d.getHours()}:${d.getMinutes().toString().padStart(2, '0')}`
  }

  async getRecordList() {
    try {
      this.isLoading = true;
      this.records = await this.workoutService.getRecordList();
    } catch (error) {
      console.error('Failed to fetch records:', error)
      promptAction.showToast({
        message: '获取记录失败',
        duration: 3000
      })
    } finally {
      this.isLoading = false
    }
  }

  async onRefresh() {
    try {
      this.refreshing = true;
      this.records = await this.workoutService.getRecordList();
      promptAction.showToast({
        message: '刷新成功',
        duration: 2000
      })
    } catch (error) {
      console.error('Refresh failed:', error)
      promptAction.showToast({
        message: '刷新失败',
        duration: 2000
      })
    } finally {
      this.refreshing = false
    }
  }

  navigateToDetail(record: WorkoutRecord) {
    router.pushUrl({
      url: 'pages/RecordDetailPage',
      params: {
        record: record
      }
    })
  }

  // 获取运动类型对应的图标
  getWorkoutTypeIcon(workoutType: string): Resource {
    switch (workoutType) {
      case '跑步':
        return $r('app.media.ic_run');
      case '骑车':
        return $r('app.media.ic_bike');
      case '健走':
        return $r('app.media.ic_walk');
      case '游泳':
        return $r('app.media.ic_swim');
      default:
        return $r('app.media.ic_run');
    }
  }

  // 获取运动类型对应的主题色
  getWorkoutTypeColor(workoutType: string): string {
    switch (workoutType) {
      case '跑步':
        return '#FF9500';
      case '骑车':
        return '#4CD964';
      case '健走':
        return '#5856D6';
      case '游泳':
        return '#FF3B30';
      default:
        return '';
    }
  }

  @Builder
  RecordItem(record: WorkoutRecord) {
    Column() {
      // 顶部信息
      Row() {
        Row() {
          // 使用对应的运动类型图标
          Image(this.getWorkoutTypeIcon(record.workoutType))
            .width(28)
            .height(28)
            .margin({ right: 8 })
            .objectFit(ImageFit.Contain)
          Column() {
            Text(record.workoutType)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getWorkoutTypeColor(record.workoutType))
            Text(this.formatDate(record.createTime))
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
        }

        Row() {
          Image($r('app.media.ic_enter'))
            .width(20)
            .height(20)
            .opacity(0.6)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 16 })

      // 分割线
      Divider()
        .color('#F0F0F0')
        .margin({ bottom: 16 })

      // 主要数据
      Row() {
        Column() {
          Row() {
            Image($r('app.media.ic_distance'))
              .width(20)
              .height(20)
              .margin({ right: 4 })
            Text(`${record.totalDistance.toFixed(2)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ bottom: 4 })

          Text('总距离(km)')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color('#EEEEEE')

        Column() {
          Row() {
            Image($r('app.media.ic_timer'))
              .width(20)
              .height(20)
              .margin({ right: 4 })
            Text(this.formatTime(record.totalTime))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ bottom: 4 })

          Text('运动时间')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color('#EEEEEE')

        Column() {
          Row() {
            Image($r('app.media.ic_speed'))
              .width(20)
              .height(20)
              .margin({ right: 4 })
            Text(`${record.averageSpeed.toFixed(1)}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ bottom: 4 })

          Text('平均配速(km/h)')
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .cardStyle()
    .backgroundColor(Color.White)
    .onClick(() => this.navigateToDetail(record))
  }

  @Builder
  EmptyState() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(120)
        .height(120)
        .opacity(0.6)
        .margin({ bottom: 16 })
      Text('暂无运动记录')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Styles
  cardStyle() {
    .width('100%')  // 改为100%，由父容器控制实际宽度
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 2,
      offsetY: 4
    })
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        Row() {
          Text('运动记录')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })

        // 记录列表
        Refresh({ refreshing: $$this.refreshing }) {
          List() {
            if (this.records.length === 0 && !this.isLoading) {
              ListItem() {
                this.EmptyState()
              }
            } else {
              ForEach(this.records, (record: WorkoutRecord) => {
                ListItem() {
                  // 使用额外的Container来控制卡片两侧间距
                  Row() {
                    this.RecordItem(record)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16 })
                }
                .margin({ bottom: 10 })
              })
              ListItem() {
                Row() {
                  // 防止最下面一个卡片被导航栏遮挡
                }.height(75)
              }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ top: 12 })  // 移除左右内边距
        }
        .onRefreshing(() => {
          this.onRefresh()
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 加载指示器
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color('#007DFF')
            .width(32)
            .height(32)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#007DFF')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80FFFFFF')
        .justifyContent(FlexAlign.Center)
        .zIndex(999)
      }
    }
  }
}